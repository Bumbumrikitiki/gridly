const crypto = require('crypto');
const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onMessagePublished } = require('firebase-functions/v2/pubsub');
const { logger } = require('firebase-functions');
const { google } = require('googleapis');

admin.initializeApp();
const db = admin.firestore();

const RTDN_TOPIC = 'play-rtdn';

function tokenHash(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

async function fetchSubscriptionStatus(packageName, purchaseToken) {
  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });

  const androidpublisher = google.androidpublisher({
    version: 'v3',
    auth,
  });

  const response = await androidpublisher.purchases.subscriptionsv2.get({
    packageName,
    token: purchaseToken,
  });

  const data = response.data || {};
  const lineItems = Array.isArray(data.lineItems) ? data.lineItems : [];
  const firstLineItem = lineItems[0] || {};

  const subscriptionState = data.subscriptionState || 'SUBSCRIPTION_STATE_UNSPECIFIED';
  const nowMs = Date.now();

  const expiryTime = firstLineItem.expiryTime || null;
  const expiryMs = expiryTime ? Date.parse(expiryTime) : null;

  const isStateActive =
    subscriptionState === 'SUBSCRIPTION_STATE_ACTIVE' ||
    subscriptionState === 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD';

  const isNotExpired = expiryMs == null ? true : expiryMs > nowMs;

  const hasActiveEntitlement = Boolean(isStateActive && isNotExpired);

  return {
    hasActiveEntitlement,
    subscriptionState,
    productId: firstLineItem.productId || null,
    expiryTime,
    raw: data,
  };
}

async function applyEntitlementToUser({ uid, packageName, purchaseToken, status, source }) {
  const purchaseTokenHash = tokenHash(purchaseToken);

  const userRef = db.collection('users').doc(uid);
  const purchaseRef = db.collection('playPurchaseTokens').doc(purchaseTokenHash);

  await db.runTransaction(async (tx) => {
    tx.set(
      userRef,
      {
        isPro: status.hasActiveEntitlement,
        entitlement: {
          source,
          provider: 'google_play',
          active: status.hasActiveEntitlement,
          packageName,
          productId: status.productId,
          subscriptionState: status.subscriptionState,
          expiryTime: status.expiryTime,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    tx.set(
      purchaseRef,
      {
        uid,
        packageName,
        productId: status.productId,
        subscriptionState: status.subscriptionState,
        expiryTime: status.expiryTime,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}

exports.verifyAndroidSubscription = onCall(
  { region: 'europe-central2' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Musisz być zalogowany.');
    }

    const uid = request.auth.uid;
    const packageName = String(request.data?.packageName || '').trim();
    const purchaseToken = String(request.data?.purchaseToken || '').trim();

    if (!packageName || !purchaseToken) {
      throw new HttpsError(
        'invalid-argument',
        'Wymagane: packageName i purchaseToken.'
      );
    }

    try {
      const status = await fetchSubscriptionStatus(packageName, purchaseToken);
      await applyEntitlementToUser({
        uid,
        packageName,
        purchaseToken,
        status,
        source: 'callable_verify',
      });

      return {
        ok: true,
        hasActiveEntitlement: status.hasActiveEntitlement,
        productId: status.productId,
        subscriptionState: status.subscriptionState,
        expiryTime: status.expiryTime,
      };
    } catch (error) {
      logger.error('verifyAndroidSubscription failed', error);
      throw new HttpsError('internal', 'Nie udało się zweryfikować subskrypcji.');
    }
  }
);

exports.handlePlayRtdn = onMessagePublished(
  { topic: RTDN_TOPIC, region: 'europe-central2' },
  async (event) => {
    try {
      const messageData = event.data.message?.data;
      if (!messageData) {
        logger.warn('RTDN message without data.');
        return;
      }

      const decoded = Buffer.from(messageData, 'base64').toString('utf8');
      const payload = JSON.parse(decoded);

      const packageName = payload.packageName;
      const subscriptionNotification = payload.subscriptionNotification;
      const purchaseToken = subscriptionNotification?.purchaseToken;

      if (!packageName || !purchaseToken) {
        logger.warn('RTDN missing packageName or purchaseToken', payload);
        return;
      }

      const purchaseTokenHash = tokenHash(purchaseToken);
      const purchaseDoc = await db
        .collection('playPurchaseTokens')
        .doc(purchaseTokenHash)
        .get();

      if (!purchaseDoc.exists) {
        logger.warn('RTDN token not mapped yet', { packageName, purchaseTokenHash });
        return;
      }

      const uid = purchaseDoc.data()?.uid;
      if (!uid) {
        logger.warn('RTDN token mapping has no uid', { purchaseTokenHash });
        return;
      }

      const status = await fetchSubscriptionStatus(packageName, purchaseToken);
      await applyEntitlementToUser({
        uid,
        packageName,
        purchaseToken,
        status,
        source: 'rtdn',
      });

      logger.info('RTDN entitlement updated', {
        uid,
        packageName,
        productId: status.productId,
        active: status.hasActiveEntitlement,
      });
    } catch (error) {
      logger.error('handlePlayRtdn failed', error);
    }
  }
);
