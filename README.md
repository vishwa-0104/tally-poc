# Tally Bill Sync

AI-powered purchase bill parser and Tally ERP sync tool. Upload a bill photo or PDF — the AI extracts the data, you map it to your Tally ledgers, and it syncs directly into Tally ERP with one click.

---

## What You Need Before Starting

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- An [Anthropic API key](https://console.anthropic.com) (for AI bill parsing)
- Google Chrome browser (for the Tally sync extension)
- Tally ERP / TallyPrime running on your machine (for actual Tally sync)

---

## Part 1 — Install & Run the Web App

### Step 1 — Download the project

Download and extract the project folder, or clone it:

```bash
git clone <repository-url>
cd tally-bill-sync
```

### Step 2 — Create your environment file

Copy the example file and fill in your details:

**On Mac / Linux:**
```bash
cp .env.example .env
```

**On Windows (Command Prompt):**
```cmd
copy .env.example .env
```

Open `.env` in any text editor and set your values:

```env
# Your Anthropic API key — get one at https://console.anthropic.com
ANTHROPIC_API_KEY=sk-ant-your-key-here

# Leave this as-is for now (you will fill it in Part 2)
VITE_CHROME_EXTENSION_ID=

# Optional: change this to a long random string for security
JWT_SECRET=change-this-to-a-long-random-string
```

### Step 3 — Start the application

```bash
docker-compose up --build
```

This downloads and builds everything automatically. First run takes 3–5 minutes.

Once you see `Starting server...` in the logs, open your browser:

```
http://localhost
```

### Step 4 — Log in

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@tallysync.com` | `admin123` |
| Company | `groceries@sharma.com` | `company123` |

> The Admin account manages companies. The Company account uploads and syncs bills.

### Stopping the app

```bash
docker-compose down
```

### Starting again later (no rebuild needed)

```bash
docker-compose up
```

---

## Part 2 — Install the Chrome Extension

The Chrome extension is needed to sync bills to Tally. It acts as a bridge between the web app and your local Tally server — the browser cannot connect to Tally directly, but the extension can.

> If you only want to upload and parse bills without syncing to Tally, you can skip this part.

### Step 1 — Open Chrome Extensions

Open Google Chrome and go to:
```
chrome://extensions
```

### Step 2 — Enable Developer Mode

Toggle **Developer mode** on (top-right corner of the page).

### Step 3 — Load the extension

1. Click **Load unpacked**
2. Browse to the project folder and select the **`extension`** subfolder
3. Click **Select Folder**

The extension will appear in your list as **"Tally Bill Sync"**.

### Step 4 — Copy the Extension ID

You will see an ID under the extension name — it looks like:

```
abcdefghijklmnopabcdefghijklmnop
```

Copy that ID.

### Step 5 — Add the ID to your .env file

Open your `.env` file and paste the ID:

```env
VITE_CHROME_EXTENSION_ID=abcdefghijklmnopabcdefghijklmnop
```

### Step 6 — Rebuild the app

```bash
docker-compose up --build
```

The extension status indicator in the app header will turn green when connected.

---

## Part 3 — Configure Tally for Syncing

Tally must be open and its web server must be enabled for sync to work.

### Enable Tally's web server

1. Open Tally ERP / TallyPrime
2. Go to **F12: Configure → Advanced Configuration**
3. Set **Enable ODBC Server** to **Yes**
4. Set the port to **9000** (default — must match what you set in the company settings)
5. Press **Enter** to save

### Confirm it is working

Click the **Test Tally Connection** button in the extension popup (click the extension icon in Chrome toolbar).

---

## How It Works

```
Bill Image / PDF
       ↓
  AI Parsing (Claude)
       ↓
  Review & Edit data
       ↓
  Map to Tally Ledgers
       ↓
  Chrome Extension
       ↓
  Tally ERP (localhost)
       ↓
  Voucher Created ✓
```

1. Upload a photo or PDF of a purchase bill
2. AI reads the bill and extracts vendor, date, amounts, GST, line items
3. You review and correct any mistakes
4. You map the bill fields to your Tally ledger names
5. Click **Sync to Tally** — the extension POSTs the XML to your local Tally
6. The bill is marked **Synced**

---

## Ledger Mapping Guide

When syncing a bill you need to select four ledger names. These must exactly match the ledger names in your Tally:

| Field | What to enter | Where to find it in Tally |
|-------|--------------|--------------------------|
| Vendor Ledger | The supplier's name | Accounts Info → Ledgers → Sundry Creditors |
| Purchase Ledger | Your purchase account | Accounts Info → Ledgers → Purchase Accounts |
| CGST Ledger | Input CGST tax account | Accounts Info → Ledgers → Duties & Taxes |
| SGST Ledger | Input SGST tax account | Accounts Info → Ledgers → Duties & Taxes |
| IGST Ledger | Input IGST (inter-state only) | Accounts Info → Ledgers → Duties & Taxes |

If a ledger does not exist in Tally, create it first:
**Gateway of Tally → Accounts Info → Ledgers → Create**

---

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Anthropic API key for AI bill parsing |
| `JWT_SECRET` | Recommended | Secret for signing login tokens. Change before production use |
| `VITE_CHROME_EXTENSION_ID` | For Tally sync | Chrome extension ID from chrome://extensions |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18 + TypeScript + Vite |
| Styling | Tailwind CSS |
| Backend | Node.js + Express + TypeScript |
| Database | PostgreSQL + Prisma ORM |
| AI Parsing | Anthropic Claude (claude-sonnet-4-6) |
| Auth | JWT + bcrypt |
| Container | Docker + Docker Compose |
| Web server | nginx (frontend) |
| Extension | Chrome MV3 service worker |

---

## Troubleshooting

**App not opening at http://localhost**
- Make sure Docker Desktop is running
- Run `docker-compose ps` to check container status
- Run `docker-compose logs backend` to see backend errors

**Login not working**
- Run `docker-compose down -v` then `docker-compose up --build` to reset the database

**Extension shows "not detected"**
- Make sure `VITE_CHROME_EXTENSION_ID` in `.env` matches the ID in `chrome://extensions`
- Rebuild after changing `.env`: `docker-compose up --build`
- Refresh the page after installing the extension

**Tally sync fails**
- Make sure Tally is open and the web server is enabled (port 9000)
- Click **Test Tally Connection** in the extension popup to verify
- Check that the ledger names you typed exactly match what is in Tally

**Bills always show the same mock data (not parsing real bills)**
- Check that `ANTHROPIC_API_KEY` is set correctly in `.env`
- Make sure you have API credits at [console.anthropic.com](https://console.anthropic.com)
