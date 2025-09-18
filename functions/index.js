const {onRequest} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const axios = require("axios");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();

// Billplz Configuration
const BILLPLZ_SANDBOX_URL = "https://www.billplz-sandbox.com/api/v3";
const BILLPLZ_API_KEY = "1149106e-4ef2-474b-8eea-eadbf21818be";
const BILLPLZ_COLLECTION_ID = "xsu0hjux";
const BILLPLZ_CALLBACK_URL =
    "https://us-central1-wms-appi1.cloudfunctions.net/paymentCallback";

/**
 * Create a new bill in Billplz
 * This function is called from your Flutter app when a user wants to make a
 * payment
 */
exports.createBill = onRequest({cors: true}, async (req, res) => {
  try {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.status(204).send('');
      return;
    }

    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const {
      amount,
      description,
      customerName,
      customerEmail,
      customerPhone,
      orderId,
    } = req.body;

    // Validate required fields
    if (!amount || !description || !customerName || !customerEmail) {
      throw new Error(
          "Missing required fields: amount, description, customerName, " +
          "customerEmail");
    }

    // Prepare bill data for Billplz
    const billData = {
      collection_id: BILLPLZ_COLLECTION_ID,
      email: customerEmail,
      mobile: customerPhone || "",
      name: customerName,
      amount: Math.round(amount * 100), // Convert to cents
      description: description,
      callback_url: BILLPLZ_CALLBACK_URL,
      redirect_url: "https://your-app.com/payment-success",
      due_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      reference_1_label: "Order ID",
      reference_1: orderId || "",
      reference_2_label: "Customer",
      reference_2: customerName,
    };

    // Create bill in Billplz
    const response = await axios.post(
        `${BILLPLZ_SANDBOX_URL}/bills`,
        billData,
        {
          auth: {
            username: BILLPLZ_API_KEY,
            password: "",
          },
          headers: {
            "Content-Type": "application/json",
          },
        });

    const bill = response.data;

    // Save payment record to Firestore
    const paymentRecord = {
      billId: bill.id,
      orderId: orderId || "",
      customerName,
      customerEmail,
      customerPhone: customerPhone || "",
      amount,
      description,
      status: "pending",
      billUrl: bill.url,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await db.collection("payments").doc(bill.id).set(paymentRecord);

    logger.info("Bill created successfully", {
      billId: bill.id,
      orderId,
      amount,
    });

    res.set('Access-Control-Allow-Origin', '*');
    res.status(200).json({
      success: true,
      billId: bill.id,
      billUrl: bill.url,
      message: "Bill created successfully",
    });
  } catch (error) {
    logger.error("Error creating bill", error);
    res.set('Access-Control-Allow-Origin', '*');
    res.status(500).json({
      success: false,
      error: `Failed to create bill: ${error.message}`,
    });
  }
});

/**
 * Payment callback from Billplz
 * This function is called by Billplz after payment completion
 */
exports.paymentCallback = onRequest({cors: true}, async (req, res) => {
  try {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.status(204).send('');
      return;
    }

    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    // Verify the request is from Billplz
    const {
      billplzid,
      billplzpaid_at: billplzPaidAt,
      billplztransaction_id: billplzTransactionId,
      billplztransaction_status: billplzTransactionStatus,
    } = req.body;

    if (!billplzid) {
      logger.error("Missing billplzid in callback");
      throw new Error("Missing billplzid");
    }

    // Get the payment record from Firestore
    const paymentRef = db.collection("payments").doc(billplzid);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      logger.error("Payment record not found", {billplzid});
      throw new Error("Payment record not found");
    }

    const isPaid = billplzTransactionStatus === "completed";

    // Update payment status in Firestore
    await paymentRef.update({
      status: isPaid ? "paid" : "failed",
      transactionId: billplzTransactionId || "",
      paidAt: isPaid ? new Date(billplzPaidAt) : null,
      updatedAt: new Date(),
    });

    logger.info("Payment status updated", {
      billplzid,
      status: isPaid ? "paid" : "failed",
      transactionId: billplzTransactionId,
    });

    // You can add additional logic here, such as:
    // - Sending confirmation emails
    // - Updating order status
    // - Triggering other business logic

    res.set('Access-Control-Allow-Origin', '*');
    res.status(200).json({
      success: true,
      message: "Payment callback processed successfully",
    });
  } catch (error) {
    logger.error("Error processing payment callback", error);
    res.set('Access-Control-Allow-Origin', '*');
    res.status(500).json({
      success: false,
      error: `Payment callback failed: ${error.message}`,
    });
  }
});

/**
 * Get payment status
 * This function allows your Flutter app to check payment status
 */
exports.getPaymentStatus = onRequest({cors: true}, async (req, res) => {
  try {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.status(204).send('');
      return;
    }

    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const {billId} = req.body;

    if (!billId) {
      throw new Error("Missing billId");
    }

    const paymentDoc = await db.collection("payments").doc(billId).get();

    if (!paymentDoc.exists) {
      throw new Error("Payment record not found");
    }

    const paymentData = paymentDoc.data();

    res.set('Access-Control-Allow-Origin', '*');
    res.status(200).json({
      success: true,
      payment: paymentData,
    });
  } catch (error) {
    logger.error("Error getting payment status", error);
    res.set('Access-Control-Allow-Origin', '*');
    res.status(500).json({
      success: false,
      error: `Failed to get payment status: ${error.message}`,
    });
  }
});

/**
 * List payments for a customer
 * This function allows your Flutter app to get payment history
 */
exports.getCustomerPayments = onRequest({cors: true}, async (req, res) => {
  try {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.status(204).send('');
      return;
    }

    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const {customerEmail, limit = 10} = req.body;

    if (!customerEmail) {
      throw new Error("Missing customerEmail");
    }

    const paymentsQuery = await db
        .collection("payments")
        .where("customerEmail", "==", customerEmail)
        .orderBy("createdAt", "desc")
        .limit(limit)
        .get();

    const payments = [];
    paymentsQuery.forEach((doc) => {
      payments.push({
        id: doc.id,
        ...doc.data(),
      });
    });

    res.set('Access-Control-Allow-Origin', '*');
    res.status(200).json({
      success: true,
      payments,
    });
  } catch (error) {
    logger.error("Error getting customer payments", error);
    res.set('Access-Control-Allow-Origin', '*');
    res.status(500).json({
      success: false,
      error: `Failed to get customer payments: ${error.message}`,
    });
  }
});
