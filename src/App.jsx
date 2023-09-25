import React, { useState, useEffect } from "react";
import { loadHyper } from "@juspay-tech/hyper-js";
import { HyperElements } from "@juspay-tech/react-hyper-js";
import './App.css';
import CheckoutForm from "./CheckoutForm";

  const AWS = require('aws-sdk');
  AWS.config.update({
    region: 'us-east-1',
  });
  let PUBLISHABLE_KEY;
  const secretsManager = new AWS.SecretsManager();
  const secretName = 'HYPERSWITCH';
  secretsManager.getSecretValue({ SecretId: secretName }, (err, data) => {
        if (err) {
                console.error('Error retrieving secret:', err);
        } else {
                // Parse the secret JSON or plaintext, depending on how it's stored
                const secretValue = JSON.parse(data.SecretString || '{}');
                const PUBLISHABLE_KEY = secretValue.HYPERSWITCH_PUBLISHABLE_KEY;
                console.log('KEY:', PUBLISHABLE_KEY);
        } });

const hyperPromise = loadHyper(PUBLISHABLE_KEY);

function App() {
  const [options, setOptions] = useState(null);

  useEffect(() => {
    fetch("/create-payment", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ items: [{ id: "xl-tshirt" }] }),
    }).then((res) => res.json())
      .then((data) => {
        setOptions({
          clientSecret: data.client_secret,
          appearance: {
            theme: "midnight"
          }
        })
      })
  }, [])

  return (
    <div className="app">
      {options && (
        <HyperElements options={options} hyper={hyperPromise}>
          <CheckoutForm return_url={`${window.location.origin}/completion`} />
        </HyperElements>
      )}
    </div>
  );
}

export default App;
