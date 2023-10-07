import os
import json

json_secret = os.environ.get("TF_VARFILE")

if json_secret:
    try:
        secret_data = json.loads(json_secret)
        with open("terraform.tfvars", "w") as var_file:
            for key, value in secret_data.items():
                var_file.write(f'{key} = "{value}"\n')
        print("Terraform variable file created successfully.")
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON secret: {e}")
else:
    print("JSON secret not found in GitHub Secrets.")
