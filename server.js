const express = require("express");
const app = express();

app.use(express.static("public"));
app.use(express.json());

const calculateOrderAmount = (items) => {
  return 1400;
};

app.post("/create-payment", async (req, res) => {
  const { items } = req.body;

  /*
     If you have two or more “business_country” + “business_label” pairs configured in your Hyperswitch dashboard,
     please pass the fields business_country and business_label in this request body.
     For accessing more features, you can check out the request body schema for payments-create API here :
     https://api-reference.hyperswitch.io/docs/hyperswitch-api-reference/60bae82472db8-payments-create
  */
  const AWS = require('aws-sdk');
  AWS.config.update({
    region: 'us-east-1',
  });
  let API_KEY;
  const secretsManager = new AWS.SecretsManager();
  const secretName = 'HYPERSWITCH';
  secretsManager.getSecretValue({ SecretId: secretName }, (err, data) => {
        if (err) {
                console.error('Error retrieving secret:', err);
        } else {
                // Parse the secret JSON or plaintext, depending on how it's stored
                const secretValue = JSON.parse(data.SecretString || '{}');
                const API_KEY = secretValue.HYPERSWITCH_API_KEY;
                console.log('KEY:', API_KEY);
        } });
  const hyperswitch_url = "https://sandbox.hyperswitch.io/payments";
  const hyperswitch_api_key = API_KEY;

//  const hyperswitch_url = "https://sandbox.hyperswitch.io/payments";
//  const hyperswitch_api_key = "HYPERSWITCH_API_KEY"; // Replace with your actual API key provided by Hyperswitch

  const payload = {
    amount: calculateOrderAmount(items),
    currency: "USD",
    customer_id: "hyperswitch_customer"
  };

  const headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "api-key": hyperswitch_api_key,
  };

  try {
    const response = await fetch(hyperswitch_url, {
      method: "POST",
      headers: headers,
      body: JSON.stringify(payload),
    });

    const data = await response.json();
    res.send({
      client_secret: data.client_secret,
    });
  } catch (error) {
    res.send({
      error: error.message || "Unknown error occurred",
    });
  }
});

app.listen(4242, () => console.log("Node server listening on port 4242!"));
