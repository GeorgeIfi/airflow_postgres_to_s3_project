# AWS Manual Permission Setup Guide

## Add Permissions to shopease_user

Follow these steps in AWS Console to add the necessary permissions:

---

## Step 1: Login to AWS Console
1. Go to https://console.aws.amazon.com/
2. Login with your **root account** or an **admin user** (NOT shopease_user)

---

## Step 2: Navigate to IAM
1. In the AWS Console search bar, type **IAM**
2. Click on **IAM** service

---

## Step 3: Find shopease_user
1. Click **Users** in the left sidebar
2. Search for and click on **shopease_user**

---

## Step 4: Add Permissions
1. Click the **Add permissions** button
2. Select **Attach policies directly**

---

## Step 5: Attach These 3 Managed Policies

Search for and check the box next to each policy:

### Policy 1: AWSGlueConsoleFullAccess
- **Purpose**: Create and manage Glue databases, crawlers, and jobs
- **Search**: Type "glue" in the search box
- **Select**: ✅ AWSGlueConsoleFullAccess

### Policy 2: AmazonAthenaFullAccess  
- **Purpose**: Create and manage Athena workgroups and run queries
- **Search**: Type "athena" in the search box
- **Select**: ✅ AmazonAthenaFullAccess

### Policy 3: IAMFullAccess (or create custom policy below)
- **Purpose**: Create IAM roles for Glue service
- **Search**: Type "iam full" in the search box
- **Select**: ✅ IAMFullAccess

**OR** if you want limited IAM access (more secure), create a custom policy:

---

## Step 6: (Optional) Create Custom IAM Policy Instead

If you don't want to give full IAM access, create this custom policy:

1. Go to **IAM** → **Policies** → **Create policy**
2. Click **JSON** tab
3. Paste this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "iam:PutRolePolicy"
      ],
      "Resource": [
        "arn:aws:iam::*:role/GlueServiceRole",
        "arn:aws:iam::*:role/*glue*"
      ]
    }
  ]
}
```

4. Click **Next**
5. Name it: **ShopEaseGlueLimitedIAM**
6. Click **Create policy**
7. Go back to **Users** → **shopease_user** → **Add permissions**
8. Attach the **ShopEaseGlueLimitedIAM** policy

---

## Step 7: Review and Confirm
1. Click **Next: Review**
2. Click **Add permissions**

---

## Step 8: Verify Permissions Added

You should now see these policies attached to shopease_user:
- ✅ AmazonS3FullAccess (already had this)
- ✅ AWSGlueConsoleFullAccess (newly added)
- ✅ AmazonAthenaFullAccess (newly added)
- ✅ IAMFullAccess OR ShopEaseGlueLimitedIAM (newly added)

---

## Step 9: Test in Your Project

After adding permissions, come back and tell me. I'll re-run the `glue_athena_setup` DAG to create:
- Glue database: `shopease_catalog`
- Glue crawlers: `shopease-bronze-crawler`, `shopease-silver-crawler`, `shopease-gold-crawler`
- Athena workgroup: `shopease-analytics`

---

## Quick Summary

**What to add:**
1. AWSGlueConsoleFullAccess
2. AmazonAthenaFullAccess  
3. IAMFullAccess (or custom limited IAM policy)

**Where:** IAM → Users → shopease_user → Add permissions → Attach policies directly

**Time needed:** 2-3 minutes

---

Let me know when you're done!
