# Serverless Grafana with Identity Aware Proxy

## Setup Terraform
1. Run `terraform init`
2. Set required terraform variables, e.g. Linux:

    `export TF_VAR_project_id=[YOUR_GCP_PROJECT_ID]` You can find the project ID in the GCP console
    `export TF_VAR_support_email=[YOUR_SUPPORT_EMAIL]` 
    `export TF_VAR_domain=[YOUR_DOMAIN]` This is the domain to host your Grafana dashboard

## Execute the Terraform script to create your Grafana Dashboard
3. Run `terraform plan` and confirm all steps are correct
4. Run `terraform apply`
5. Confirm the command has been executed successfully
6. Copy the external_ip from the console Outputs. Add an A record redirect from your domain to this IP address.
7. Wait around 5-10 minutes for GCP Load Balancer to perform certificate checks

## Access your Grafana Dashboard
8. Open an Incognito browser window. Go to admin.google.com and sign in with your GCP account owner. Create a new User (only users who are part of your domain can access the dashboard)
9. Open the GCP Console and go to IAM -> Add -> enter your user’s email (e.g. user@your-domain.com) and select role *IAP-secured Web App User*
10. Open an incognito window, go to your-domain.com (the domain you used in step 6) and sign in using the newly created user (you will be prompted to change your password the first time you login)


