--
-- PostgreSQL database dump
--

\restrict IitSqFQLgO541XGHEL6ReyDxafaVrL0obemGPBsN3H4xdKMr9UbxlyMimeBUEgc

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: BillStatus; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."BillStatus" AS ENUM (
    'PENDING',
    'PARSED',
    'MAPPED',
    'SYNCED',
    'ERROR'
);


ALTER TYPE public."BillStatus" OWNER TO postgres;

--
-- Name: Role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."Role" AS ENUM (
    'ADMIN',
    'COMPANY'
);


ALTER TYPE public."Role" OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Bill; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Bill" (
    id text NOT NULL,
    "companyId" text NOT NULL,
    "billNumber" text NOT NULL,
    "vendorName" text NOT NULL,
    "vendorGstin" text,
    "buyerGstin" text,
    "billDate" text NOT NULL,
    subtotal double precision NOT NULL,
    "cgstAmount" double precision DEFAULT 0 NOT NULL,
    "sgstAmount" double precision DEFAULT 0 NOT NULL,
    "igstAmount" double precision DEFAULT 0 NOT NULL,
    "totalAmount" double precision NOT NULL,
    status public."BillStatus" DEFAULT 'PARSED'::public."BillStatus" NOT NULL,
    "imageUrl" text,
    "originalData" jsonb,
    "isEdited" boolean DEFAULT false NOT NULL,
    "rawAiJson" jsonb,
    "tallyXml" text,
    "tallyMapping" jsonb,
    "roundOffAmount" double precision,
    "syncedAt" timestamp(3) without time zone,
    "syncError" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


ALTER TABLE public."Bill" OWNER TO postgres;

--
-- Name: Company; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Company" (
    id text NOT NULL,
    name text NOT NULL,
    gstin text,
    email text NOT NULL,
    port integer DEFAULT 9000 NOT NULL,
    mapping jsonb,
    "voucherCounter" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."Company" OWNER TO postgres;

--
-- Name: LedgerCache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LedgerCache" (
    id text NOT NULL,
    "companyId" text NOT NULL,
    name text NOT NULL,
    "group" text DEFAULT ''::text NOT NULL,
    gstin text,
    state text,
    "openingBalance" text,
    "gstRegistrationType" text
);


ALTER TABLE public."LedgerCache" OWNER TO postgres;

--
-- Name: LineItem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LineItem" (
    id text NOT NULL,
    "billId" text NOT NULL,
    description text NOT NULL,
    "hsnCode" text,
    quantity double precision NOT NULL,
    unit text NOT NULL,
    "unitPrice" double precision NOT NULL,
    "discountPercent" double precision,
    "gstRate" double precision NOT NULL,
    amount double precision NOT NULL,
    "tallyLedger" text,
    "tallyStockItem" text
);


ALTER TABLE public."LineItem" OWNER TO postgres;

--
-- Name: StockGroupCache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."StockGroupCache" (
    id text NOT NULL,
    "companyId" text NOT NULL,
    name text NOT NULL,
    parent text DEFAULT ''::text NOT NULL
);


ALTER TABLE public."StockGroupCache" OWNER TO postgres;

--
-- Name: StockItemAlias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."StockItemAlias" (
    id text NOT NULL,
    "companyId" text NOT NULL,
    "stockItemCacheId" text NOT NULL,
    "billItemName" text NOT NULL
);


ALTER TABLE public."StockItemAlias" OWNER TO postgres;

--
-- Name: StockItemCache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."StockItemCache" (
    id text NOT NULL,
    "companyId" text NOT NULL,
    name text NOT NULL,
    "group" text DEFAULT ''::text NOT NULL,
    unit text DEFAULT ''::text NOT NULL
);


ALTER TABLE public."StockItemCache" OWNER TO postgres;

--
-- Name: StockUnitCache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."StockUnitCache" (
    id text NOT NULL,
    "companyId" text NOT NULL,
    name text NOT NULL,
    symbol text DEFAULT ''::text NOT NULL
);


ALTER TABLE public."StockUnitCache" OWNER TO postgres;

--
-- Name: User; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."User" (
    id text NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    "passwordHash" text NOT NULL,
    role public."Role" DEFAULT 'COMPANY'::public."Role" NOT NULL,
    "companyId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."User" OWNER TO postgres;

--
-- Data for Name: Bill; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Bill" (id, "companyId", "billNumber", "vendorName", "vendorGstin", "buyerGstin", "billDate", subtotal, "cgstAmount", "sgstAmount", "igstAmount", "totalAmount", status, "imageUrl", "originalData", "isEdited", "rawAiJson", "tallyXml", "tallyMapping", "roundOffAmount", "syncedAt", "syncError", "createdAt", "updatedAt") FROM stdin;
b_1776535341654	c1	438	Good Food People	07ALGPK1152J2Z7	\N	2026-03-23	200340	0	0	10017	210357	SYNCED	\N	{"billDate": "2026-03-23", "subtotal": 200340, "lineItems": [{"unit": "Pcs", "amount": 102000, "gstRate": 5, "hsnCode": "19053100", "quantity": 240, "unitPrice": 425, "description": "Lotus Biscuite Spread (5%)", "discountPercent": null}, {"unit": "Pcs", "amount": 10000, "gstRate": 5, "hsnCode": "19053100", "quantity": 50, "unitPrice": 200, "description": "Lotus Biscuite (5%)", "discountPercent": null}, {"unit": "Pcs", "amount": 65760, "gstRate": 5, "hsnCode": "18069010", "quantity": 120, "unitPrice": 548, "description": "NUTELLA 750gm Mrp 819/- (5%)", "discountPercent": null}, {"unit": "Pcs", "amount": 4400, "gstRate": 5, "hsnCode": "19021900", "quantity": 80, "unitPrice": 55, "description": "Ramen Noodle 300g*40 Green Label", "discountPercent": null}, {"unit": "Pcs", "amount": 4680, "gstRate": 5, "hsnCode": "21039040", "quantity": 24, "unitPrice": 195, "description": "PassGochujang 500gm (5%)", "discountPercent": null}, {"unit": "Pkt", "amount": 13500, "gstRate": 5, "hsnCode": "21039040", "quantity": 100, "unitPrice": 135, "description": "NOORI SHEET", "discountPercent": null}], "billNumber": "438", "buyerGstin": "09AATPM2300E1ZV", "cgstAmount": 0, "igstAmount": 10017, "sgstAmount": 0, "vendorName": "Good Food People", "totalAmount": 210357, "vendorGstin": "07ALGPK1152J2Z7", "roundOffAmount": null}	t	null	<?xml version="1.0" encoding="utf-8"?>\n<ENVELOPE>\n  <HEADER>\n    <TALLYREQUEST>Import Data</TALLYREQUEST>\n  </HEADER>\n  <BODY>\n    <IMPORTDATA>\n      <REQUESTDESC>\n        <REPORTNAME>Vouchers</REPORTNAME>\n      </REQUESTDESC>\n      <REQUESTDATA>\n        <TALLYMESSAGE xmlns:UDF="TallyUDF">\n          <VOUCHER VCHTYPE="GST PURCHASE" ACTION="Create" OBJVIEW="Invoice Voucher View">\n            <DATE>20260418</DATE>\n            <VOUCHERNUMBER>438_1</VOUCHERNUMBER>\n            <REFERENCEDATE>20260323</REFERENCEDATE>\n            <VOUCHERTYPENAME>GST PURCHASE</VOUCHERTYPENAME>\n            <PARTYLEDGERNAME>Good Food People</PARTYLEDGERNAME>\n            <PARTYMAILINGNAME>Good Food People</PARTYMAILINGNAME>\n            <REFERENCE>438</REFERENCE>\n            <VCHENTRYMODE>Item Invoice</VCHENTRYMODE>\n            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>\n            <ISINVOICE>Yes</ISINVOICE>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Lotus Biscoff Spread (18%)</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>425/Pcs</RATE>\n              <AMOUNT>-102000</AMOUNT>\n              <ACTUALQTY> 240 Pcs</ACTUALQTY>\n              <BILLEDQTY> 240 Pcs</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-102000</AMOUNT>\n                <ACTUALQTY> 240 Pcs</ACTUALQTY>\n                <BILLEDQTY> 240 Pcs</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-102000</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Lotus Biscoff Biscuits (Imp)</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>200/Pcs</RATE>\n              <AMOUNT>-10000</AMOUNT>\n              <ACTUALQTY> 50 Pcs</ACTUALQTY>\n              <BILLEDQTY> 50 Pcs</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-10000</AMOUNT>\n                <ACTUALQTY> 50 Pcs</ACTUALQTY>\n                <BILLEDQTY> 50 Pcs</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-10000</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Nutella 750 GM MRP 799</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>548/Pcs</RATE>\n              <AMOUNT>-65760</AMOUNT>\n              <ACTUALQTY> 120 Pcs</ACTUALQTY>\n              <BILLEDQTY> 120 Pcs</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-65760</AMOUNT>\n                <ACTUALQTY> 120 Pcs</ACTUALQTY>\n                <BILLEDQTY> 120 Pcs</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-65760</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Ramen Noodel 300g</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>55/Pcs</RATE>\n              <AMOUNT>-4400</AMOUNT>\n              <ACTUALQTY> 80 Pcs</ACTUALQTY>\n              <BILLEDQTY> 80 Pcs</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-4400</AMOUNT>\n                <ACTUALQTY> 80 Pcs</ACTUALQTY>\n                <BILLEDQTY> 80 Pcs</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-4400</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Gochujang Korean Chilly Paste 500 Gm</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>195/Pcs</RATE>\n              <AMOUNT>-4680</AMOUNT>\n              <ACTUALQTY> 24 Pcs</ACTUALQTY>\n              <BILLEDQTY> 24 Pcs</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-4680</AMOUNT>\n                <ACTUALQTY> 24 Pcs</ACTUALQTY>\n                <BILLEDQTY> 24 Pcs</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-4680</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Sakura Noori Sheet 28 Gm</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>135/Pkt</RATE>\n              <AMOUNT>-13500</AMOUNT>\n              <ACTUALQTY> 100 Pkt</ACTUALQTY>\n              <BILLEDQTY> 100 Pkt</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-13500</AMOUNT>\n                <ACTUALQTY> 100 Pkt</ACTUALQTY>\n                <BILLEDQTY> 100 Pkt</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-13500</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>Good Food People</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>Yes</ISPARTYLEDGER>\n              <AMOUNT>210357</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>IGST 5</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-10017</AMOUNT>\n            </LEDGERENTRIES.LIST>\n          </VOUCHER>\n        </TALLYMESSAGE>\n      </REQUESTDATA>\n    </IMPORTDATA>\n  </BODY>\n</ENVELOPE>	{"igstLedger": "IGST 5", "vendorLedger": "Good Food People", "purchaseLedger": "GST PURCHASE INTER STATE 5%"}	\N	2026-04-18 18:04:58.74	\N	2026-04-18 18:02:21.654	2026-04-18 18:04:58.818
b_1776535570635	c1	438	Good Food People	07ALGPK1152J2Z7	\N	2026-03-23	200340	0	0	10017	210357	SYNCED	\N	{"billDate": "2026-03-23", "subtotal": 200340, "lineItems": [{"unit": "Pcs", "amount": 102000, "gstRate": 5, "hsnCode": "19053100", "quantity": 240, "unitPrice": 425, "description": "Lotus Biscuite Spread (5%)", "discountPercent": null}, {"unit": "Pcs", "amount": 10000, "gstRate": 5, "hsnCode": "19053100", "quantity": 50, "unitPrice": 200, "description": "Lotus Biscuite (5%)", "discountPercent": null}, {"unit": "Pcs", "amount": 65760, "gstRate": 5, "hsnCode": "18069010", "quantity": 120, "unitPrice": 548, "description": "NUTELLA 750gm Mrp 819/- (5%)", "discountPercent": null}, {"unit": "Pcs", "amount": 4400, "gstRate": 5, "hsnCode": "19021900", "quantity": 80, "unitPrice": 55, "description": "Ramen Noodle 300g*40 Green Label", "discountPercent": null}, {"unit": "Pcs", "amount": 4680, "gstRate": 5, "hsnCode": "21039040", "quantity": 24, "unitPrice": 195, "description": "FassGochujang 500gm (5%)", "discountPercent": null}, {"unit": "Pkt", "amount": 13500, "gstRate": 5, "hsnCode": "21039040", "quantity": 100, "unitPrice": 135, "description": "NOORI SHEET", "discountPercent": null}], "billNumber": "438", "buyerGstin": "09AATPM2300E1ZV", "cgstAmount": 0, "igstAmount": 10017, "sgstAmount": 0, "vendorName": "Good Food People", "totalAmount": 210357, "vendorGstin": "07ALGPK1152J2Z7", "roundOffAmount": null}	t	null	<?xml version="1.0" encoding="utf-8"?>\n<ENVELOPE>\n  <HEADER>\n    <TALLYREQUEST>Import Data</TALLYREQUEST>\n  </HEADER>\n  <BODY>\n    <IMPORTDATA>\n      <REQUESTDESC>\n        <REPORTNAME>Vouchers</REPORTNAME>\n      </REQUESTDESC>\n      <REQUESTDATA>\n        <TALLYMESSAGE xmlns:UDF="TallyUDF">\n          <VOUCHER VCHTYPE="GST PURCHASE" ACTION="Create" OBJVIEW="Invoice Voucher View">\n            <DATE>20260418</DATE>\n            <VOUCHERNUMBER>438_2</VOUCHERNUMBER>\n            <REFERENCEDATE>20260323</REFERENCEDATE>\n            <VOUCHERTYPENAME>GST PURCHASE</VOUCHERTYPENAME>\n            <PARTYLEDGERNAME>Good Food People</PARTYLEDGERNAME>\n            <PARTYMAILINGNAME>Good Food People</PARTYMAILINGNAME>\n            <REFERENCE>438</REFERENCE>\n            <VCHENTRYMODE>Item Invoice</VCHENTRYMODE>\n            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>\n            <ISINVOICE>Yes</ISINVOICE>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Lotus Biscoff Spread (18%)</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>425/Pcs</RATE>\n              <AMOUNT>-102000</AMOUNT>\n              <ACTUALQTY> 240 Pcs</ACTUALQTY>\n              <BILLEDQTY> 240 Pcs</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-102000</AMOUNT>\n                <ACTUALQTY> 240 Pcs</ACTUALQTY>\n                <BILLEDQTY> 240 Pcs</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-102000</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Lotus Biscoff Biscuits (Imp)</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>200/Pcs</RATE>\n              <AMOUNT>-10000</AMOUNT>\n              <ACTUALQTY> 50 Pcs</ACTUALQTY>\n              <BILLEDQTY> 50 Pcs</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-10000</AMOUNT>\n                <ACTUALQTY> 50 Pcs</ACTUALQTY>\n                <BILLEDQTY> 50 Pcs</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-10000</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Nutella 750 GM MRP 799</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>548/Pcs</RATE>\n              <AMOUNT>-65760</AMOUNT>\n              <ACTUALQTY> 120 Pcs</ACTUALQTY>\n              <BILLEDQTY> 120 Pcs</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-65760</AMOUNT>\n                <ACTUALQTY> 120 Pcs</ACTUALQTY>\n                <BILLEDQTY> 120 Pcs</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-65760</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Ramen Noodel 300g</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>55/Pcs</RATE>\n              <AMOUNT>-4400</AMOUNT>\n              <ACTUALQTY> 80 Pcs</ACTUALQTY>\n              <BILLEDQTY> 80 Pcs</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-4400</AMOUNT>\n                <ACTUALQTY> 80 Pcs</ACTUALQTY>\n                <BILLEDQTY> 80 Pcs</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-4400</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Gochujang Hot Pepper Paste 500 Gm</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>195/Pcs</RATE>\n              <AMOUNT>-4680</AMOUNT>\n              <ACTUALQTY> 24 Pcs</ACTUALQTY>\n              <BILLEDQTY> 24 Pcs</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-4680</AMOUNT>\n                <ACTUALQTY> 24 Pcs</ACTUALQTY>\n                <BILLEDQTY> 24 Pcs</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-4680</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>Sakura Noori Sheet 28 Gm</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>135/Pkt</RATE>\n              <AMOUNT>-13500</AMOUNT>\n              <ACTUALQTY> 100 Pkt</ACTUALQTY>\n              <BILLEDQTY> 100 Pkt</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-13500</AMOUNT>\n                <ACTUALQTY> 100 Pkt</ACTUALQTY>\n                <BILLEDQTY> 100 Pkt</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>GST PURCHASE INTER STATE 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-13500</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>Good Food People</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>Yes</ISPARTYLEDGER>\n              <AMOUNT>210357</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>IGST 5</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-10017</AMOUNT>\n            </LEDGERENTRIES.LIST>\n          </VOUCHER>\n        </TALLYMESSAGE>\n      </REQUESTDATA>\n    </IMPORTDATA>\n  </BODY>\n</ENVELOPE>	{"igstLedger": "IGST 5", "vendorLedger": "Good Food People", "purchaseLedger": "GST PURCHASE INTER STATE 5%"}	\N	2026-04-18 18:06:41.94	\N	2026-04-18 18:06:10.635	2026-04-18 18:06:42.014
b_1776537696035	c1	GSLUK2526/972425	Universal Corporation Limited	09AAACU3756A1ZJ	\N	2026-01-27	103744.44	9337	9337	0	122418	PARSED	\N	{"billDate": "2026-01-27", "subtotal": 103744.44, "lineItems": [{"unit": "PCS", "amount": 51872.22, "gstRate": 18, "hsnCode": "85068090", "quantity": 216, "unitPrice": 269.83, "description": "DU UL AA SBL 8X12X6 OLPP IN LE TP INR 440", "discountPercent": null}, {"unit": "PCS", "amount": 51872.22, "gstRate": 18, "hsnCode": "85068090", "quantity": 216, "unitPrice": 269.83, "description": "DU UL AAA SBL 8X12X6 OLPP IN LE TP INR 440", "discountPercent": null}], "billNumber": "GSLUK2526/972425", "buyerGstin": "09AATPM2300E1ZV", "cgstAmount": 9337, "igstAmount": 0, "sgstAmount": 9337, "vendorName": "Universal Corporation Limited", "totalAmount": 122418, "vendorGstin": "09AAACU3756A1ZJ", "roundOffAmount": -0.44}	f	\N	\N	\N	-0.44	\N	\N	2026-04-18 18:41:36.035	2026-04-18 18:41:36.07
\.


--
-- Data for Name: Company; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Company" (id, name, gstin, email, port, mapping, "voucherCounter", "createdAt") FROM stdin;
c2	Electronics Hub	27AAFCS5859R1Z4	accounts@ehub.in	9000	{"cgst": "Input CGST @9%", "igst": "Input IGST", "sgst": "Input SGST @9%", "purchase": "Electronics Purchase"}	0	2026-04-17 20:30:42.489
c3	Raj Pharma Store	09AAACR5055K1Z5	raj@pharmastore.com	9000	\N	0	2026-04-17 20:30:42.581
c1	Sharma Groceries Pvt Ltd	07AABCS1429B1Z1	groceries@sharma.com	9000	{"igst_5": "IGST 5", "igst_18": "IGST 18", "input_cgst_9": "Input CGST 9%", "input_sgst_9": "Input SGST 9%", "purchase_up_5": "Purchase UPGST 5%", "input_cgst_2_5": "Input CGST 2.5%", "input_sgst_2_5": "Input SGST 2.5%", "purchase_up_18": "Purchase UPGST 18%", "purchase_exempt": "PURCHASE GST @ 0%", "roundoff_ledger": "Round Off", "purchase_interstate_5": "GST PURCHASE INTER STATE 5%", "purchase_interstate_18": "GST PURCHASE INTERSTATE 18"}	2	2026-04-17 20:30:42.39
\.


--
-- Data for Name: LedgerCache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LedgerCache" (id, "companyId", name, "group", gstin, state, "openingBalance", "gstRegistrationType") FROM stdin;
a3d7a00e-4e0c-4861-aae0-6cb78afcf34d	c1	Keshav Sweet	Sundry Debtors	\N	\N	0.00	\N
b5fcc646-b9e2-403b-86e1-1582fb1db230	c1	RAJU NETA CHAI	Sundry Debtors	\N	\N	-7200.00	\N
16bbe2ad-e6e2-4866-9c60-fcdd3d531357	c1	Risers	Sundry Debtors	\N	\N	0.00	Unregistered
82b43679-a049-4d33-af2a-a41e258306bd	c1	Shri Enterprises	Sundry Debtors	\N	\N	0.00	\N
210b027e-b9f7-40e9-8fe7-5fddd80ecd94	c1	11-11	Sundry Debtors	\N	\N	0.00	Unregistered
09e05637-6337-4b25-8e21-a466a5605e7a	c1	24*7 Bhatia Hospitality Private Limited	Sundry Debtors	09AADCI7967C1ZB	\N	-42809.80	Regular
c304f202-1a4d-4473-8ac0-ed2bbf1d1bc9	c1	3 Bros	Amazon Debtors	09AACFZ4376L1ZH	\N	0.00	Regular
76b97ca1-df4e-4070-a867-6c399cee613f	c1	3 Guys	Sundry Debtors	09AAUFT8430B1ZV	\N	0.00	Regular
fe8f0877-4cec-4904-ae62-97c6efdb1d41	c1	4d Telecom Solution Pvt Ltd	Amazon Debtors	06AIZPA2274R1ZI	\N	0.00	Regular
a19b8aae-58c3-455b-8a8d-1428bfd3335a	c1	Aaaradhya Enterprises	Sundry Creditors	09AQZPJ0213F1ZT	\N	0.00	Regular
d94e1266-7b17-4b31-b4ba-5ad9f39b404b	c1	Aakrti Store	Sundry Debtors	\N	\N	0.00	Unregistered
fa99f33d-9b14-4a84-bfdd-709a0a45ec7b	c1	AARADHYA ENTERPRISES	Sundry Creditors	09BISPD1644J1ZZ	\N	0.00	Regular
39b93f3d-36d4-4e6f-a417-1372c366b641	c1	Aarav Enterprises	Sundry Debtors	09DJZPP6026G1ZH	\N	0.00	Regular
80b82db6-c18f-4ea9-a044-491eb8c4256c	c1	AASK FACILITY SOLUTIONS LLP	Sundry Creditors	\N	\N	0.00	\N
5e3bc2d4-c74e-4479-a262-5decab39984b	c1	Aasmi Enterprises	Sundry Debtors	09ABPFA8606A1ZH	\N	0.00	Regular
358b7e5a-495e-4597-bcc2-07c22b77f509	c1	AAY VEE BAKERS LLP	Sundry Debtors	09ACAFA6800E1ZU	\N	-53940.00	Regular
d8d67514-bef9-4b27-86fd-d1c4729a2057	c1	AAY VEE CATERERS PRIVATE LIMITED	Sundry Debtors	09AAJCA3291K2ZA	\N	-2375.00	Regular
1b6af92e-3ffe-4efa-8fe7-f0761f1c5ee5	c1	ABC Bajar	Sundry Debtors	09BPXPK8015E1ZH	\N	0.00	Regular
a2e39937-bd10-4946-8aa1-e4dde342968c	c1	Aber Enterprises	Sundry Debtors	\N	\N	-2880.00	\N
a3dcc0f6-6542-43ce-ac9c-6651acd3d94f	c1	Abhay	Sundry Debtors	\N	\N	0.00	Unregistered
3c5df628-44fb-4f7b-9c92-15acaaab1c4e	c1	ABHINAY REF.&amp; ELECTRICAL	Sundry Creditors	\N	\N	0.00	Unregistered
2ceb7e1b-378b-4d6c-8b2b-81a17efcb9a7	c1	Abhinay Refigretor	Sundry Debtors	09AMKPG0277H1ZZ	\N	0.00	Regular
1f8ba67f-1cb3-4303-a867-589a0a8c1af3	c1	Abhshek Jain	Sundry Debtors	\N	\N	0.00	Unregistered
0425d19f-d829-4e48-aa83-70edfa409a99	c1	A.B.K.D. Enterprises	Sundry Creditors	09AAIFA5883F1Z7	\N	0.00	Regular
ca3d23a1-5a21-488c-ab52-59221cc0bd85	c1	ACCESSORIES @ 18%	Fixed Assets	\N	\N	-5084.74	\N
6e84d2be-f86d-416a-b585-3560dbeef9c0	c1	Accountancy Charges Payable	Provisions	\N	\N	0.00	\N
fcf72432-7fdc-478a-8dc0-4cc87fe3c673	c1	Accounting Charges	Indirect Expenses	\N	\N	0.00	\N
cf796ce2-652e-453a-900b-9767b44e54dd	c1	Accounting Chargess	Indirect Expenses	\N	\N	0.00	\N
df3e166d-3756-4f8f-bca5-4248d60e3438	c1	Ace Foods	Sundry Creditors	07ACBFA8337K1Z8	\N	0.00	Regular
8a66b56d-711b-414b-99bf-fd34913cdf22	c1	Ace Pan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
84f4c383-17ae-4d1f-bcb5-f3f8d9555d32	c1	Adarsh	Sundry Debtors	\N	\N	0.00	Unregistered
d1f914f5-c9fa-4851-a4c0-45e50ca42366	c1	Adarsh Confactionery	Sundry Debtors	09FTBPS4341P1ZZ	\N	0.00	Regular
370bb67b-b8ce-4c1c-87f9-aac6ddd9e2fb	c1	Adarsh Cornor.......x	Sundry Debtors	09AAHPN3983A1ZN	\N	0.00	Regular
f7457926-bd3e-49fa-a571-1bbbbd7a9655	c1	Adarsh Tyres And Tread PVT LTD	Amazon Debtors	23AAECA8192L1ZE	\N	0.00	Regular
e387eb75-4c23-4085-a773-ca8d6e85154e	c1	ADL	Sundry Debtors	07BOYPS8580Q1Z8	\N	0.00	Regular
72fae6ad-1cb6-4799-bcba-72555f246848	c1	Adlabs Sales  Ltd .	Sundry Debtors	\N	\N	0.00	\N
993e55af-7bb7-436e-8a7d-66c0c3e03714	c1	Adlabs Sales (P) Ltd ( Rave Moti)	Sundry Debtors	\N	\N	0.00	\N
660eb0cf-e118-4c3f-9904-df365d7cdd47	c1	Adrisha Enterprises	Sundry Debtors	09BUGPD9166H1ZB	\N	0.00	Regular
95e4ce80-ed2a-47bc-94d8-49d7f076b05e	c1	ADS Mart	Sundry Debtors	09ABEFR8501N1ZQ	\N	0.00	Regular
c76b4c90-2bcf-49e1-b13a-35a758dd8951	c1	Advertising Services	Indirect Expenses	\N	\N	0.00	\N
e40cd56d-f6da-4229-96d4-8638c82f5317	c1	Agastya Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
a4829ca0-043b-4f85-9aee-6d0b9e6352cb	c1	Agnihotri General Store	Sundry Debtors	\N	\N	0.00	Unregistered
27f9c93e-d89b-4bf5-ae3f-64227f6cc7e5	c1	Agrahari Agencies3	Sundry Debtors	09ABVPA7358K1ZY	\N	0.00	Regular
f7b870d1-03d2-457a-8078-6ea35a20d37d	c1	AGRA SWEET HOUSE	Sundry Debtors	09ADKPK9595M1ZG	\N	0.00	Regular
8f252775-0b2d-4dcd-91bb-6ad81f222133	c1	Agra Vala Sweets (Gumti)	Sundry Debtors	\N	\N	0.00	\N
19ff453b-4389-45b0-af33-f6f6067a2155	c1	Agrim Sales Corporation	Sundry Debtors	09CEHPD1361N1ZC	\N	0.00	Regular
d9d3260c-cd6c-4b4d-8e3c-e654f8699f59	c1	Ahuja Medical Store	Sundry Debtors	\N	\N	0.00	Unregistered
5572da1f-1cfc-4cab-b129-03900796a4e7	c1	Ahuja Times	Sundry Debtors	09ABGPA8068F1ZN	\N	-4739.00	Regular
6d422315-c846-49bd-9845-e4504035e2d8	c1	Ahuja Watch House	Sundry Debtors	09ABGPA8067L1ZB	\N	0.00	Regular
df09fdde-e9d7-4d17-bf80-647e0c6ae0fb	c1	AIM EXPRESS LOGISTICS	Sundry Debtors	\N	\N	0.00	\N
9962f39f-db73-4a1b-b4f6-9cee626aa208	c1	AIR CONDITIONER @ 28%	Fixed Assets	\N	\N	-32716.25	\N
b6a1e6e3-d2c3-41ec-b1f0-4ebf4a3f5a25	c1	Ajay Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
526cd4c5-e86e-44be-a759-32e88e3732f9	c1	Ajay Marketing	Sundry Creditors	09ACBPG9558Q1ZS	\N	0.00	Regular
988f8eed-4c19-4fcd-b430-37d0a9a39779	c1	Ajay Raviprakash Sonar	Amazon Debtors	27BUPPS8604E1Z6	\N	0.00	Regular
a26d8523-ec8f-4181-864f-eb4dba1303fb	c1	Ajay Store	Sundry Debtors	\N	\N	0.00	Unregistered
49bae67b-1ffa-4b84-9707-d95d29e9fe6d	c1	Ajay Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
c1233a56-25a8-4762-9ada-4aefe92bd069	c1	Ajeet Tachnocloth	Sundry Debtors	\N	\N	0.00	Unregistered
b3042a25-aa4b-4b31-9426-3e0791139526	c1	Ajmeri Food Chain	Sundry Debtors	09ABGPW9285N2ZE	\N	0.00	Regular
9d79ce50-f31f-4c6c-b849-801d58e37666	c1	Akansha Stores	Sundry Debtors	\N	\N	0.00	Unregistered
3dbbe97c-0ca4-49c4-ad9a-52d71096abcf	c1	AKASH GENERAL STORE	Sundry Debtors	\N	\N	0.00	Unregistered
049fb85f-880d-4e0e-a380-e648fc4c3ca5	c1	Akash Genral Store	Sundry Debtors	\N	\N	0.00	Unregistered
73140b48-0cb9-495c-b166-8bf6761edfe6	c1	Akash Holidays	Amazon Debtors	30ANNPC7855M2ZN	\N	0.00	Regular
1a68fe3f-edc2-4698-8173-5dc4b7227581	c1	Akash Mart	Sundry Debtors	\N	\N	0.00	Unregistered
01c18cb6-5f02-4679-81f0-d9b5845a8563	c1	A.K.Foods Agencies	Sundry Creditors	\N	\N	0.00	Unregistered
ead03102-f46b-4319-ad87-5204c5b9a5f9	c1	Akhil Electronics	Sundry Debtors	09AJSPA8639G1ZR	\N	0.00	Regular
524e1bea-6e87-4ac0-945e-4c015d175298	c1	Akhil Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
7147ce7b-3911-41ca-a0b5-101e3fce701e	c1	A.K. Marketing (2021-22)	Sundry Debtors	09ABIFA3305M1ZD	\N	0.00	Regular
bf5d42c4-5545-4099-962f-768b22cdbcc8	c1	Akrita	Sundry Debtors	\N	\N	0.00	Unregistered
9c82aa10-bdbd-445c-a65d-f5bfa5aee071	c1	Akshara Store	Capital Account	\N	\N	0.00	Unregistered
c2445d58-00a4-4dce-b039-f22c1e23cb9f	c1	Akshaya Wealth Management Pvt Ltd	Amazon Debtors	29AAGCA2492R1ZX	\N	0.00	Regular
f4d5e29c-e451-4792-a2f9-0186d9a800da	c1	Ali&apos;s Cafe and Pizzeria LLP	Sundry Debtors	09ABPFA8115L1ZY	\N	-175000.00	Regular
1a1a01be-25fc-4093-8d21-e8afeb147ce6	c1	Ali&apos;s Cafe And Pizzeria LLP (GURUGRAM)	Sundry Debtors	\N	\N	-20000.00	\N
3e933b15-1f79-4121-9304-c6b466cd2eb3	c1	Allianz Marketing	Sundry Creditors	09AGIPS5126K1ZX	\N	0.00	Regular
aeb47b93-270a-420f-8354-3858ee085f33	c1	All Time Foods Pvt.Ltd.	Sundry Debtors	09AACCA2111M1ZX	\N	-5793.00	Regular
c28344e4-7d7a-480d-a27b-6e32fc62bc46	c1	Almost Cafe	Sundry Debtors	\N	\N	0.00	Unregistered
3c76ac60-3d1b-4b19-a7a1-bd6a14030942	c1	Aloha Engineering Private Limited	Amazon Debtors	33AATCA5518M1Z8	\N	0.00	Regular
a8ef733c-5460-4e52-83b8-0aff08098abd	c1	ALOK AGENCY	Sundry Debtors	\N	\N	0.00	Unregistered
7993ead3-2377-48ae-917d-f0d0748c9b04	c1	Alok Medical	Sundry Debtors	\N	\N	0.00	Unregistered
68aa06b3-14fa-48b7-aab4-4b7ecb6e9f35	c1	Alpine Foods	Sundry Debtors	09CUQPA5208N1Z7	\N	0.00	Regular
42669205-03ec-488e-b7f2-54651c735f80	c1	Al-Taj Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
c8686f09-22a5-47a1-b655-562b5cf06fd0	c1	Always Open	Sundry Debtors	\N	\N	0.00	Unregistered
8e2b5ce3-1391-457e-bba7-3698a3ffdb1f	c1	Aman	Sundry Debtors	\N	\N	0.00	\N
aa57f2ba-b25d-4f88-ac5d-ff885fefdc1f	c1	AMAN QURAISHI	Sundry Debtors	\N	\N	0.00	Unregistered
b496c099-7084-435d-8bed-fce4dbf8c2dc	c1	Aman Traders	Sundry Debtors	09AHZPG1096Q1Z9	\N	0.00	Regular
e34a4a8f-d303-4ab2-896c-0744b2ac3f92	c1	Amara India	Amazon Debtors	27ABGPA4160L1ZR	\N	0.00	Regular
60eac353-7a7c-4e74-bc2e-5a767adcee41	c1	AMAR CHAND SURESH CHAND	Sundry Debtors	\N	\N	0.00	Unregistered
d03083e4-42d3-4955-8c8d-5e38b682199f	c1	Amar Chemist	Sundry Debtors	\N	\N	0.00	Unregistered
c536120e-294c-4aee-b57a-ce4f49c7ffc0	c1	Amar Deep Store	Sundry Debtors	\N	\N	0.00	Unregistered
ceac206b-5af4-457d-807a-12d7267ddd62	c1	Amar General Store	Sundry Debtors	09AFPPS4429B1Z7	\N	0.00	Regular
dbea59d8-cf24-46bd-99a5-7ea216839cae	c1	Amarjeet Store	Sundry Debtors	\N	\N	0.00	Unregistered
847cc762-6d7b-42df-bcaf-2eecbd4c8ef7	c1	Amar Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
de9e4f6f-8f43-449a-8955-3b9b0766ca6a	c1	Amazon Andaman &amp; Nicobar Islands	Amazon Debtors	\N	\N	0.00	Unregistered
9aefb319-10b6-4a5d-8fc4-58f164896f82	c1	Amazon Andhra Pradesh	Amazon Debtors	\N	\N	0.00	Unregistered
2d936a64-f59d-4df2-b7f3-9bb5353706d8	c1	Amazon Arunachal Pradesh	Amazon Debtors	\N	\N	0.00	Unregistered
819dcb8e-7dac-4869-bf21-f2fa070cecc6	c1	Amazon Assam	Amazon Debtors	\N	\N	0.00	Unregistered
aca23c3b-2520-4f30-b3d9-0e2bde1b39d9	c1	Amazon Bangalore	Amazon Debtors	\N	\N	0.00	Unregistered
4ecc2369-1a08-4102-a486-b1b6a56a464b	c1	Amazon Bihar	Amazon Debtors	\N	\N	0.00	Unregistered
ddb0a59b-4db9-49ae-8aeb-b8372361443f	c1	Amazon Chandigarh	Amazon Debtors	\N	\N	0.00	Unregistered
33433db3-8cbb-4695-9b34-ffb906a1f4fc	c1	Amazon Chennai	Amazon Debtors	\N	\N	0.00	Unregistered
0eb24e34-0948-40b3-a86c-407cfa0b5a68	c1	Amazon Chhattisgarh	Amazon Debtors	\N	\N	0.00	Unregistered
e0b1a46d-7916-4e7d-b72f-e6f1e8bd65ec	c1	Amazon Closing Fees	Indirect Expenses	\N	\N	0.00	\N
f92ad904-4cb4-45a5-abcd-d6e90105ade4	c1	Amazon Commission	Indirect Expenses	\N	\N	0.00	\N
6874267b-b368-441b-a182-b832f69de1b7	c1	Amazon Dadra &amp; Nagar Haveli And Daman &amp; Diu	Amazon Debtors	\N	\N	0.00	Unregistered
d7db5c78-599d-486b-98db-a1336f02f3d4	c1	Amazon Debtors	Sundry Debtors	\N	\N	0.00	Unregistered
c527487c-5ccf-4a53-90ee-2ef47fd49422	c1	Amazon Delhi	Amazon Debtors	\N	\N	0.00	Unregistered
9f89696d-e19f-4f58-ad40-1ab880d37381	c1	Amazon Goa	Amazon Debtors	\N	\N	0.00	Unregistered
ef31db71-9615-4519-8faf-a92f2dfd99ba	c1	Amazon Gujarat	Amazon Debtors	\N	\N	0.00	Unregistered
96629224-3614-4610-9085-5a4387698eff	c1	Amazon Haryana	Amazon Debtors	\N	\N	0.00	Unregistered
00a3e996-f388-4080-8a3a-cdce9c9fe612	c1	Amazon Himachal Pradesh	Amazon Debtors	\N	\N	0.00	Unregistered
460ab17b-adfe-41f2-9f84-6424d9a9eac3	c1	Amazon Jammu &amp; Kashmir	Amazon Debtors	\N	\N	0.00	Unregistered
ed30d204-25c6-4a44-b016-80e4053bb7f8	c1	Amazon Jharkhand	Amazon Debtors	\N	\N	0.00	Unregistered
d78becc4-be1b-4c57-98cf-5a0a8f31412d	c1	Amazon Karnataka	Amazon Debtors	\N	\N	0.00	Unregistered
cbede337-badd-45c3-a309-acc3976bf77f	c1	Amazon Kerala	Amazon Debtors	\N	\N	0.00	Unregistered
9810d1d6-8ea3-48f7-b4b6-7638d6487ffa	c1	Amazon Lakshadweep	Amazon Debtors	\N	\N	0.00	Unregistered
5d7c0736-18dc-4c25-890f-fe65f5775677	c1	Amazon Madhya Pradesh	Amazon Debtors	\N	\N	0.00	Unregistered
623c85c7-ba6f-41af-9b6b-ebd34168aef3	c1	Amazon Maharashtra	Amazon Debtors	\N	\N	0.00	Unregistered
c1668535-a496-469b-9529-0817ec66e84f	c1	Amazon Manipur	Amazon Debtors	\N	\N	0.00	Unregistered
ac224110-88a3-41c4-81a7-db0689e76fb7	c1	Amazon Meghalaya	Amazon Debtors	\N	\N	0.00	Unregistered
9867f529-e307-4aa8-8ffd-6490df627c0e	c1	Amazon Mizoram	Amazon Debtors	\N	\N	0.00	Unregistered
9ab5134b-c497-4585-8665-b8694f34ab0b	c1	Amazon Nagaland	Amazon Debtors	\N	\N	0.00	Unregistered
a379a802-ccc7-4fca-91b3-676f038c8abf	c1	Amazon Odisha	Amazon Debtors	\N	\N	0.00	Unregistered
6af49398-e66a-4115-a20d-b1930666984c	c1	Amazon Payments	Sundry Debtors	\N	\N	0.00	Unregistered
77196c14-ff9c-4a94-8f45-fc5b4fad1481	c1	Amazon Pudducherry	Amazon Debtors	\N	\N	0.00	Unregistered
c022d2b3-2c8f-44b7-8d17-3a0d9328baa3	c1	Amazon Punjab	Amazon Debtors	\N	\N	0.00	Unregistered
3036d9e7-4366-45ab-b12e-2eadc4f64925	c1	Amazon Rajasthan	Amazon Debtors	\N	\N	0.00	Unregistered
a3f73fd8-ff7c-44ff-9a49-2a61f02a00e5	c1	AMAZON SELLER SERVICES	Sundry Debtors	\N	\N	-8522.38	\N
9c0e181c-7b61-48fc-8a23-8ec5f293aabe	c1	Amazon Seller Services Private Limited	Sundry Debtors	29AAICA3918J1ZE	\N	8317.59	Regular
58dda548-867a-4142-ba6d-230760641436	c1	Amazon Service Charges	Indirect Expenses	\N	\N	0.00	\N
e82061ef-f01a-4113-b928-f6eb1c423701	c1	Amazon Sikkim	Amazon Debtors	\N	\N	0.00	Unregistered
5d87b1d2-e6ad-4e9c-a33b-27e306e3056e	c1	Amazon Tamil Nadu	Amazon Debtors	\N	\N	0.00	Unregistered
51a3b392-14ab-40b6-957c-fe3d6c23e1cb	c1	Amazon Telangana	Amazon Debtors	\N	\N	0.00	Unregistered
2f574336-2950-4e1e-b14d-9e093729edc8	c1	Amazon Tripura	Amazon Debtors	\N	\N	0.00	Unregistered
54713c1a-c953-4e89-acb6-48803ba525f6	c1	Amazon Uttarakhand	Amazon Debtors	\N	\N	0.00	Unregistered
aef9f745-eb6c-45aa-b10d-1b941228c8e7	c1	Amazon Uttar Pradesh	Amazon Debtors	\N	\N	0.00	Unregistered
d39fc844-f6d8-4a44-b96a-1a32ab39ac47	c1	Amazon West Bengal	Amazon Debtors	\N	\N	0.00	Unregistered
f7be75be-b701-4d38-a28e-39ea2f103824	c1	Amber Agencies	Sundry Debtors	\N	\N	-289.00	\N
66835f90-dd12-4e73-abfd-67aa5fd48692	c1	AMBIKA KIRANA STORE	Sundry Debtors	\N	\N	0.00	Unregistered
0186b1b7-b213-42a3-9a59-bb69f539f602	c1	Ambresh General Store	Sundry Debtors	\N	\N	0.00	Unregistered
66ce5977-24cf-48a2-aa1b-44e0a1e5f243	c1	Ambrosia	Sundry Debtors	\N	\N	0.00	Unregistered
bd5d3cb3-b273-4dd9-b8a2-05ec737fdcfa	c1	Amit Deep Medical	Sundry Debtors	09AAKFA8610Q1ZV	\N	0.00	Regular
163dbdd7-afc4-489f-b4b8-5ea74c3a8407	c1	Amit Dubey	Sundry Debtors	\N	\N	0.00	Unregistered
43b805c0-b8f3-437b-8049-1f7cf535a3ce	c1	Amit Electronics	Sundry Debtors	09AEPPG6797P2Z8	\N	0.00	Regular
51729b0b-dcc2-456e-82dc-05c8e1218cbd	c1	Amit Electronics &amp; Mobile Co.	Sundry Debtors	09AQFPG8139B3ZX	\N	0.00	Regular
c4179cf6-30ba-4ad1-9277-f4cd57523630	c1	AMIT GARMENTS	Sundry Debtors	09ARNPA3100H1Z8	\N	0.00	Regular
283cc17c-4c21-4d4c-8561-4bc29b1c7a32	c1	AMIT KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
be335323-ec58-45fc-add9-fbcc6f505151	c1	Amit Medical	Sundry Debtors	\N	\N	0.00	Unregistered
c268867c-1dce-4329-b27a-3d1f92ead1a1	c1	Amit Pandey	Sundry Debtors	\N	\N	0.00	\N
56497f4c-9ffb-4a68-bff0-4abee095b0e6	c1	Amit Store	Sundry Debtors	\N	\N	0.00	Unregistered
b0d7f981-1c7a-4189-8e30-8709cbba518f	c1	AMRIT TRADERS	Sundry Creditors	\N	\N	0.00	Unregistered
a0b527bf-2dbc-4de3-9066-992d3ee41f38	c1	ANA Desinhworx Private Limited	Amazon Debtors	09AAKCA4254B1ZW	\N	0.00	Regular
6e301ee9-3a99-45b0-93c2-2e75fa7408c0	c1	Ananad Confectionery	Sundry Debtors	\N	\N	0.00	Unregistered
ecf86ae9-00e9-48b1-b838-8de2ac9db8ca	c1	Ananaya Enterprises	Sundry Debtors	09ABKFA6117F1ZI	\N	0.00	Regular
68a7abef-7461-4129-9110-8f9574814db1	c1	Anandeshwar Departmental Store	Sundry Debtors	09ABNFA3731G1ZF	\N	0.00	Regular
a15af24c-f90c-437b-a48c-4c7dff8d5c81	c1	Anand F&amp;B Distributions Pvt.Ltd.	Sundry Creditors	07AALCA5634J1ZG	\N	0.00	Regular
dea95e14-30a2-4cf3-a434-57e30a6b0017	c1	Anand Kedia	Sundry Debtors	\N	\N	0.00	Unregistered
df12509c-b99c-4616-b5b4-22e66b079d8a	c1	Anand Ram &amp;Sons.	Sundry Debtors	\N	\N	0.00	Unregistered
7090b024-3ee1-4854-a1e8-992d2de3288f	c1	Anand Store	Sundry Debtors	\N	\N	0.00	Unregistered
e2a2f0fe-d168-47f7-a67f-1187e708e7dd	c1	ANAND TRADERS	Sundry Debtors	09DIBPK7523L1ZX	\N	0.00	Regular
ff89a026-0764-4111-94f1-e80a581f8172	c1	A N Enterprises	Sundry Debtors	09ABCPT3526F1ZN	\N	0.00	Regular
11bfb46c-0099-4627-9c20-89601d27f71c	c1	A N Foods	Sundry Debtors	\N	\N	0.00	Unregistered
b0b79df4-cb38-4fa8-8170-e52d7169489b	c1	ANGAD CREATIONS	Sundry Debtors	09DTMPS7926F1ZY	\N	0.00	Regular
cbe7dcbf-e8d3-4097-a55c-5b38b9270a29	c1	Anil Kirana Store	Sundry Debtors	\N	\N	0.00	Unregistered
7d9b2afe-ec23-44c1-9bf3-daee1f6bf8d4	c1	Anil Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
fdb2cb5c-9b45-479e-a20e-b45daf3b4670	c1	ANIL MANGO SHAKE	Sundry Debtors	\N	\N	0.00	Unregistered
3d90fcd7-7ed6-47bf-ad9b-49910c366791	c1	Anil Mango Store	Sundry Debtors	\N	\N	0.00	Unregistered
3d6cc3e3-51b4-4390-ae8c-baa5c2405ffd	c1	Anil Medical Store	Sundry Debtors	\N	\N	0.00	Unregistered
c6d6de43-38ab-411b-8293-ff4f2788b161	c1	Anil Store	Sundry Debtors	\N	\N	0.00	Unregistered
9cc52d8d-660a-426f-9a77-a4e252c7b5da	c1	Anjaney Pharma Care	Sundry Debtors	\N	\N	0.00	Unregistered
33057998-359f-470d-94e8-044768e5427c	c1	Anju Store	Sundry Debtors	\N	\N	0.00	Unregistered
f939065e-c656-42f1-a500-9612f8d7e77f	c1	ANKIT	Sundry Debtors	\N	\N	0.00	Unregistered
57a50ea3-5149-46c5-83fb-4d9c40f24fd4	c1	Ankita Mehrotra	Unsecured Loans	\N	\N	0.00	\N
2a6defed-e206-447d-9736-9d30b53fc1cf	c1	Ankit Confectionery Store	Sundry Debtors	09BFIPA6560F3ZH	\N	-900.00	Regular
b70a0530-4f28-4882-91df-630ad3fb40cd	c1	Ankit Genral Store	Sundry Debtors	\N	\N	0.00	Unregistered
19349562-9e72-46c5-8358-f982cc09bfad	c1	Ankit Universal	Sundry Debtors	\N	\N	0.00	\N
85c0f57f-668b-42fc-8109-c248994dcd14	c1	Ankush Catters	Sundry Debtors	\N	\N	0.00	Unregistered
9ca1ccc1-26b2-48dc-9e20-29cb7228b658	c1	Ankush Store	Sundry Debtors	\N	\N	0.00	Unregistered
60d30c01-4118-46d2-ae8e-8a7d43fa6aed	c1	Anmol Ji Store	Sundry Debtors	\N	\N	0.00	Unregistered
d50201b9-7c63-4af4-ac15-f7221ef4ddc1	c1	Annapurna Trading Company	Sundry Creditors	09ABMFA0396G1Z9	\N	0.00	Regular
0e8d0980-a82a-4920-821f-ff7c30528143	c1	Annu Icecream	Sundry Debtors	\N	\N	0.00	Unregistered
90984299-6257-45fe-86ff-45c2cd7213ea	c1	Annu Trading	Sundry Debtors	\N	\N	0.00	Unregistered
50fb7f89-6e9d-4db7-b717-58d0affdac5a	c1	Anu Agarwal	Sundry Debtors	\N	\N	0.00	Unregistered
7bb6b2dc-c7a5-4b45-8ff7-0cbc2f18210c	c1	Anuj Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
2bb1a4cb-6cd3-45f2-8f94-a6dee1f97471	c1	Anupam Store	Sundry Debtors	\N	\N	0.00	Unregistered
642d5558-c4ec-4678-a475-ccc3dbde4b0c	c1	Anurag 9793533021	Sundry Debtors	\N	\N	0.00	Unregistered
2e1f3fd2-0051-46e1-9cf2-b0d75fc01bf1	c1	Anurag Mehrotra (Salary)	Indirect Expenses	\N	\N	0.00	\N
02d9a4c2-6961-42f1-a7be-555733f8675f	c1	Anurag Mehrotra Trns Act	Sundry Creditors	\N	\N	0.00	Unregistered
d74cd26a-a875-4230-a825-34f3ee528306	c1	Anurag Singh	Sundry Debtors	\N	\N	0.00	Unregistered
a92a4423-5a3d-42de-b00a-45e712b19f7c	c1	Anurag Store	Sundry Debtors	\N	\N	0.00	Unregistered
dd560982-375d-4436-b547-fe2bb5b10839	c1	Anushka Sales &amp; Marketing	Sundry Creditors	07AAAPA1447R1ZP	\N	-20.00	Regular
4c916199-6220-4955-8192-6827f8ea556b	c1	Anu Trading	Sundry Debtors	\N	\N	0.00	Unregistered
50d78d8e-0633-4da5-8cad-98b74632ecb9	c1	Apex Agencies	Sundry Debtors	\N	\N	0.00	Unregistered
e17faa76-83ad-45ca-93e2-5873ff43bd63	c1	APEX FINANCIAL &amp; MARKETING SERVICES	Amazon Debtors	03ALQPS8612R1Z7	\N	0.00	Regular
eabf6cc1-5acb-46ed-b069-ff2e2f10f2c9	c1	APJ FOODS PVT.LTD.	Sundry Debtors	09AACCA4893L1Z6	\N	0.00	Regular
10acb347-2d06-4246-8380-3087828c72ca	c1	Apurva Agencies	Sundry Debtors	\N	\N	0.00	Unregistered
fb48d8ac-93d5-4f19-a37a-3d84b4b9a4af	c1	AQUAA BY MCS	Sundry Debtors	\N	\N	0.00	\N
c8b4c134-ef87-43ff-a4f2-8d75ffe16188	c1	Aquamontana India Pvt.Ltd.	Sundry Creditors	\N	\N	0.00	Unregistered
56b5fcb4-71f0-404b-bd81-85fae4ecc383	c1	Arabeque	Sundry Debtors	\N	\N	0.00	\N
69dcf155-d4e0-45f8-aaba-4736db780260	c1	Aradhna Store	Sundry Debtors	\N	\N	0.00	Unregistered
1da7bdc9-a936-4e9e-9f52-3ae1e2549129	c1	Archana Traders	Sundry Creditors	09AEBPS3728L2Z1	\N	0.00	Regular
ea8e3427-50a1-4b9d-81ac-7001536d7b3c	c1	Areva Lifestyle Products Pvt.Ltd.	Sundry Creditors	\N	\N	0.00	Unregistered
dfeae6df-e928-467f-8076-3f1133a2f362	c1	Arinjay Infratech LLP	Sundry Creditors	09ABFFA8396K1ZR	\N	0.00	Regular
44b4a773-59d9-41f8-ac7a-aec41b2c2da5	c1	ARJ	Sundry Debtors	\N	\N	0.00	Unregistered
20d0a1de-d08f-43be-b8d2-13c8a10ef1bb	c1	Arjun Store	Sundry Debtors	\N	\N	0.00	Unregistered
37818461-11fa-4c98-a73f-816d395788d8	c1	Arjun Transport Co.	Creditors Others	09AEWPV3867N1Z2	\N	0.00	Regular
4f11b684-0169-4fbb-93f6-ca7f35b64467	c1	Aromas	Sundry Debtors	09AEEPM4035K1ZD	\N	0.00	Composition
c1674cb3-2648-4255-aaa7-da39b7510200	c1	Arora Confactionary	Sundry Debtors	\N	\N	0.00	Unregistered
fe89eaca-b484-4ecb-af5a-a4380fae9b31	c1	Arora General Store	Sundry Debtors	09ABOPA4558J1ZB	\N	0.00	Regular
dfd6d2eb-e39b-4c06-ad59-a6b96627e3bf	c1	Arora Store	Sundry Debtors	\N	\N	0.00	Unregistered
ed6eaf07-ce0f-4090-aa71-8ccfaa9876e9	c1	Arora  Stores	Sundry Debtors	\N	\N	0.00	Unregistered
1dc552e8-a746-40e3-a0cd-2b7507d46d97	c1	Arpit	Sundry Debtors	\N	\N	0.00	Unregistered
e713cbb8-2748-4830-9160-3a97a0fca468	c1	ARPIT MEHROTRA	Sundry Debtors	\N	\N	0.00	Unregistered
a45481f1-61be-44a0-88af-8c52d32e5698	c1	ARS Foods Ingedieants Pvt.Ltd.	Sundry Creditors	07AAJCA5028J1ZM	\N	0.00	Regular
84aa36a1-391a-426e-9d01-bcd7e24418fc	c1	Articolo India	Sundry Creditors	07AHOPG6534C1ZG	\N	0.00	Regular
17d3c807-3718-42af-b576-5600fac008c0	c1	Arun Agencies	Sundry Debtors	09AUMPK9989Q1Z1	\N	0.00	Regular
1397a702-6850-44a4-bd89-c164b2f9457e	c1	Arun Kirana Store	Sundry Debtors	\N	\N	0.00	Unregistered
592d9e24-5732-4749-8811-237396a137c9	c1	Arvin Traders	Amazon Debtors	33ANCPA4080D1ZR	\N	0.00	Regular
cf95bb5c-43f2-4ed0-b2c9-2ce6078572f2	c1	Arya Havan Samagri	Sundry Debtors	\N	\N	0.00	\N
3a6959e7-acf8-4643-8043-6cf683524996	c1	Asha  Electronic	Sundry Debtors	09AGBPA2894F1ZK	\N	0.00	Regular
aada9464-12e2-4518-8bf3-5f0e68dfb8c6	c1	Asha Electronics	Sundry Debtors	09AGBPA2894F1ZK	\N	0.00	Regular
6864621d-aab9-49ac-a753-101cb9bda04c	c1	Ashif Lucknow	Sundry Debtors	\N	\N	0.00	\N
cdd08b01-67cb-47ab-9f6a-c3e3640e9edd	c1	ASHISH MARKETING	Sundry Creditors	09AAJFA0414D1Z1	\N	0.00	Regular
8397004e-80f1-4867-806e-5e837d82850a	c1	Ashish Medical Store	Sundry Debtors	09BLQPS0105N1ZM	\N	-2310.00	Regular
9473f69f-56f4-4974-b967-9cbf1c995689	c1	Ashish Traders	Sundry Debtors	\N	\N	0.00	Unregistered
5e88a317-2734-48b3-9076-42f4c02edd04	c1	Ashoka Baikery	Sundry Debtors	\N	\N	0.00	Unregistered
30d49432-a62b-49d4-89b7-f1c9cd0aa879	c1	Ashok Agencies	Sundry Debtors	09AJCPM8825C1Z7	\N	0.00	Regular
9bad1ef9-e920-4508-9cdc-50ac9100fd42	c1	Ashok Electrical	Sundry Debtors	\N	\N	0.00	Unregistered
efe9a000-bbad-4de2-9ca7-7ba582702b93	c1	Ashok Kumar &amp; Brothers	Sundry Debtors	\N	\N	0.00	Unregistered
afd5d14f-e9f6-4f34-9152-ee19f78ab872	c1	Ashok Kumar Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
2bde19f7-6b8e-4b88-aafa-3a13454cfbc6	c1	Asian Pantry	Sundry Debtors	\N	\N	-2426152.90	Unregistered
50a5584d-018c-4e77-927a-cdebbcaa11dc	c1	Asiatic Beverages Private Limited	Sundry Creditors	06AAWCA8072H1Z6	\N	0.00	Regular
b214743a-249c-4285-a167-e7b6a1da0cfd	c1	Aspire Automobiles Pvt Ltd	Amazon Debtors	09AAHCA2002N1ZS	\N	0.00	Regular
09d88c63-0673-45bc-bf63-6da38a640d41	c1	Astha Departmental Store Pvt.Ltd.	Sundry Debtors	09AABCA6900B1Z8	\N	0.00	Regular
01da48b7-ccfc-4d39-b868-df0f1ef9c0b0	c1	A S TRADERS	Sundry Creditors	\N	\N	0.00	\N
030307cf-b750-429f-9423-f33f690c1e7d	c1	Atlanta Overseas	Sundry Creditors	\N	\N	0.00	Unregistered
e9a09150-6cca-43bc-acee-276587b8662c	c1	A TO Z Super Market	Sundry Debtors	\N	\N	0.00	Unregistered
b4d32ae5-a565-4005-9e2f-7e5d73e4c59f	c1	Attic Hospitality Pvt.Ltd.	Sundry Debtors	09AAPCA4639R1ZP	\N	0.00	Regular
5bc84459-5b87-407e-87d8-f3db33c7d4c6	c1	AUDI STADIACONSULTANTS PVT.LTD.	Sundry Debtors	09AANCA2860Q1ZY	\N	0.00	Regular
fb3dac82-2d5c-4618-8e3e-d06b9cabca8f	c1	Audit Fee Payable	Provisions	\N	\N	5500.00	\N
79b9e7ea-0117-4418-b06d-04c3bb09ef67	c1	Audit Fees	Indirect Expenses	\N	\N	0.00	\N
eb2e4011-f14f-44fc-bcae-e779adaa9362	c1	Audit Fees(GST)	Indirect Expenses	\N	\N	0.00	\N
7a5dcfbd-09da-49e7-a4d2-ec8856a276b3	c1	A Unit of Mandakini Heaven Huts Pvt Ltd.	Sundry Debtors	09AAHCM7012N1Z4	\N	0.00	Regular
e56830e6-0ec0-41f9-b519-7597f569cacc	c1	Aush Baikery	Sundry Debtors	\N	\N	0.00	\N
0a4663bc-7783-41e5-bd2e-c4c3b8635135	c1	Avanya Agency	Sundry Debtors	09AQIPM4952B1ZT	\N	0.00	Regular
fac14a73-7fad-44a6-8870-3561701f9a5a	c1	Av Catterers	Sundry Creditors	09AWYPP6443N1ZB	\N	0.00	Regular
9d048aae-fb16-4490-9d71-ba73a8794e17	c1	Avinash Pandit	Sundry Debtors	\N	\N	0.00	\N
523f3b83-3c9a-4ae3-86ef-949fe121ee75	c1	Aviraj Hospitality	Sundry Debtors	09ABBFA5957A1ZN	\N	0.00	Regular
aaa10ac4-e61a-4024-aaee-85fe48ad2e2a	c1	Avtar Singh Parvinder Singh	Sundry Debtors	\N	\N	-826.00	\N
2b73634b-330a-40f0-b029-58661ef9aff7	c1	Awtar Singh Paravin	Sundry Debtors	09BZJPS3019Q1ZK	\N	0.00	Regular
b9994b86-91fd-41db-8b1e-e11103725c3c	c1	AYP Retails LLP	Sundry Debtors	09ABVFA0944M1ZT	\N	0.00	Regular
043f9cf8-7a67-4bea-bbb9-156eefc35011	c1	AYUSH BAKERY	Sundry Debtors	\N	\N	0.00	Unregistered
218d0d82-f889-418b-99fb-32cb1a445cde	c1	Baba Bala Ji Medical	Sundry Debtors	09BFKPS7990M1Z8	\N	0.00	Regular
caaa57d7-153e-437a-86c1-ec51d23370c4	c1	Baba Foods	Sundry Debtors	09DLWPK1905A3Z1	\N	0.00	Regular
e7e40d3c-fa44-44e7-988c-98149d8192f0	c1	Baba General Store &amp; Statiosnar	Sundry Debtors	\N	\N	0.00	Unregistered
f1591da5-7f15-4514-9549-a5bff1dc9a29	c1	Baba Genral Stotre	Sundry Debtors	\N	\N	0.00	Unregistered
d71b2aea-05a2-4779-975c-5736b841e9af	c1	Baba Gift House	Sundry Debtors	09AEFPS9022K1Z1	\N	0.00	Regular
e36105c0-8a5e-4bd3-93ad-24de2759356b	c1	Baba  Watch	Sundry Debtors	\N	\N	0.00	Unregistered
66114ffb-8691-4eaf-8f60-a115634e6e6b	c1	BABU LAL GUPTA &amp; SON&apos;S	Sundry Debtors	\N	\N	0.00	Unregistered
cbd39a7b-8782-4151-8667-96edc0ba66e5	c1	Baijnath Legacy Private Limited	Sundry Debtors	09AAKCB8131A1ZX	\N	0.00	Regular
3b677bc7-7136-4532-ae04-38c0bc3be5c5	c1	Baithak	Sundry Debtors	\N	\N	0.00	Unregistered
71a86585-2c53-4d2b-b8ff-f3bca36d618d	c1	BAJAJ &amp; COMPANY	Sundry Debtors	09ACAPB8653Q1Z4	\N	0.00	Regular
adfe78b5-b51d-4610-afb4-c36c8861da27	c1	Bajaj Finance Limited	Secured Loans	\N	\N	0.00	\N
48718f59-a085-4c22-ba5f-cec3f844a440	c1	BAJAJ FINANCE LTD (Loan)	Sundry Creditors	\N	\N	68240.00	\N
0e2a73e3-e0c2-48a1-b02d-251c834a1597	c1	Bajaj G Departmental Store	Sundry Debtors	\N	\N	-600.00	\N
2b31e557-d248-4ef1-9f86-886557fe3fec	c1	Bajpai General Store	Sundry Debtors	\N	\N	0.00	Unregistered
a10e31ec-ef1e-4851-9775-1481195612c4	c1	Bala Ji Store	Sundry Debtors	\N	\N	0.00	Unregistered
46dd0666-776c-4bd8-adaf-f656c8f9299d	c1	Bal Suneet Rao	Sundry Creditors	\N	\N	0.00	Unregistered
8c3299f8-b170-4107-95a5-de7c4034a448	c1	Bank Charges	Indirect Expenses	\N	\N	0.00	\N
efad85e1-093c-4a17-9971-b12086945007	c1	Bank Service Charges	Indirect Expenses	\N	\N	0.00	\N
e9e53b57-e4f9-46b2-8484-d6a479e1f0c1	c1	Bansal Associates	Sundry Creditors	\N	\N	0.00	Unregistered
b0ad664f-4664-408c-82f9-d5b73952e7b4	c1	Bansal Associates 2019-2020	Sundry Creditors	09AAOPB3761B1ZY	\N	0.00	Regular
2f2f2ad4-e062-43da-8e4a-8cb8a3fe125f	c1	Bansi Baba Atul and Sons	Sundry Debtors	09ACIPD7140A1Z3	\N	0.00	Regular
694fa175-77a7-4be0-bd43-78c83d92d7a4	c1	Bansilala Rajan Palak and Sons(Regd.)	Sundry Debtors	09AHYPD2411P1ZU	\N	0.00	Regular
481e170b-a1b1-4110-b2f5-1e053cb80174	c1	Banwari Chaurasia	Sundry Debtors	\N	\N	0.00	Unregistered
017af6b2-3bb2-4e33-95ef-7982d8857137	c1	Banwari Lal Enterprises	Sundry Creditors	09AKMPR8830K1ZC	\N	0.00	Regular
32a054f4-a179-4c33-8703-d7d5fca6435c	c1	Barbeque Nation Hospitality Limited	Sundry Debtors	09AAKCS3053N1ZU	\N	17839.19	Regular
d947e5c0-bcb3-44b0-9243-c401ad371e19	c1	Barbeque Nation Hospitality Ltd.	Sundry Debtors	09AAKCS3053N1ZU	\N	-1893.22	Regular
32733389-73d1-4dfd-98b8-ef6f4af634d5	c1	BAREILLY AGARWAL FORWARDING AGENCY	Sundry Creditors	\N	\N	0.00	\N
a3d44290-cd8a-4702-987a-43b6dbb49d41	c1	BASU	Sundry Debtors	\N	\N	0.00	Unregistered
9805ce0c-f147-4e63-8e22-de6be66f0038	c1	Basudev Ganga Ram Provision &amp; General Store	Sundry Debtors	09AQTPG4733H1ZH	\N	0.00	Regular
5e7fefea-ab66-4b0d-9f0a-c99cac8a165b	c1	Basu Enterprises	Sundry Debtors	\N	\N	0.00	\N
10722770-a272-4829-bac9-942e8fb0b838	c1	BATRA &amp; COMPANY	Sundry Creditors	07AANFB9991J1ZN	\N	0.00	Regular
518a65a0-3fca-45db-8994-3f81d65f9c42	c1	BATRA ENTERPRISES	Sundry Debtors	07AAEPB5311M1ZZ	\N	0.00	Regular
eeb09b40-0fb3-4670-bcb8-3eb26ac094d8	c1	Battery	Fixed Assets	\N	\N	0.00	\N
e1f2364b-a4c0-49bf-b0e9-963b3ab20bdd	c1	BATTERY INVERTOR	Fixed Assets	\N	\N	-29744.26	\N
8a91eb83-4660-407c-b091-624f894c539e	c1	Bedi Plastic &amp; Gift House	Sundry Debtors	\N	\N	0.00	\N
29429845-495d-47d3-8992-1d085f13c7de	c1	Beenu General Store	Sundry Debtors	\N	\N	0.00	Unregistered
d285c6fc-bff7-4cf2-ad86-1a2ff364e4fa	c1	Beeru Dheeru Departmental	Sundry Debtors	09AKDPG0030D1ZZ	\N	0.00	Regular
85a3b326-e231-4e38-bcf6-cbb2058b7313	c1	Bellevue Hotel Company Pvt.Ltd.	Sundry Debtors	09AACCB6295R1ZT	\N	0.00	Regular
ddf6895f-e4b9-4ad6-a640-7c344a1c87dc	c1	BENT INC.	Sundry Creditors	09ALVPK1018Q1ZE	\N	0.00	Regular
2cd4057b-063b-4935-b8ec-bd0debefe608	c1	Bhagchand Bros.	Sundry Debtors	09ABFPC2156D1Z5	\N	-1236.00	Regular
79a78531-ef0b-43aa-a1f7-d3f309160bba	c1	BHAGYARAJ	Sundry Debtors	\N	\N	0.00	Unregistered
5a594763-1701-4060-9451-fff2e4250637	c1	Bhanu	Sundry Debtors	\N	\N	0.00	\N
9b1ee78b-0410-4934-a2db-99a7336fe2e1	c1	Bhanu Corporates Services	Sundry Debtors	06AGUPA0017H1ZS	\N	0.00	Regular
bb688cf6-30f3-4dac-aa49-1a45cabf4d71	c1	Bhanu Singh	Sundry Debtors	\N	\N	0.00	Unregistered
9541f7f6-2889-4d03-afc2-27239d6c4425	c1	Bharat Chaturwedi Easychoice	Sundry Debtors	\N	\N	0.00	Unregistered
ea352d34-fe25-48fe-9f4a-c36cf7df7850	c1	Bharat Electronics	Sundry Debtors	\N	\N	0.00	\N
460890b8-218b-4a84-bc48-72b2d01d77d6	c1	Bharat Time Center	Sundry Debtors	09ADVPG5289P1ZC	\N	0.00	Regular
bc9c6c15-c60c-4ad1-8824-9e2bff1b5825	c1	Bharat Watch Store	Sundry Debtors	\N	\N	0.00	Unregistered
60680795-9fb2-4a87-9989-0a0b3c0816e7	c1	Bharti Fancy Store	Sundry Debtors	09ACGPK0576K1ZB	\N	0.00	Regular
8b8d8eec-40eb-44d9-a5f9-74080ff92107	c1	Bhatia	Sundry Debtors	\N	\N	0.00	Unregistered
9a9f5a69-bc34-454e-ba15-21db962d83cc	c1	Bhatia Electricals	Sundry Debtors	09AAPPB8336F1ZK	\N	0.00	Regular
a564c7f4-dc72-447a-8f7f-cffa760334eb	c1	Bhatia Grah Udyog	Sundry Debtors	09AKUPB8341H1ZT	\N	0.00	Regular
48d6ff8e-c913-432c-9a74-eb8b5b25eca6	c1	Bhatia Hotel Pvt.Ltd.	Sundry Debtors	09AAACB5682L1ZA	\N	-19710.00	Regular
82d76056-4bca-4aec-983b-ba8f4e035ef8	c1	Bhavyatharv Consultancy Private Limited	Sundry Debtors	09AAICB6654N1Z0	\N	0.00	Regular
5b33378f-592f-4848-95ce-7d9c05a3aeaf	c1	Bhikharam Sweet House	Sundry Debtors	\N	\N	0.00	\N
fe16f1b6-f74c-437f-bcdb-f8b4493e003e	c1	Bhola  Store	Sundry Debtors	\N	\N	0.00	Unregistered
8cf3f836-3ca6-4232-98f2-4c324dfa4681	c1	Bholey Nath Ice Land Store	Sundry Debtors	\N	\N	0.00	Unregistered
889aefdb-19dd-4cca-95f3-0c74b198a47c	c1	Big Bazar Anchore Stores	Sundry Debtors	\N	\N	0.00	\N
27ff0196-03e4-4c9f-a7c8-19f0b45f8fcf	c1	Big Bird Ventures	Sundry Debtors	09AAZFB2439B1ZB	\N	0.00	Regular
b46c8a1a-531e-4e51-a90c-f3ad12b3dfb8	c1	Big Cinema	Sundry Debtors	\N	\N	0.00	Unregistered
b791314a-7ad2-48ad-95a2-691136b1153d	c1	BIHARI JI TRADERS	Sundry Debtors	\N	\N	0.00	\N
d50755ed-5605-4e3e-a6c5-9c8a589f35df	c1	Bikaner Cereals Industries	Sundry Creditors	\N	\N	0.00	Unregistered
758fa3a9-6de4-4071-8459-fd6dab374a87	c1	Birla Store	Sundry Debtors	\N	\N	0.00	Unregistered
2321850f-aba9-48cb-b1ab-041bfe6e39d7	c1	Blite Industries (OPC) Private Limited	Amazon Debtors	\N	\N	0.00	Unregistered
4de191b2-3432-40a1-9d80-a8021bbbd613	c1	Blossom Restaurants Private Limited	Sundry Debtors	\N	\N	-19559.00	\N
7fd1bf0a-f3c5-455e-9a98-b672b544af6c	c1	Blue Bird Foods (INDIA)PVT.LTD	Sundry Creditors	24AAACB0693F1Z2	\N	0.00	Regular
59fe09b3-3098-4367-ab12-e999f411a9a4	c1	Blue Star Deep Freezer	Fixed Assets	\N	\N	0.00	Unregistered
1d8e475d-d72b-4537-95ac-509eec5a00e3	c1	Blue World Corporation Private Limited	Sundry Debtors	09AACCB5377L1Z8	\N	0.00	Regular
fd36b8a8-ae39-4b40-b2f4-f8e6d0156ad7	c1	BLUE WORLD CORPORATION PVT.LTD.	Sundry Debtors	09AACCB5377L4Z5	\N	0.00	Regular
c08f12bc-c5c0-4f53-91ad-d7fed57fed45	c1	Blu Lagoon	Sundry Debtors	\N	\N	0.00	\N
20f58e06-27d0-4f21-9800-3c81ad9e5bcb	c1	Bobby Store	Sundry Debtors	\N	\N	0.00	Unregistered
1e7363d9-c1e3-492d-bbf6-ff13d9df04ef	c1	Bombay Baikery	Sundry Debtors	\N	\N	0.00	Unregistered
de4b22f0-e434-4836-a865-9836030dc08d	c1	Bombay Namkeen	Sundry Debtors	\N	\N	0.00	Unregistered
83bced31-08fa-468c-9317-e5f765fba734	c1	Bonus	Indirect Expenses	\N	\N	0.00	\N
c0c63913-3a78-403f-b32a-2ec6fcc0924a	c1	Bonus Payable	Provisions	\N	\N	45000.00	\N
78e0e121-d25c-40e3-bd66-97cccbc68701	c1	Bottico	Sundry Debtors	\N	\N	0.00	Unregistered
994e2d69-e96a-478a-84b0-a8fbceb4c613	c1	BRAND YUVA INTERNATIONAL	Sundry Creditors	\N	\N	615.00	\N
780b232d-03ef-4074-9f54-9a5e75f17d3b	c1	Brijesh Chandra Agencies	Sundry Debtors	\N	\N	0.00	Unregistered
1813e8b0-40c1-4b02-b4d8-7609ee566f54	c1	Brijesh Kumar Gangwar	Amazon Debtors	09ACAPG6142R1Z9	\N	0.00	Regular
cea068f7-a93e-4acc-9596-867f7db83b53	c1	B.S.Agencies	Sundry Creditors	09ALXPS0279B1ZM	\N	12594.00	Regular
0250ca6c-2dff-43e0-b732-87efb8ab5f94	c1	Budhsen	Sundry Debtors	\N	\N	0.00	Unregistered
cc8dd59c-f523-4529-90c5-dd94c898f41d	c1	Bulkify	Sundry Creditors	09FFWPS8515A1ZU	\N	0.00	Regular
7c66bdd0-9029-491e-896c-9ec989ec34e8	c1	Bundl Technologies Private Limited	Sundry Debtors	09AAFCB7707D1ZS	\N	0.00	Regular
97390462-254a-478b-b696-15651c13850b	c1	Bun Street	Sundry Debtors	09AANFT2062L1ZP	\N	0.00	Regular
e4f90ba6-a119-4ef4-a3bb-fa7030f761eb	c1	BURMAN HOSPITALITY COMPANY	Sundry Debtors	09BSTPB9995B1Z3	\N	0.00	Regular
6f0f8c95-74f8-4fc1-9bc4-aceabbbece76	c1	Business Promotion	Indirect Expenses	\N	\N	0.00	\N
724a354a-4cbb-45a2-b44e-0db5a4f8cea8	c1	Busy Beans	Sundry Debtors	\N	\N	0.00	Unregistered
e9f2a163-15fd-4dbb-b627-62acd96252cc	c1	BUSY BEANS MULTISOLUTIONS	Sundry Debtors	09ABBFB3512E1ZZ	\N	0.00	Regular
d8a350c3-250b-4780-a4d2-ef83eb8da399	c1	BUTTERCUP CONFECTIONERY LTD	Sundry Creditors	07AABCB8861E2ZO	\N	27082.13	Regular
c39f7fee-e107-4126-a271-1ad5ffab536f	c1	Buyers Choice	Sundry Creditors	09AKZPP9789J1ZJ	\N	0.00	Regular
4e7dfdc7-373e-4594-9b24-f7f2945be8b1	c1	BYRAMJEE FRAMJEE &amp;CO.	Sundry Creditors	09AGHPB0050C1Z7	\N	0.00	Regular
30a68918-c69d-4f2c-b6a1-50e22f214a1c	c1	CAFE BY THAGGU	Sundry Debtors	09AAICR3820N2ZX	\N	0.00	Regular
7286ad7b-7abb-47cc-80d5-1cbd6abbab8d	c1	Caffeko	Amazon Debtors	09BSMPJ8655H1Z3	\N	0.00	Regular
6373af0f-66e1-48f7-b048-feb92af94438	c1	Calcutta Paan Shop	Sundry Debtors	\N	\N	277.00	\N
5c9e62de-7924-4e3c-9f45-6a9be91b403d	c1	CALIFURNIA PIZZA CAFE	Sundry Debtors	09AANFC1255G1ZG	\N	0.00	Regular
cb330884-461f-4d00-a219-76cb16642f60	c1	Campus C Shop	Sundry Debtors	09AXIPS4213J1Z6	\N	0.00	Regular
41c97104-7566-4c56-9718-dd0b0a934103	c1	Campus D Shop	Sundry Debtors	09AAMFC9389C1ZY	\N	0.00	Regular
fcbb0d0e-d9cb-4ce9-abb5-208289b0af22	c1	Campus E Shop	Sundry Debtors	09AEOPS3298C1ZZ	\N	6246.50	Regular
eecc5301-658a-48d4-898e-15b64e83c3fb	c1	Canara Bank	Sundry Creditors	\N	\N	5227.03	\N
05d83760-b767-4804-bf4f-ac8144a34fde	c1	Canara Bank 5300	Bank Accounts	\N	\N	-126601.74	\N
d52302c8-afba-4b72-b41b-fbeb75749b1c	c1	CANARA Bank CC A/c No. 125005022399	Bank OD A/c	\N	\N	281209.05	\N
2635f1f5-8c98-49dd-a76a-0e3f9cb65221	c1	Canara Bank Ex-Up	Sundry Creditors	\N	\N	213.32	\N
96a34eec-fd50-4777-8f98-9609ad3d9b78	c1	Canara Bank OD A/c	Secured Loans	\N	\N	0.00	\N
964c21b4-1593-43ca-a2b5-6692575a1f18	c1	Car	Fixed Assets	\N	\N	-537425.00	\N
7aa7fe59-9ce3-460d-9495-db03bf284940	c1	Car Extra Warranty	Indirect Expenses	\N	\N	0.00	\N
0d831f59-eed6-4fb9-a4f9-d9e636f3b21a	c1	Car Rto	Indirect Expenses	\N	\N	0.00	\N
94a36984-d077-41b0-b039-991f1ea2e711	c1	Car Saz	Sundry Debtors	09AYPPS7223L1ZL	\N	0.00	Regular
3e5b5406-c775-4a48-bd83-b4a79aec3997	c1	Casa Bistro	Sundry Creditors	\N	\N	0.00	Unregistered
26be7ed4-2e21-47aa-910f-6976300f3f2e	c1	CASH	Cash-in-hand	\N	\N	-1240780.53	\N
2f8f7bfa-096f-4581-b8d3-85ec4b827624	c1	Cash Dicount	Indirect Incomes	\N	\N	0.00	\N
493c1535-8299-42a9-b6a8-8693ebc0a0ac	c1	Cash Discoumnt	Indirect Incomes	\N	\N	0.00	\N
27ae9cbc-4f36-43e3-b37a-96b54ee65964	c1	Cash Party on Bank	Sundry Debtors	\N	\N	0.00	Unregistered
aa839223-9a8b-427f-aa8a-2ed8e205c267	c1	CAST OF FORM 38	Indirect Expenses	\N	\N	0.00	\N
1634bfa0-5f7c-4cc1-a158-55a322e7e57a	c1	CEEKAY INTERNATIONAL (Delhi)	Sundry Creditors	07AAGFC0128B1Z7	\N	0.00	Regular
c638e405-f348-4263-9be5-bf31e0715458	c1	CEEKAY INTERNATIONAL (Haryana)	Sundry Creditors	06AAGFC0128B1Z9	\N	0.00	Regular
68d9e4a5-4d34-4ad5-9360-1127da17dc04	c1	Celebrations	Sundry Debtors	09BNRPS1032B1Z2	\N	0.00	Regular
32f36944-e3e4-4dc0-a2e6-ac0587e02aaa	c1	Celebrations Kids &amp; Queens	Sundry Debtors	09BNRPS1032B2Z1	\N	0.00	Regular
8d5b1188-1a20-4efd-80a4-0365361c2575	c1	Central Tax 2%	Duties & Taxes	\N	\N	0.00	\N
24abec30-1827-4085-88d6-cccd9949c1db	c1	Cess Payable	Duties & Taxes	\N	\N	0.00	\N
698c239f-0cfc-4e7b-940c-3528e33d84c1	c1	Cgst Cash Ledger	Loans & Advances (Asset)	\N	\N	0.00	Unregistered
65312b97-c6d3-454c-aa6a-c1c52bbca316	c1	Cgsts Payable	Duties & Taxes	\N	\N	0.00	\N
1b05699d-afd5-4ffd-bd84-afd7fb0b4fea	c1	Chahat Store	Sundry Debtors	\N	\N	0.00	Unregistered
6fdc5d87-51c7-4856-8de9-720d1812e762	c1	Challan	Suspense A/c	\N	\N	0.00	\N
161df7e3-2886-4666-b1c7-8c15e55eeb25	c1	Chandani Store	Sundry Debtors	\N	\N	0.00	Unregistered
9dfff1d0-f5b2-4252-ba83-0d2905c1b7f0	c1	Chanda Store	Sundry Debtors	\N	\N	0.00	Unregistered
8bcb603e-d5a8-43f6-95ab-6d922e14c4be	c1	Chandel Watch House	Sundry Debtors	09AEXPC3692P1ZH	\N	0.00	Regular
82e28c3a-034e-4196-b82f-fd4ccaf3da01	c1	CHARU GARMENTS	Sundry Debtors	09ABXPS7391C1ZU	\N	0.00	Regular
02a99a38-0de2-48f3-b500-0fe99ba4c07b	c1	Chaurasia Pan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
007f90da-2406-43cf-b452-fcb6114583f3	c1	chaurasiya paan	Sundry Debtors	\N	\N	0.00	\N
6c2fc9c3-6e4c-4416-a368-5e1e86b35824	c1	Chawala Son&apos;s	Sundry Debtors	\N	\N	0.00	Unregistered
fde2a399-2c40-4d28-9fcb-d3e7dfc93149	c1	Chawla Brother&apos;s	Sundry Debtors	09AAKPC2696L1Z8	\N	0.00	Regular
26d0e64f-056e-4f1a-9b29-ce5545edf2cb	c1	Chawla Chabra	Sundry Debtors	09AHFPS5563E1Z2	\N	0.00	Regular
4b85c36b-c322-4fa8-9da9-47a60ac69e10	c1	Chawla &amp; Chhabra Brothers	Sundry Debtors	\N	\N	0.00	Unregistered
d9532d30-9e17-4758-b980-54eee574f910	c1	Chawla Store	Sundry Debtors	\N	\N	0.00	Unregistered
6280aac4-1d8a-4321-82c7-b27912823552	c1	CHENAB IMPEX	Sundry Creditors	\N	\N	0.00	Regular
ef4b8e1a-d0d5-4f6f-9e64-8f0ded92eace	c1	Chennai Express	Sundry Debtors	\N	\N	0.00	Unregistered
32ce8019-7f4f-4f62-a551-4d3ed9fb7fad	c1	Chesa Dental Care Services Ltd.	Amazon Debtors	29AABCC6137G1ZP	\N	0.00	Regular
b05d9233-ed9a-44da-af62-a7ed5f428292	c1	CHESTNUTS (Varanasi)	Sundry Debtors	\N	\N	-24458.00	\N
fb949431-55cc-4198-90a7-2d501e0fdc21	c1	Chetan  Exports	Amazon Debtors	27AAAFC3633M1ZG	\N	0.00	Regular
2c02e196-9427-4c84-9497-b9829598f3c8	c1	Chetan Sales Corporation	Sundry Debtors	\N	\N	0.00	Unregistered
f5bb6d99-8d71-4ed9-9743-89267051a04d	c1	CHHAPPAN BHOG	Sundry Debtors	\N	\N	0.00	\N
91d7ce0a-dfea-4b64-a7c5-e7378729c174	c1	Chilliz	Sundry Debtors	\N	\N	0.00	Unregistered
4e539254-ba74-415c-88bb-7bdb55eff4bb	c1	Chilly Point	Sundry Debtors	\N	\N	0.00	Unregistered
c316c232-00a4-44c6-8ba5-ab1ae46677fa	c1	Chilly Restaurant	Sundry Debtors	\N	\N	0.00	Unregistered
2cb8b444-3b0c-4c34-b196-91f9a6ee520e	c1	Chintani Tea Stall	Sundry Debtors	\N	\N	0.00	\N
2b680b0c-ca40-4456-850f-4e7d6d41ebd8	c1	Chirag Associates	Amazon Debtors	24AWSPG3277H1Z9	\N	0.00	Regular
4d53e51d-42df-49ab-bcda-4b51e9fa4527	c1	Chitra Grih Udyog	Sundry Debtors	09BFSPD4606M1Z0	\N	0.00	Regular
28c670e9-75dc-4453-9ba8-f6769af89827	c1	Chocolate Library	Sundry Creditors	27ALDPU3209R1ZH	\N	23482.00	Regular
8c50fbdc-7b7c-4760-a2c1-072c57c099ca	c1	Chopsticks Momos	Sundry Debtors	09AAOFC8014E1ZG	\N	0.00	Regular
e0a3c0ab-7cff-470b-85b2-794061a70e94	c1	Chote Masale	Sundry Debtors	\N	\N	0.00	Unregistered
d26261cc-6525-4265-b6bf-f36eafb24e68	c1	Chrysalis Restaurants Private Limited	Amazon Debtors	29AAICC6013A1Z3	\N	0.00	Regular
45f78e44-cf42-4b10-afc0-3683007ca4d3	c1	Cine Max South x Mall	Sundry Debtors	\N	\N	0.00	Unregistered
35fe57f8-514e-48a7-8400-351bc3f8de4b	c1	Classic Corrugations P Ltd	Amazon Debtors	24AAECC4060H1Z0	\N	0.00	Regular
6b855961-c68c-43d3-b5f9-d9b72a303808	c1	Classic Time	Sundry Debtors	\N	\N	0.00	Unregistered
8327d3c8-ee1f-4b5d-8b3b-82529196405b	c1	Cliam &amp; Incintive	Indirect Incomes	\N	\N	0.00	\N
f13f864a-6552-4b94-ae51-1855e9afe524	c1	Closing Stock	Stock-in-Hand	\N	\N	-3815500.00	\N
710e004d-bb98-453a-8fd6-1eaa5e2039b5	c1	Cocoamelts Chocolates India Pvt. Ltd.	Sundry Creditors	\N	\N	-382.00	\N
407eedcf-ce9d-43ce-bfef-4996027e8403	c1	Commission	Indirect Expenses	\N	\N	0.00	\N
b0e4db46-7998-418a-948f-a7220599b317	c1	Commission Rect	Indirect Incomes	\N	\N	0.00	\N
fe93fe45-6faa-426b-9f38-81c67c112789	c1	Computer	Fixed Assets	\N	\N	-13236.66	\N
e3c89259-4daf-4bac-8d9f-1ec2e208fb79	c1	Computer Expenses	Indirect Expenses	\N	\N	0.00	\N
e6ffec0b-7214-472f-8342-ff000a1a69e1	c1	Computer IT Solutions	Amazon Debtors	07ADXPG9451D2Z6	\N	0.00	Regular
3cd6dc29-d08e-48d0-8fbc-d5c6c50eefeb	c1	Confession	Sundry Debtors	09ACSPB7605A1ZT	\N	-2994.00	Regular
f5e3402c-169a-403d-a542-30fd03d8fb2f	c1	Convence Expences	Indirect Expenses	\N	\N	0.00	\N
cb629416-1c33-47cf-baf4-3cf0b4ac8452	c1	Conveyance Exp.	Indirect Expenses	\N	\N	0.00	\N
9cbc110e-cf29-4dce-802c-73686101f4ca	c1	Cool Kat Ice Cream	Sundry Debtors	\N	\N	0.00	Unregistered
4a3d0a2c-153c-4fbd-b436-3ce125790ab1	c1	Corner Medical Store	Sundry Debtors	\N	\N	0.00	Unregistered
341be076-eace-4cf5-9846-72f08424f985	c1	Cothas Coffee Co.	Sundry Debtors	\N	\N	0.00	Unregistered
511c0e0e-1d02-4b13-97fc-505a1368df54	c1	Country Side	Sundry Debtors	\N	\N	0.00	Unregistered
4689f468-054f-499e-9d14-7322d18d974a	c1	Cownpore Club Ltd	Sundry Debtors	09AAACC5804H1ZU	\N	11461.00	Regular
7c57ebed-59ef-443c-b072-2b98068e1497	c1	Cravova Food &amp; Beverages India Pvt. Ltd	Sundry Creditors	27AAICC3909K1ZF	\N	0.00	Regular
339a5655-56e3-4e6a-bc51-8509f239efc3	c1	Credence Corporation	Amazon Debtors	27BEMPS6713R1ZH	\N	0.00	Regular
b3e8cf5b-b227-40f2-ad1d-c8ecb81f462e	c1	Critics Poetry Cafe (OPC) Private Limited	Amazon Debtors	33AAHCC9604Q1Z7	\N	0.00	Regular
c69ae3ba-b5d7-4909-a621-3a50013b6555	c1	Crystal Craft	Amazon Debtors	07ACEPM8129Q1ZY	\N	0.00	Regular
3d1b3209-3cd5-4911-8f67-7a9fbf06eb89	c1	CUP N CONE	Sundry Debtors	\N	\N	0.00	Unregistered
0852300f-493b-4ef2-b9a5-0d70ecc841ad	c1	Cwanpor Store	Sundry Debtors	\N	\N	0.00	Unregistered
e2c009c8-ebe9-438a-8b01-5e097994d584	c1	Daibetic Healthcare Shop	Sundry Debtors	\N	\N	0.00	Unregistered
b6c92a69-94de-4039-98e4-d65fad45e9c1	c1	Daily Needs Products	Amazon Debtors	33BYFPB5478K1Z9	\N	0.00	Regular
edd486a6-0a02-417e-b7e9-eb1da8d246a3	c1	Dalmia Groups	Sundry Debtors	\N	\N	0.00	Unregistered
8ece9675-750b-4a1a-8970-3eb5328b1e03	c1	Damage ,Discount. Sample &amp;DISPLAY	Indirect Incomes	\N	\N	0.00	\N
6b39ea65-d27d-41af-9ee1-0a2ce4e9121c	c1	DAMAGE EXPIRY	Indirect Incomes	\N	\N	0.00	\N
0f0108db-3828-4d62-b0d4-51dc01772555	c1	Damini Store	Sundry Debtors	\N	\N	0.00	Unregistered
38e18f10-1f51-494f-86c2-92683262a75a	c1	D Apurva Agencies	Sundry Debtors	09AGFPP5149N1ZQ	\N	0.00	Regular
e8bb3b9f-2605-4c39-805b-351d9f927360	c1	Darshan Provision Store	Sundry Debtors	09AAEFD7696K1ZQ	\N	0.00	Regular
2216e767-966a-44d4-a9d7-08ef822918fc	c1	Dasa Ram Chaurasia	Sundry Debtors	\N	\N	0.00	Unregistered
04ce53ec-08c8-4ffa-98f6-c75faddb2389	c1	Dashmesh Dairy Products	Sundry Debtors	09AFTPS8657R1ZS	\N	-7072.00	Regular
f9f27901-92e6-4af8-b8b7-f7cd75fbefce	c1	Dashmesh Foods Pharma Privet Limited	Sundry Debtors	09AAFCD7009L1ZE	\N	0.00	Regular
e866f498-528e-456e-88e2-772b7dd39b17	c1	Dashmesh Products	Sundry Debtors	09AAAHT2733F1Z9	\N	0.00	Regular
5e05cfcf-a6b4-430f-b6cc-c9b06ee11d02	c1	Das Technologies	Amazon Debtors	03BECPS9746C1ZH	\N	0.00	Regular
4df05481-0488-41ba-9e2f-e2c0bb81ce39	c1	Day	Sundry Debtors	\N	\N	0.00	Unregistered
04fd01bc-234d-4869-ac1e-86e006b6c54d	c1	Day 2 Day Convenience Store	Sundry Debtors	\N	\N	0.00	Unregistered
8a4e7c4c-274c-4320-a9a6-63be7736d101	c1	DC &amp; Sons Motels And Restaurants LLP	Sundry Debtors	09AAMFD4562G1Z8	\N	0.00	Regular
e769008d-b916-4913-85eb-c63edcb717ae	c1	D D Distributors	Sundry Debtors	\N	\N	0.00	Unregistered
412e1e21-d4a8-470f-8547-fb15358354eb	c1	Deep Agencies	Sundry Creditors	09AMQPK6507J1ZJ	\N	0.00	Regular
7e9e20c3-c19e-4361-af15-593a520fee3b	c1	Deepak	Sundry Debtors	\N	\N	0.00	Unregistered
db019275-f977-4b54-a696-9d5bf523bc74	c1	Deepak &amp; Co.	Sundry Debtors	09AADFD8487H1ZZ	\N	0.00	Regular
7672ab26-6433-4546-a974-6095328ff8c6	c1	Deepak Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
5e1faff6-da34-4fc5-9a02-79713c4dd079	c1	DEEPAK GENERAL STORE	Sundry Debtors	\N	\N	0.00	Unregistered
8a9cdec7-0e37-4440-a3d2-9075006490b1	c1	Deepak Mehrotra	Unsecured Loans	\N	\N	53195.00	\N
e796ac41-6a01-4e6e-99a6-efecac4b3b01	c1	Deepak Store	Sundry Debtors	\N	\N	0.00	Unregistered
957bd0b5-3cca-49c4-87b4-35436f8489c6	c1	Deep Sales	Sundry Debtors	\N	\N	0.00	Unregistered
d1815a67-0cb1-420b-bcfe-6543668b32b9	c1	Delhi Cosmetics	Sundry Debtors	09ADWPF1540P1ZY	\N	0.00	Regular
89616f18-2958-4078-bb2c-4cc3f673876a	c1	Delhi Departmental Store	Sundry Debtors	\N	\N	0.00	Unregistered
3f9ff057-aff0-4b20-8a98-31b7b6548caf	c1	Delivery Charges	Direct Expenses	\N	\N	0.00	\N
09ba2ab1-69d5-4c07-8330-9e05aa30bfd7	c1	Delivery Expence	Indirect Expenses	\N	\N	0.00	\N
44549b63-d92d-44c2-bad3-2eab9a41ae09	c1	Dellivery Charges 14%	Indirect Expenses	\N	\N	0.00	\N
4b3440a2-38fe-4d65-92f9-14a02c7818d8	c1	Depriciation	Indirect Expenses	\N	\N	0.00	\N
310ad654-642b-43ae-bab1-1767e56b8949	c1	Desi Pallate	Sundry Debtors	\N	\N	0.00	Unregistered
2393e858-3705-4fa2-be6a-0b8ef46a47f6	c1	DESSERT HEART VENTURE	Sundry Debtors	09ADJPO1685R1ZK	\N	0.00	Regular
537e388f-bbe9-47d7-b482-253dde82fa9c	c1	Devak Foods Pvt. Ltd.	Sundry Creditors	\N	\N	-32525.00	\N
d07c39dc-918c-45fa-b6f2-8765c4dc5132	c1	Dev Enterprises	Sundry Creditors	09CUGPG8814E1ZK	\N	0.00	Regular
a99ba247-ad53-4fe6-86e7-ac552300001d	c1	Devgiri Exports	Amazon Debtors	06AABFD1226E1Z6	\N	0.00	Regular
a6a0f04d-99e6-482a-872f-93040d35de9a	c1	Devlopment Coprative Bank	Bank Accounts	\N	\N	0.00	\N
3b902d59-e54e-44fb-9fd5-bba932610a49	c1	Dhawal Trading Company	Sundry Debtors	09AGJPC3841Q1ZY	\N	0.00	Regular
f9d88bd9-df24-4545-9c1c-8350aa047c7c	c1	Dheeraj General Store	Sundry Debtors	\N	\N	-270.00	Unregistered
73b7747f-aee1-4632-8a75-471ba43c9d5e	c1	Dheeraj General Store-2	Sundry Debtors	\N	\N	-204.00	\N
aed7546d-31d6-4acd-bcfd-1142bf2d7272	c1	Dheeraj Neeraj Jewellers	Sundry Debtors	09ABUPV8762H1ZJ	\N	0.00	Regular
be002f8a-7b66-40e3-bdde-d40c1f8aca0f	c1	Dhruv Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
2aaf9209-3b9f-47c8-870c-567f22eefe20	c1	DIABETIC &amp; HEALTHCARE SHOP	Sundry Debtors	09ASFPS1242M1ZE	\N	0.00	Regular
ca89c27e-ba4f-46fd-8dda-6c3a85572251	c1	Diat Foods India	Sundry Creditors	27AABPA5111B1ZQ	\N	205513.00	Regular
2d58f6dc-6336-4ffb-b113-314c3aef651f	c1	Digipanda Consulting Private Limited.	Amazon Debtors	09AAFCD9821N1Z2	\N	0.00	Regular
6c212768-08be-4b1e-bca0-a74192bd9416	c1	Digital Signature Exp.	Indirect Expenses	\N	\N	0.00	\N
d8a213dc-441a-49d1-84ed-bdbe50201df7	c1	Dilip General Store	Sundry Debtors	09ARRPK6564H1Z4	\N	-6369.00	Regular
94d0f846-3b94-41b1-b38b-4729287ab356	c1	Dilip  Store	Sundry Debtors	\N	\N	0.00	Unregistered
538cdf75-eca3-45fd-8d7a-bbdd32db7b19	c1	Dina Nath Store	Sundry Debtors	\N	\N	0.00	Unregistered
ffe896f2-9336-4e39-aaa2-994ff98fa684	c1	Dinesh Kumar Gupta Store	Sundry Debtors	\N	\N	0.00	Unregistered
0c893a0d-c7b3-44dc-a536-53b2cafe701d	c1	Discount	Indirect Incomes	\N	\N	0.00	\N
b929c52d-5bf1-4c92-8b7a-7042317c14bb	c1	Discount 1%	Indirect Incomes	\N	\N	0.00	\N
88c828fe-fe85-4d8f-9e91-d77d1569ec77	c1	Discount(12%)	Indirect Incomes	\N	\N	0.00	\N
815e0c2f-c7b7-40d0-80c1-4ad8d1c50994	c1	Discount(18%)	Indirect Incomes	\N	\N	0.00	\N
df5ed933-a2cf-4ed9-bf2f-2b5da765c144	c1	DISCOUNT 2%	Indirect Incomes	\N	\N	0.00	\N
da7c9c66-6036-4a63-8770-2e2bccada50a	c1	Discount(5%	Indirect Incomes	\N	\N	0.00	\N
8e6235f2-a37e-4679-934b-55520bd70313	c1	Discount of Whole Wheat Atta 5 Kg	Direct Expenses	\N	\N	0.00	\N
7e197b48-989d-44bd-aca1-c4e52434b1f7	c1	DISCOUNT REC	Indirect Incomes	\N	\N	0.00	\N
2d7c1ae4-a176-47a2-a0fa-34326927ea37	c1	Disha Enterprises	Sundry Creditors	09BFIPP8090M1ZK	\N	0.00	Regular
3970ef27-6516-4624-8303-bfe4e4cc5d9a	c1	Display	Indirect Expenses	\N	\N	0.00	\N
51b7589f-9dd9-4dfe-9be6-defab7ba8193	c1	Divyam Naturals	Sundry Debtors	09AWBPA2358L1ZJ	\N	0.00	Regular
c792b59e-7b05-40a9-b410-e3fe1c7690a2	c1	Divyam Store	Sundry Debtors	\N	\N	0.00	Unregistered
f8dc802b-f9a2-46c6-9c94-9e2e0779df6a	c1	Diya Store	Sundry Debtors	\N	\N	0.00	Unregistered
037f85ab-ba3a-4f9a-b8a5-cda1cecbb6ca	c1	D K Traders	Sundry Debtors	\N	\N	0.00	Unregistered
efb1c45e-6c3a-42d8-89f2-3fb105de3a4a	c1	D N Brothers	Sundry Debtors	\N	\N	0.00	Unregistered
8101dd1d-f0b8-4bd0-bd88-385da0c92b32	c1	Doctor&apos;s Store	Sundry Debtors	\N	\N	0.00	\N
ec4e56ca-4db7-4cbb-9fa5-c0ae031dd913	c1	Document Point	Sundry Debtors	\N	\N	0.00	Unregistered
5ce94329-c8f9-4656-81c9-f943b39819e4	c1	Doehler India Pvt Ltd	Amazon Debtors	27AAACD2157N1ZI	\N	0.00	Regular
ff879ce4-168d-4a9c-8a86-2a178b9002f6	c1	Dohar Electronics	Sundry Debtors	\N	\N	0.00	Unregistered
d5686c95-f3fe-4ca9-8013-8c4ca71d6785	c1	Domanian Trading	Sundry Debtors	09AXUPH2510F1ZI	\N	-23753.00	Regular
b51d8b32-8825-4b3b-9786-d08b9da5361e	c1	D Purchoonz	Sundry Debtors	09AALFD5669H1ZX	\N	0.00	Regular
ee6ef24a-25a0-4e70-b85f-ba63170fb45d	c1	Drama	Sundry Debtors	\N	\N	0.00	Unregistered
485e0012-1d88-44dc-8011-7af860378e6f	c1	Dress Code	Sundry Debtors	\N	\N	0.00	Unregistered
78747505-e379-4f87-9bfe-3117995dd831	c1	Dr. Kumkum	Sundry Debtors	\N	\N	0.00	Unregistered
3b18986d-2a49-41cb-8be6-b75d38eb9d6d	c1	DR.OETKAR INDIA PVT LTD	Sundry Creditors	09AACCD7173L1Z8	\N	0.00	Regular
86825927-186d-4c97-976e-8ab2289d77b2	c1	D R S Enterprises	Sundry Debtors	\N	\N	0.00	\N
dbd08d87-17fc-47c0-85bc-55f9ffbad484	c1	DURA  CLAIM	Indirect Incomes	\N	\N	0.00	\N
317c17d3-51fb-46a4-95be-48000b40510f	c1	DURGA DISTRIBUTORS	Sundry Creditors	09AIKPG2216N1Z3	\N	0.00	Regular
d7f37677-daf2-4464-96df-3969f13627e7	c1	Durga Fruit Co.	Sundry Debtors	09ADTPK4860E1Z6	\N	0.00	Regular
0a9c3f01-ab46-43d5-bfa0-7d1b5e27a4ba	c1	Durga Fruits	Sundry Debtors	\N	\N	0.00	Unregistered
0f099e8d-c43a-452d-917d-d098f58db5f0	c1	DURGA SHANKAR AND COMPANY	Sundry Debtors	09AAHFD0926F1ZN	\N	0.00	Regular
b66f99d8-6c7c-4688-94c2-52ae1f3ba06a	c1	Durga Shankar And Kanth.	Sundry Debtors	\N	\N	0.00	Unregistered
14537314-32f3-4cdf-bafd-45dd7ee35500	c1	Durgesh Watch	Sundry Debtors	\N	\N	0.00	Unregistered
d4da3010-87ea-4e38-bd4a-82c5db250db0	c1	Durion Furniture	Sundry Debtors	\N	\N	0.00	Unregistered
3b70ea0f-b0fc-4475-910a-2131fe19e4f0	c1	Earth Innovative Construction	Amazon Debtors	29ADVPR7815A1Z2	\N	0.00	Regular
11f7ffef-1cbe-45d7-83ed-f713cdbd520c	c1	EASYCHOICE SUPERMARKET LLP	Sundry Debtors	09AAAAE7016M2ZK	\N	0.00	Regular
c9c6e610-99a3-4081-a30a-fd13d50bae87	c1	Easyship Weight Handling Fee Amazon	Indirect Expenses	\N	\N	0.00	\N
f7502d6f-2692-403c-a738-1e40100fff8c	c1	Ecavo Agro Daily Private Limited	Amazon Debtors	09AAFCE0398D1ZO	\N	0.00	Regular
472d39aa-cc2c-4652-ac12-a1977413e882	c1	ECO Fresh	Sundry Creditors	09DAWPS4105R1ZL	\N	0.00	Regular
b03af13d-4b12-488f-8359-8cc8b03f0356	c1	Ekta Medical Store	Sundry Creditors	09APAPA2574G1Z7	\N	0.00	Regular
e3e97ff0-8cf3-4e2b-b583-bb8e0e2781ba	c1	ELANORE HOSPITALITY PVT LTD	Sundry Debtors	09AAHCE2784K1Z5	\N	0.00	Regular
a65c59bd-c64e-4c8d-a4cd-d9b9ec70fc9c	c1	Electricity Exp.	Indirect Expenses	\N	\N	0.00	\N
69cb859f-4769-4761-98d4-57aac671cc0a	c1	Electricity Payable	Provisions	\N	\N	0.00	\N
5cf0950d-7025-4846-ba5b-a9a3263f7205	c1	ENILUAP	Sundry Creditors	\N	\N	8315.00	\N
0e2f28c4-ba25-457f-9070-7297443efbe8	c1	ENSCULP (Praveen)	Amazon Debtors	29AAIFE5211F1ZN	\N	0.00	Regular
f50afe4d-7cc0-4805-9810-b8b66d73b9bf	c1	Entire Foods	Sundry Creditors	\N	\N	-38448.00	\N
d4bb4593-7931-4f2d-b10b-d3defcf71322	c1	E &amp; T BAKERY	Sundry Creditors	09BAQPG8516G1ZD	\N	0.00	Regular
52691361-fb99-4a0a-a298-a963557f8609	c1	European Foods India Pvt. Ltd.	Sundry Creditors	07AAECE1033E1Z9	\N	0.00	Regular
9a6e5f8a-956d-4564-9bf8-34ad66ca1df0	c1	Excel Enterprices	Amazon Debtors	27ADBPJ7912N1Z9	\N	0.00	Regular
dd02f7b6-83d5-431b-b5f2-6436edd305c7	c1	Excitel Broadband Private Limited	Sundry Creditors	09AADCE9043K1ZB	\N	-0.16	Regular
b69a6fc7-e968-44d7-a127-3553a6659a7e	c1	Exitel Fiber Broad Band	Creditors Others	09AADCE9043K1ZB&#13;&#10;	\N	0.00	Regular
45106a1e-c27e-46e6-b61f-1ac7f05bde44	c1	F5 Universe (Opc) Private Limited	Amazon Debtors	03AAECF2969C1ZX	\N	0.00	Regular
f69b9302-aaa3-406a-aa11-b37e91dc2090	c1	FAB FOOD	Sundry Creditors	07ABFPS9953G1Z4	\N	0.00	Regular
491b99ba-1f2e-446c-a383-6d05d7fc4772	c1	Facebook Expencess Online Service	Indirect Expenses	\N	\N	0.00	\N
583caefb-8551-46d6-b600-d21f0a08540e	c1	FACEBOOK INDIA ONLINE SERVICES PRIVATE LIMITED	Sundry Creditors	\N	\N	0.00	\N
88dfddb0-f170-4c88-a247-052090994c28	c1	Fair Deal Cornour	Sundry Debtors	\N	\N	0.00	\N
8f6acb05-0094-4a44-b81d-d18e37aeb32b	c1	FARIDI IMPEX PVT LTD	Sundry Creditors	27AABCF3589P1ZX	\N	0.00	Regular
c984e068-a028-4c69-84dd-68885e558ebe	c1	Farm Delight	Sundry Creditors	\N	\N	33233.00	\N
03562e97-cdd0-4a8b-b457-512203f4f07b	c1	Farmlander Enterprises	Sundry Creditors	07BITPJ0029C1ZI	\N	22184.00	Regular
6608d241-bd2f-4f9a-ace4-a70007102869	c1	FASHION	Sundry Debtors	\N	\N	0.00	Unregistered
cc64ea1f-a3a9-40a1-9e4b-e096d7871267	c1	Fasion Assassries	Sundry Debtors	09AGOPA2695M1ZT	\N	0.00	Regular
93be896d-60f8-488c-bdb4-e5c4bae23785	c1	Fast Tag &amp; Auto Card	Indirect Expenses	\N	\N	0.00	\N
ed4dfa1a-36e9-42e9-8e39-b0969f0e7842	c1	Fazil Hussain	Sundry Debtors	\N	\N	0.00	Unregistered
44479a3d-05af-4b19-bf45-936e86556347	c1	F.C.Sondhi &amp; Co. (India) Pvt Ltd.	Amazon Debtors	03AAACF2771Q1ZG	\N	0.00	Regular
1b1be56a-367f-4b23-a72c-782fe94cce18	c1	Festival Exp	Indirect Expenses	\N	\N	0.00	\N
62f8f8c2-59aa-4cda-b951-f208a6b5cd7d	c1	Filpkart Uttar Pradesh	Flipkart Debtors	\N	\N	0.00	Unregistered
8a01a3e3-7b3c-4b68-af14-0978eb8189fd	c1	Fine Enterprises	Sundry Debtors	\N	\N	0.00	\N
244b9972-2895-43bd-8e9d-846caf997935	c1	FIROZ PAN SHOP	Sundry Debtors	\N	\N	0.00	Unregistered
d3670a05-cefc-42a1-bce0-57b09db773e5	c1	FITNESS GYM	Sundry Debtors	\N	\N	0.00	Unregistered
9cf378f4-32b4-409d-b302-06afbc187020	c1	Fixed Closing Fees Amazon	Indirect Expenses	\N	\N	0.00	\N
b616f593-8f9f-49dd-ac1a-fd9e906bde9c	c1	Flavour And Fresh Foods	Sundry Debtors	09AAHFF9109Q1ZP	\N	0.00	Regular
4ed56f3d-204b-4774-acd8-ca15c5aeb4c3	c1	Flipkart Haryana	Flipkart Debtors	\N	\N	0.00	Unregistered
dc0e10c1-73b5-48fa-b5cb-53d011d0fff1	c1	Flipkart Maharashtra	Flipkart Debtors	\N	\N	0.00	Unregistered
e3756818-aba2-4591-ab64-c0ca453c4c83	c1	Flipkart Pvt. Ltd.	Flipkart Debtors	\N	\N	0.00	Unregistered
d984f784-4fc8-4784-8f46-11a6cb3c9673	c1	Flipkart Rajasthan	Flipkart Debtors	\N	\N	0.00	Unregistered
0ab4c730-f4db-4830-9dbf-ee85632b6e90	c1	Flipkart Tamilnadu	Flipkart Debtors	\N	\N	0.00	Unregistered
48f65c13-da72-4e60-833d-dc56f4f28e8a	c1	Flipkart Uttar Pradesh	Flipkart Debtors	\N	\N	0.00	Unregistered
e5ece9f2-84f2-4f99-87c9-5f7a0ac54108	c1	Flying Man Air Courier	Sundry Creditors	\N	\N	0.00	\N
4db8a566-754d-4f51-ab34-95fc40503059	c1	Focus Sourcing India	Amazon Debtors	07ABSPC9100C1Z0	\N	0.00	Regular
99330b0a-56cc-4856-8929-884282cd8ca5	c1	Food Monde	Sundry Creditors	07CTXPP2715D1ZE	\N	0.00	Regular
1d3a891d-5361-4d42-8877-83ee8049bc42	c1	FOODOZ PIZZA	Sundry Debtors	\N	\N	0.00	Unregistered
52ee73d5-04ca-415d-bbab-c78ddeb00bfd	c1	Food Safety Services	Direct Expenses	\N	\N	0.00	\N
20237243-a8bb-45a9-b5b0-82148b79fc1a	c1	Foto Spot	Sundry Debtors	09AAOPR4956N1ZM	\N	0.00	Regular
b83d7a7b-386c-4c7f-ac22-c515d99beffc	c1	Fragrance Solutions	Sundry Creditors	09AAEFF9746N1ZN	\N	0.00	Regular
402d9f36-bb7b-4e29-a584-4a735e549bc9	c1	Fraterniti Hospitality Solution	Amazon Debtors	\N	\N	0.00	Unregistered
9cef6df9-7534-41d5-8fa1-29035e957304	c1	Freezer	Fixed Assets	\N	\N	-10230.00	Unregistered
ee86cab8-29ba-483b-bd27-4088698b5e62	c1	Freight &amp; Cartage	Direct Expenses	\N	\N	0.00	\N
208d7d48-1cbf-40c0-bb5b-64d99f625424	c1	Freight &amp; Cartage 5%	Direct Expenses	\N	\N	0.00	\N
e8b836ad-430c-4bb1-a0ef-3b6106e9a302	c1	FREIGHT &amp; CARTAGE NON TAXABLE	Direct Expenses	\N	\N	0.00	\N
7080e4d8-3b7d-4469-b02a-24225bb0320e	c1	Freight Outward RCM	Indirect Expenses	\N	\N	0.00	\N
fc729efd-1c14-4b9f-a68a-4acf08f0eae8	c1	Freight &amp; Outword	Indirect Expenses	\N	\N	0.00	\N
5b024597-a17b-4950-bb1f-2860f321b3bc	c1	Freight  Out Word @12%	Indirect Expenses	\N	\N	0.00	\N
d2c6860c-5b5c-40ef-b5d8-327d5494d6f0	c1	Friday Foods	Sundry Debtors	09AAFFF3642L1Z7	\N	0.00	Regular
d1bce670-3d3f-434b-9d40-2454fb037741	c1	FRIEND GENERAL STORE	Sundry Debtors	\N	\N	0.00	Unregistered
b187cfcd-4438-4a1c-8eff-eca48c9b22d2	c1	Friends Bakery	Sundry Debtors	\N	\N	0.00	\N
97b5b6f9-e8d8-47d0-bf54-5ee464ce6051	c1	Friends Distributor	Sundry Creditors	09BAVPG8804L1ZY	\N	0.00	Regular
ae2292b1-3d2f-426b-a4f5-49d4b6037a33	c1	Fright 12%	Direct Expenses	\N	\N	0.00	\N
ccf05ef1-00f6-4e34-86e6-e3d95ea9506d	c1	fright exp guru food	Indirect Expenses	\N	\N	0.00	\N
7bd69868-a139-434d-955b-df4c74cd49bc	c1	Frozen Junction	Sundry Debtors	09ADKFS8733M1Z7	\N	0.00	Regular
7ccd7962-4cdc-4657-820e-4c7d9fccf30d	c1	FRSL	Sundry Debtors	\N	\N	0.00	Unregistered
00b01ae2-19f5-400a-8d7d-0d87487122c7	c1	FURNITURE &amp; FIXTURE	Fixed Assets	\N	\N	-27337.48	\N
312ef1b1-e448-4100-a1cf-fbc220b64c52	c1	Future Value Retail Ltd.	Sundry Debtors	\N	\N	0.00	Unregistered
5726274d-afc3-4e55-83b9-bf6c0754f5a4	c1	Gail India Limited	Amazon Debtors	24AAACG1209J1Z2	\N	0.00	Regular
c480cad0-95ef-4fad-9e2e-6261b87d8362	c1	Galaxy Enterprises	Amazon Debtors	27DIFPS8256G1ZQ	\N	0.00	Regular
3f61d73c-14c1-4904-b580-2d45f8904771	c1	Galito	Sundry Debtors	\N	\N	0.00	Unregistered
b6592337-2153-405c-9c49-f9d6a43e58c6	c1	G and P Traders	Amazon Debtors	08AXHPG2697K1ZZ	\N	0.00	Regular
f0626fa4-b93e-4fde-b006-edf7369588db	c1	Ganesh	Sundry Debtors	\N	\N	0.00	Unregistered
52c05e1b-4279-4912-8451-9e22a4ddcc61	c1	Ganesh Sales &amp;  Servises	Sundry Debtors	09AXXPS1503N1ZO	\N	0.00	Regular
201160e5-f0d9-4000-b0c0-c00230fd418d	c1	Ganesh/shankar	Sundry Debtors	\N	\N	0.00	Unregistered
b6a25673-e289-49d2-96f6-d7dc2f88c4ae	c1	Ganesh Tea Stall	Sundry Debtors	\N	\N	0.00	Unregistered
4f78d6a2-8f6c-4b6d-aa14-d9796bb02282	c1	Ganesh Traders	Sundry Debtors	\N	\N	0.00	Unregistered
908e7aa8-798a-4b1b-902c-943eb1d4f2d4	c1	Gangaram And Sons	Sundry Creditors	09AQTPG4639E2ZH	\N	0.00	Regular
0091e7ce-765d-4769-b650-08c3fe904b49	c1	Gangour (Bareilly)	Sundry Debtors	\N	\N	-13976.00	\N
82ec7e8a-69c4-4044-9bba-56e33f735138	c1	Ganpati Cargo Logiatics	Capital Account	\N	\N	0.00	\N
3bfecb55-d4e1-4ddf-82d6-0c8ebfb00b03	c1	Gargi Mishra	Sundry Creditors	\N	\N	0.00	Unregistered
02dbbc04-a108-481f-bd93-ba22748db983	c1	Garima Store	Sundry Debtors	\N	\N	0.00	Unregistered
91ffe8d8-3417-436a-a695-7a3e0569b33c	c1	Garud Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
80f940ec-b6d3-4a06-9e0d-3fa84e56d596	c1	Garun Builders Pvt Ltd Xxxxx	Sundry Debtors	09AABCG9472G1ZB	\N	0.00	Regular
9eaa9d45-af7b-4098-9be2-7f1cc3859bac	c1	Garun Hotel Pvt Ltd	Sundry Debtors	09AABCG9472G1ZB	\N	-32273.00	Regular
7fd94d40-d1f4-42be-8486-2ae22c1ab52a	c1	GATEWAY	Sundry Debtors	\N	\N	0.00	Unregistered
35214051-f4bb-4a35-ad29-cf4b7dd6bd8e	c1	Gateway Departmental Store	Sundry Debtors	09ADEPY4848H1ZX	\N	0.00	Regular
b112aca3-05de-431e-b727-e319625d1719	c1	GATIMAAN ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
88f6123f-f00f-4327-8a67-99cff25ed311	c1	GAURAV GENERAL STORE	Sundry Debtors	\N	\N	0.00	Unregistered
84d0593c-9741-43d4-984b-d125c5bbabd0	c1	Gaurav Mehrotra	Unsecured Loans	\N	\N	0.00	\N
2aa53abd-ed82-409d-8953-3f9ce915739d	c1	GAURAV OVERSEASE	Sundry Creditors	07AITPC5389F1ZV	\N	0.00	Regular
b7e3f36c-0f24-4b30-ba93-5fd447f81d81	c1	Gaurav Pustak Bhandar	Sundry Debtors	\N	\N	0.00	Unregistered
35299460-a6e5-4faa-8af4-718e85f1d6df	c1	Gaurav Relish Cornor	Sundry Debtors	09APCPB1271K1Z3	\N	0.00	Regular
fd44b0fc-176c-4a15-8ae5-6cc12087dff4	c1	Gaurav Traders	Sundry Debtors	\N	\N	0.00	Unregistered
f7b33729-952c-4e3b-9062-bdd0aeaddbc9	c1	Gaurav....Xx	Sundry Debtors	\N	\N	0.00	Unregistered
d139f207-7140-4780-b939-3e733877dd34	c1	Geeta International	Sundry Debtors	\N	\N	0.00	\N
948ed047-9631-4322-be7c-07fcaacb6c80	c1	Geeta Provision Store	Sundry Debtors	09AFTPS8588M1ZW	\N	0.00	Regular
95767b45-6d05-4b50-8222-4397af8e77cf	c1	Geetika Stores	Sundry Debtors	09AHTPV8942Q1ZR	\N	0.00	Regular
47c3ef80-1ea2-4d0c-badb-ab16424e32e8	c1	GENERAL EXPENSES	Indirect Expenses	\N	\N	0.00	\N
1ec85ae3-8b1e-41b0-830f-cb077c689125	c1	General Medical Store	Sundry Debtors	\N	\N	0.00	Unregistered
e0f30a65-8088-46f2-8c45-354227567db1	c1	Genius Marketing	Sundry Debtors	\N	\N	0.00	Unregistered
c1bb0159-2b6a-4dd6-aa59-ebaf61a5d5ec	c1	Genius Marketing (Bamba Road)	Sundry Debtors	\N	\N	0.00	Unregistered
bfe15652-71a1-479d-ade5-70a1315af685	c1	Ghansyam	Sundry Debtors	\N	\N	0.00	Unregistered
468fe347-1bb8-4a28-8410-9a28e9bd94e6	c1	Gharana Bakery Pukhraya	Sundry Debtors	\N	\N	0.00	\N
9d0b8cdb-45ea-42be-81f7-05071fe99a64	c1	Global Communication	Sundry Debtors	\N	\N	0.00	Unregistered
983faa38-8dc9-4cf2-8c21-2e93fa8f69d8	c1	Global Wines Corporation	Sundry Debtors	09AAWFG4778P1Z2	\N	0.00	Regular
8a3c4de1-8138-4f5a-bf0a-0d0844a393f6	c1	Godown CAFE	Sundry Debtors	\N	\N	0.00	Unregistered
7786cfd8-b718-4455-b820-6ab763263084	c1	Goel Ji	Sundry Debtors	\N	\N	0.00	Unregistered
9cd3cac3-dd26-4c4a-96f9-556f8126bb68	c1	Goel Provision Store	Sundry Debtors	\N	\N	-1500.00	\N
4a2498c7-9350-4410-b6dc-2d92d5b14bf1	c1	Goel Store	Sundry Debtors	\N	\N	0.00	Unregistered
ba5e8d16-8626-488a-9d2e-de00d53bf65c	c1	GOKUL CATTERS &amp; SERVICES	Sundry Debtors	\N	\N	0.00	Unregistered
51ba954b-2cac-427b-be38-6425082d62be	c1	Gokul Foods	Sundry Debtors	\N	\N	0.00	Unregistered
e5325655-608f-4a4f-aa5d-917373fe7400	c1	Golden Crunch	Sundry Debtors	09AQPPH6596R1ZI	\N	0.00	Regular
0025c46b-f8ba-4bf6-8239-07407ff45641	c1	Golu Traders	Sundry Debtors	\N	\N	0.00	Unregistered
7f9d97ba-f977-4f13-9b30-c46313e5a437	c1	Good Bakery Pvt Ltd (Kesar Bagh)	Sundry Debtors	\N	\N	0.00	\N
b70fab3b-f429-402a-bfd9-e38ca0578e31	c1	Good Bakery Store and Cafe Pvt. Ltd.	Sundry Debtors	09AAHCG2607H1ZO	\N	-22926.00	Regular
fcb06677-c87a-4e2a-9c16-97c0b2e3a5cf	c1	Good Food People	Sundry Creditors	07ALGPK1152J2Z7	\N	841428.00	Regular
bcedae5c-127d-4600-b55b-4d82231f4a05	c1	Goodness of Nature	Amazon Debtors	09CSVPM6904N1ZP	\N	0.00	Regular
053f9bd5-104b-40c1-8e22-fe3ded80e625	c1	Google India Digital Services Private Limited	Sundry Creditors	\N	\N	0.00	\N
78085d0e-be1e-4cda-867d-13c07706bd06	c1	Google Pay Charges	Indirect Expenses	\N	\N	0.00	\N
272ab5bb-4e74-40df-9645-df0aa0aa2512	c1	Gopal Brothers	Sundry Debtors	\N	\N	0.00	Unregistered
d5e8224c-c15a-4caf-9b61-83ffa850e29b	c1	Gopal Das Sarab Dayal Sons.	Sundry Debtors	\N	\N	0.00	Unregistered
d2b9b69e-fb65-44af-bb9e-57bef9674058	c1	Gopal International	Sundry Creditors	07AAPFG9332A1ZG	\N	0.00	Regular
d244f5ea-1027-4ed5-bf37-03c265f0a363	c1	Gopal Shukla HUF	Unsecured Loans	\N	\N	0.00	\N
ae129ace-17e7-4fa2-98c5-f54b860cc1c2	c1	Gopal Sons	Sundry Debtors	\N	\N	-3483.00	Unregistered
1a1227c6-a8e0-46ec-a671-ac8262ff0d75	c1	Gourmet Foods	Sundry Debtors	09AADCB2914L1ZM	\N	-5649.00	Regular
be47f072-472e-4046-abac-f458d2391714	c1	Goverdhan Food Products	Sundry Debtors	09AXXPG3976H1ZO	\N	0.00	Regular
832f5f60-d8f2-4a36-93d5-2d6f68943850	c1	Govindum&apos;s Sweet &amp; Bakery	Sundry Debtors	\N	\N	0.00	\N
4b66712c-197d-4d36-ada7-e7c12aa0f66d	c1	GOYAL PROVISION	Sundry Debtors	\N	\N	0.00	Unregistered
b8de0df9-779f-4531-861f-9b8415680670	c1	G &amp; P Traders	Sundry Creditors	07AHEPA9353E1ZK	\N	0.00	Regular
43d96342-02a5-4a81-859d-c534039e64ba	c1	GRAND CLUB	Sundry Debtors	09AAQFG7127C1ZA	\N	0.00	Regular
267753be-cd20-4a18-ac5b-5cb8cdabf6cd	c1	G.R. Communiuation	Sundry Debtors	\N	\N	0.00	Unregistered
47fa949a-b661-4b18-ab54-58506c4e8af1	c1	Green &amp; Grill	Sundry Debtors	\N	\N	0.00	Unregistered
acb4d1b4-afbd-498c-901d-877198333c3e	c1	Green Juice Bar	Sundry Debtors	\N	\N	0.00	Unregistered
3e56b50e-39ef-4201-981a-edfdb543662a	c1	Greenliving Agribusiness Pvt Ltd	Amazon Debtors	32AAECG8126E1ZY	\N	0.00	Regular
dd35b3d9-b512-413d-8c73-122f1ab68dd4	c1	Griffin Projects Private Limited	Amazon Debtors	24AAHCG3210G1Z5	\N	0.00	Regular
f6cd227b-7f7b-42f6-80c0-03e2e4a6a3d0	c1	Grocers Store	Sundry Creditors	09FFWPS8515A1ZU	\N	0.00	Regular
112bc2d5-0273-444f-a8d5-cf5246660c05	c1	Gro Corner	Sundry Debtors	09AAVFG4009J1ZZ	\N	0.00	Regular
4e726115-1fcc-4a98-9b4e-724f7c9b820a	c1	GSM TESTING SOLUTION	Sundry Creditors	07APJPK1740H1ZO	\N	0.00	Regular
7f220427-f48d-4c58-9610-0f3f5b7f8035	c1	Gst Cash Ledger	Loans & Advances (Asset)	\N	\N	0.00	\N
373f8f11-6825-42c2-9693-4fabc58eaea2	c1	Gst Demand	Indirect Expenses	\N	\N	0.00	\N
9c7519df-56b2-4a0c-b723-9abffba6bd7e	c1	Gst Demand (2017-18)	Indirect Expenses	\N	\N	0.00	\N
9f2b1892-7a86-42df-86a4-120aff45663b	c1	Gst Deposit	Loans & Advances (Asset)	\N	\N	-7957.00	\N
c694c829-b0e9-42e7-acec-d182a35aef6e	c1	Gst Interest	Indirect Expenses	\N	\N	0.00	\N
f59878ae-e5fc-4e01-95f0-45a54dc5de6c	c1	Gst Late Fees	Indirect Expenses	\N	\N	0.00	\N
0b047796-8c28-49f1-b223-e9101d5c2df7	c1	GST Payable	Provisions	\N	\N	-179111.08	\N
bf4c6f25-3bf9-42bb-acbc-e865ad4063a7	c1	Gst Payment	Indirect Expenses	\N	\N	0.00	\N
d77bb83c-15e5-41bd-ab37-d72399658bdd	c1	GST PURCHASE INTERSATE 12	Purchase Accounts	\N	\N	0.00	\N
e1e6a537-66ea-4c88-9fa4-941d23747b0b	c1	GST PURCHASE INTERSTAE 0%	Purchase Accounts	\N	\N	0.00	\N
d528c950-8235-4be4-b6e9-eb58dea3edb9	c1	GST PURCHASE INTERSTATE 18	Purchase Accounts	\N	\N	0.00	\N
f52687aa-b49d-4321-8005-733d452fd37a	c1	GST PURCHASE INTERSTATE 28	Purchase Accounts	\N	\N	0.00	\N
6bbe7b56-0dad-4c3f-8b7a-eee1efbe90ab	c1	GST PURCHASE INTERSTATE 28% WITH CESS 12%	Purchase Accounts	\N	\N	0.00	\N
8c07777a-2239-4180-b8de-a96451e8d2de	c1	GST PURCHASE INTERSTATE40%	Purchase Accounts	\N	\N	0.00	\N
a11a2f49-0497-4cbe-a83f-c12e2b0d2926	c1	GST PURCHASE INTER STATE 5%	Purchase Accounts	\N	\N	0.00	\N
f8bf24db-eb4c-4679-9af8-d72c6af9584e	c1	G S Traders	Sundry Creditors	09ACHPS6219G1ZB	\N	0.00	Regular
c36b440a-8af9-4db4-8ddb-410a7b287440	c1	GST Receviable	Loans & Advances (Asset)	\N	\N	-116635.53	\N
02ee120f-938a-4727-95d1-cea6ca14ecbe	c1	GST SALE 28% WITH CESS	Sales Accounts	\N	\N	0.00	\N
c4c3c9cf-dbd4-43ae-962e-87b3e1bba658	c1	GST Sale in INTERSTATE 28% with Cess	Sales Accounts	\N	\N	0.00	\N
4c96d5d7-d484-419c-9b1e-511dadd798a3	c1	Gst Sale in INTERSTATE in 5%	Sales Accounts	\N	\N	0.00	\N
beb0b354-746a-4e2a-98df-0e645ac95d9f	c1	Gst Sale Inter State 0%	Sales Accounts	\N	\N	0.00	\N
8429ad5f-cdaa-4481-8238-f886e404bb30	c1	Gst Sale Inter State 12%	Sales Accounts	\N	\N	0.00	\N
730a69dd-e754-4c4c-8a1b-020fa830bf04	c1	Gst Sale Inter State 40%	Sales Accounts	\N	\N	0.00	\N
7b08ce3a-8d0c-4988-bfdd-eb58bc092a1a	c1	GST SALE INTERSTATE @18%	Sales Accounts	\N	\N	0.00	\N
5a2e7d72-c774-41a2-be35-92648fb6a2c9	c1	Gst Sale in Up 12%	Sales Accounts	\N	\N	0.00	\N
9204e2f9-b601-4de2-ada3-7d597af7c09d	c1	Gst Sale in Up 18%	Sales Accounts	\N	\N	0.00	\N
a4f0558e-c3e2-4603-9d6b-550a31cf4bf3	c1	Gst Sale in Up 28%	Sales Accounts	\N	\N	0.00	\N
4e19ad53-aba8-43f7-a094-f15fead875b5	c1	Gst Sale in Up 40%	Sales Accounts	\N	\N	0.00	\N
3768e611-4347-4c7d-a752-bc1c15abe9e5	c1	GST SALE IN UP @ 0%	Sales Accounts	\N	\N	0.00	\N
fdba07d6-3b8e-45a5-83b2-f00842d2b2e1	c1	GST SALE IN UP@5%	Sales Accounts	\N	\N	0.00	\N
977ec782-fd42-468d-9e72-0527698a9d3a	c1	Gst Tcs	Loans & Advances (Asset)	\N	\N	0.00	Unregistered
96ca4508-c723-45de-8a95-233a374501b5	c1	GUD FOOD	Sundry Creditors	09AAAHU8375C1ZW	\N	0.00	Regular
bcb7074d-b421-4657-8d8f-bfd64e35cf15	c1	Gulab Singh &amp; Sons Bar &amp; Restaurant	Sundry Debtors	09AAPFG8655E1ZW	\N	0.00	Regular
8c486e75-dd57-4f38-ae03-b2f2837930d6	c1	Gulati Entertainmaint	Sundry Debtors	09AGAPG2845F1ZO	\N	0.00	Regular
c66294d0-e661-441d-8e2a-cdfc936b2dc3	c1	Gulati Stationers	Sundry Debtors	09ABKPG5378E1ZG	\N	0.00	Regular
04feda4b-2814-4d5f-8220-87053e992883	c1	Gulshan Electronic &amp; Electricals	Sundry Debtors	09ASHPS4127P1Z0	\N	0.00	Regular
feba346f-703f-4bbb-8ebc-e0808cd4b988	c1	Gunjan Store	Sundry Creditors	\N	\N	0.00	Unregistered
9e30b886-6558-4f3d-b66b-bac672fc2b2d	c1	G UNOOONNY AND SONS	Amazon Debtors	32AASPB4733F1ZZ	\N	0.00	Regular
af670c4c-42fd-4304-aa2e-ff2610292e7e	c1	Guota Electronics	Sundry Debtors	\N	\N	0.00	Unregistered
08d49480-44bf-41b5-a5f3-9440418fbb7f	c1	Gupta Book Store	Sundry Debtors	\N	\N	0.00	Unregistered
641d7743-2a2f-471d-8509-3d1446bcb8f2	c1	Gupta Electronics	Sundry Debtors	09AHBPG1566H1ZH	\N	0.00	Regular
c68677a0-7e16-470b-b9ca-0ccb9ec0255b	c1	Gupta Misthan Bhandar	Sundry Debtors	\N	\N	0.00	\N
017b0599-4d11-4bc5-8e99-0d1ddbb286d7	c1	Gupta Paan Shop	Sundry Debtors	\N	\N	0.00	\N
2847f62a-9419-4936-babf-98ad75b024cd	c1	Gupta Provision Store	Sundry Debtors	09BASPG3060P1Z3	\N	0.00	Regular
5791812d-7958-4c68-b9a8-26d64d6b97e0	c1	Gupta Store	Sundry Debtors	\N	\N	0.00	\N
53eb31df-9472-4f93-9ec4-8621c1f858a8	c1	Gupta Traders	Sundry Debtors	\N	\N	0.00	Unregistered
bd30631e-8ada-4991-a6fc-05615f81f8f0	c1	GURGRIPA AGENCIES	Sundry Creditors	\N	\N	0.00	Unregistered
32912464-aa78-4f02-b928-d1761f4fa084	c1	Gurmeet Masala	Sundry Debtors	09ALCPM3994L1ZG	\N	0.00	Regular
d20bea10-25c2-4613-b9aa-c4f98fbb1713	c1	Gurmeet Masala Bhhandar &amp; Sons	Sundry Debtors	09APBPK3987J1ZE	\N	0.00	Regular
47fd72d0-b42c-4f56-9000-b2fd1e584150	c1	Gurmindar Singh	Sundry Debtors	\N	\N	0.00	Unregistered
d33b8640-301d-4eac-996d-d794cc4859fb	c1	Guru Charan Diwakar	Sundry Debtors	\N	\N	0.00	Unregistered
1e5f3da9-26f1-45c7-baff-9402fcd91437	c1	Guru Food 1106	Sundry Creditors	\N	\N	-3664.00	\N
e4755557-6ce8-41bf-8f47-ed83324a87bc	c1	GURU FOODS	Sundry Creditors	\N	\N	-6684.73	\N
6c10a317-d763-47e8-98a9-b020e52f44bd	c1	Guru Kripa Agencies	Sundry Creditors	\N	\N	0.00	Unregistered
43cc2d37-ee73-4093-8597-e1fe9d698669	c1	GURUKRIPA IMPEX	Sundry Creditors	07AANHM6436K1ZO	\N	0.00	Regular
52d970f3-244a-49bc-b3ca-99f285cfc0ab	c1	Guru Maa	Sundry Debtors	\N	\N	0.00	Unregistered
17c0e96c-0e7a-4e9a-a6cd-0ef47f403451	c1	GUSTO	Sundry Debtors	09ABAFG1207E1ZZ	\N	0.00	Regular
db59c1cc-097c-40c8-9fad-d161140de981	c1	Gustora Foods Pvt. Ltd.	Sundry Debtors	08AADCG291C1ZX	\N	0.00	Regular
6d890f1a-6af3-44d8-9c70-be3d9487b86c	c1	Gyan Pharma	Sundry Debtors	\N	\N	0.00	Unregistered
3bac247f-4ade-411c-b9de-1e397b97ccad	c1	Hanumath Enterprises	Sundry Debtors	09BCGPR0047H2ZJ	\N	0.00	Regular
246bb322-c826-4c17-ace0-b5eba57a0b2f	c1	Happey Life	Sundry Debtors	09AADCH5062K1ZD	\N	0.00	Regular
3a958860-d434-48ac-b0f0-399a2c25ffbf	c1	HAPPY MART	Sundry Debtors	09BGBPJ0255J1ZI	\N	0.00	Regular
ad7a16bb-b13d-40b0-9fb3-f6088c94b116	c1	HARI GENERAL STORE	Sundry Debtors	\N	\N	0.00	Unregistered
616b98b6-2b3f-4ce0-a64b-906325db3eb4	c1	HARISH	Sundry Debtors	\N	\N	0.00	Unregistered
94aeda9f-83cf-45cb-b0a2-71de32febecb	c1	Harish Genral Store	Sundry Debtors	\N	\N	-1240.00	Unregistered
5884a5e8-2270-4cb5-8d34-855dfe0dfdf0	c1	Harish Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
5bc3beea-bbe6-4383-91cd-713b19412675	c1	Hari Veg	Sundry Debtors	\N	\N	0.00	\N
78688fd9-2568-44cd-921e-bf627e247141	c1	HARI VEG STORE	Sundry Debtors	\N	\N	0.00	\N
047676b7-c5c2-4d5a-9889-8a80d2ac56ac	c1	HARJOT SINGH	Capital Account	\N	\N	0.00	Unregistered
cda994c3-2d56-4dd0-88d9-4a6da5ce8e11	c1	HAR NATH RAM NATH	Sundry Debtors	\N	\N	0.00	\N
7def3400-2a28-4755-bfc9-06b6cb417206	c1	HAVMOR ICE CREAM PVT LTD	Sundry Debtors	09AABCH6766L1Z0	\N	0.00	Regular
d0646912-fafb-43a3-b61c-4bcc341ce177	c1	Hazari Lal &amp; Sons	Sundry Debtors	09AAAFH9358J1ZX	\N	-3068.00	Regular
37e1ab13-0a25-49d4-9884-92e1d76e5027	c1	Hazelnut Factory Food Pvt. Ltd	Sundry Debtors	\N	\N	0.00	\N
312c004e-0280-4e29-a06e-2d28f2413a26	c1	Healthvisor Solutions Private Limited	Amazon Debtors	07AAFCH5929P1ZX	\N	0.00	Regular
56923d9c-7e9a-4419-ac63-6b67ebc3a6ea	c1	HEERA ENTERPRISES	Sundry Creditors	09AADFH7702B1ZR	\N	0.00	Regular
73108fee-a16d-4cf4-a15d-147066d00537	c1	Hello Madam	Sundry Debtors	\N	\N	0.00	Unregistered
4bd364cc-000f-4633-9fb4-a510016bd18d	c1	Hemant Store	Sundry Debtors	\N	\N	0.00	Unregistered
5f098586-0c16-4d47-97dc-9edf16c0f627	c1	Hey Keshav Its Yours	Sundry Debtors	09AMAPK2137Q1ZR	\N	0.00	Regular
26e0958a-6630-4736-8338-976bb8932ed0	c1	Himalayan Trading	Sundry Creditors	24GERPS9202H1Z0	\N	0.00	Regular
4082fbc6-0ffa-4e4b-8651-9050492be1ac	c1	Hindustan Electrical and Automation	Sundry Debtors	\N	\N	0.00	\N
434204a9-3c77-4ad6-9929-9962e89f4fdd	c1	Hindustan Electronic	Sundry Debtors	\N	\N	0.00	Unregistered
8db41fbc-7961-4c3d-bce6-e573c56bcd24	c1	Hindustan Liquids Private Limited	Sundry Creditors	07AADCH2897L1Z2	\N	0.00	Regular
3e9274b4-a98e-4663-bb0e-3f5e9259b29c	c1	Hindustan Unilever Limited (Bihar)	Amazon Debtors	27AAACH1004N1ZU	\N	0.00	Regular
5855ef44-b2ce-4246-a5e7-137737488597	c1	Hindustan Unilever Limited (Delhi)	Amazon Debtors	27AAACH1004N1ZU	\N	0.00	Regular
e763413f-5034-4c1a-a1ab-2a905492a7ce	c1	Hindustan Unilever Limited (Gujarat)	Amazon Debtors	27AAACH1004N1ZU	\N	0.00	Regular
ee6a6a10-c6a1-494f-8696-19264ba80d2b	c1	Hindustan Unilever Limited (Karnataka)	Amazon Debtors	27AAACH1004N1ZU	\N	0.00	Regular
7cac4e3b-826d-40ce-af90-9b17c1705ba4	c1	Hindustan Unilever Limited (U.P)	Amazon Debtors	27AAACH1004N1ZU	\N	0.00	Regular
64b55ebb-d85a-40c0-b884-feddc28b4e6e	c1	Hindustan Unilever Limited (West Bengal)	Amazon Debtors	27AAACH1004N1ZU	\N	0.00	Regular
114ca69d-772f-4c87-abc7-9735103bec9d	c1	Hindustan Unilever Ltd.	Sundry Creditors	09AAACH1004N1ZS	\N	33.73	Regular
5503ba85-e550-4024-8e1c-e14357caebdb	c1	Hirezu Management Services	Amazon Debtors	27AUBPP0642E1ZY	\N	0.00	Regular
0304593d-dfc5-4dca-8bbe-674f0ce017f0	c1	Hi-Tech Engineers	Sundry Creditors	09ALCPK7738G1ZV	\N	0.00	Regular
2e56f6e1-7861-48cf-89c7-93f66727b6f5	c1	Hi-Tech Systems &amp; Services Ltd	Amazon Debtors	19AAACH6621F1ZR	\N	0.00	Regular
cd04e4ba-3750-44f1-9836-7ea3cf4ffda4	c1	Hitesh Khatari	Sundry Debtors	\N	\N	0.00	\N
0f59abc7-7c33-4b82-b48a-8ce54824e1e6	c1	H.M.Brothers	Sundry Creditors	\N	\N	0.00	Unregistered
c7ef901b-9d81-4b73-b994-5af59999854e	c1	HOL-LAND MARKETING PVT. LTD	Sundry Creditors	\N	\N	2186.00	\N
4dd64c80-f4f7-4ae7-b4c5-f5b033399b89	c1	Home Basket	Sundry Debtors	09IADPS5691J1ZU	\N	0.00	Regular
09adaae6-e776-4ca4-847c-0f8cfcdce6dc	c1	Horizon Cereals Industries	Sundry Creditors	\N	\N	0.00	Unregistered
f533be1b-d82f-47f4-9afc-75d50498b55e	c1	Hot Baikers	Sundry Debtors	\N	\N	0.00	Unregistered
3f73026e-f386-4ea5-bfbb-50086129f2b6	c1	HOTEL AMANTRAN	Sundry Debtors	09ADVPT0191K2ZP	\N	0.00	Regular
30eff0c1-db98-412f-bd2b-3a545933c0e5	c1	Hotel Amber (A Unit of K D Complex)	Amazon Debtors	05AAFFK9018B2ZO	\N	0.00	Regular
1777c50e-6274-4a98-a4bd-27c3ddcc9b89	c1	Hotel Haven View	Sundry Debtors	09AAIFH5750N1ZT	\N	0.00	Regular
fa6f3c35-a6a0-4f70-81cf-f69137b6bbe9	c1	Hotel Pandit Pvt. Ltd.	Sundry Debtors	09AABCH4797D1ZE	\N	0.00	Regular
1e440a42-5f46-4505-a07a-0adfc190b727	c1	Hotel Varuna	Amazon Debtors	09AABFH4023K1ZI	\N	0.00	Regular
f41736be-c968-4ce0-90a8-0665a647c5aa	c1	Hridya Health Care	Sundry Debtors	\N	\N	0.00	Unregistered
6ed189ff-738d-428e-ada7-949e75f33886	c1	Hsb Food &amp; Hospitality	Sundry Debtors	\N	\N	0.00	\N
8cc11577-1132-4e55-b872-36a6da0317ca	c1	Hukka Restrarent	Sundry Debtors	\N	\N	0.00	Unregistered
87347c45-e7ef-4f11-9ce4-d06f027cd84a	c1	HUL Software Handling Expenses	Indirect Expenses	\N	\N	0.00	\N
d396fe6b-94ad-485a-a0ae-4a1e09f118b7	c1	Hundred Wholesale Networks Pvt.Ltd.	Sundry Debtors	\N	\N	0.00	Unregistered
1a0192eb-2fd4-48e8-ae11-02d8d4ef715b	c1	Ibizza Food Speciality Pvt Ltd	Sundry Creditors	06AADCI5264J1ZG	\N	0.00	Regular
693162f2-86c4-4d5c-9266-b087eac66b35	c1	ICE BALLS	Sundry Debtors	23AAYFM4885H1ZL	\N	0.00	Regular
bbad82d4-bdd3-4b1f-bc05-9dac009b4d49	c1	Ideal Medical Stotre	Sundry Creditors	\N	\N	0.00	Unregistered
aa9359b6-8d7f-48f0-9ce4-021556fea5e2	c1	Ideal Radio &amp; Electronic Works	Sundry Debtors	09AKGPG9984K1ZC	\N	0.00	Regular
dba21f20-c133-4939-915f-da44173a651c	c1	IGST 12	Duties & Taxes	\N	\N	-231305.89	\N
3c7530db-cb33-4563-bfec-75afc4df0f03	c1	IGST 18	Duties & Taxes	\N	\N	-141149.11	\N
06b78516-b5d9-4be8-8db1-943fe5b83c76	c1	IGST 28	Duties & Taxes	\N	\N	-38790.36	\N
23b220c5-af0d-440f-81d5-68fa1546a979	c1	IGST 28%	Duties & Taxes	\N	\N	-7660.80	\N
8d7e2737-db0b-4871-968a-a89c69f2eae2	c1	IGST 40	Duties & Taxes	\N	\N	-22321.78	\N
9389d814-ae34-4fc6-8dcc-429e2a6a63e1	c1	IGST 5	Duties & Taxes	\N	\N	-351501.47	\N
97d2b0a2-1238-4421-89d1-e6bd794cdf02	c1	IGST CESS 12%	Duties & Taxes	\N	\N	-13298.04	\N
326f5c73-dfff-47ea-8fe9-f78658ff5c6c	c1	Igst Payable	Duties & Taxes	\N	\N	0.00	\N
c74a59e9-171c-4620-8891-4a281a1a3a57	c1	Imperativ Hospitality Private Limited	Amazon Debtors	07AABCI6836L1Z8	\N	0.00	Regular
334f2b74-e64b-4912-a1fd-4388d194b0dd	c1	Impression the Beauty	Sundry Debtors	\N	\N	0.00	Unregistered
e05e2087-086c-4cdc-96ca-51e020b8924b	c1	I M Puri	Sundry Debtors	\N	\N	0.00	Unregistered
74118b4a-8e9a-486a-9e3b-d71e02ec08b9	c1	incentive 18%	Indirect Expenses	\N	\N	0.00	\N
78591e8e-924e-4e30-8e21-4284143b817b	c1	incentive 40%	Indirect Expenses	\N	\N	0.00	\N
cc738ee5-bcfd-48a8-88ab-4193c61c624f	c1	Income Tax	Current Liabilities	\N	\N	0.00	\N
341a70dd-686a-4e42-ac89-bd03fad35fb0	c1	Indra Enterprises	Sundry Debtors	\N	\N	0.00	\N
0a977dae-6769-4c04-8a3d-7d01f3675729	c1	INFINITY ENTERPRISES	Sundry Debtors	09KOBPS8934C1ZG	\N	0.00	Regular
47f6704d-8413-477d-98d0-58a75b2a4acb	c1	Innovo Technologies	Sundry Debtors	09AOCPN9091G1ZK	\N	0.00	Regular
6832a760-db65-4a6b-98af-75694366cf69	c1	Inovsia	Amazon Debtors	14ACVPT7047F1Z3	\N	0.00	Regular
5e005266-69b1-4312-9327-e817fd72b99d	c1	INOX	Sundry Debtors	\N	\N	0.00	Unregistered
52f72c70-1b3a-481e-abaf-9a23b6095294	c1	Input CESS	Duties & Taxes	\N	\N	0.00	\N
52be901e-c246-4789-99b9-23b1c461a7f9	c1	Input Cess 12%	Duties & Taxes	\N	\N	-10976.89	\N
cef72dca-67bb-4cef-83c9-046b42f61882	c1	Input CGST	Duties & Taxes	\N	\N	0.00	\N
63a0ae58-a99d-445e-b9aa-65b68409b687	c1	Input CGST 14%	Duties & Taxes	\N	\N	-7345.55	\N
a779d91a-ae22-4660-91c2-b0a65cd72de1	c1	Input CGST 20%	Duties & Taxes	\N	\N	0.00	\N
45e59999-30c0-4c7b-8318-ebde623c8979	c1	Input CGST 2.5%	Duties & Taxes	\N	\N	-52010.22	\N
8ed5e98e-62be-4ff8-9eef-e65a16c9c52d	c1	Input CGST 6%	Duties & Taxes	\N	\N	-47093.07	\N
8ea89e6c-099b-48e6-9244-dc03127032b9	c1	Input CGST 9%	Duties & Taxes	\N	\N	-241012.75	\N
05849473-7432-4a45-ad5f-573da5235472	c1	INPUT IGST	Duties & Taxes	\N	\N	-967.00	\N
702494c8-7026-4c29-97da-53adb699b83d	c1	Input SGST	Duties & Taxes	\N	\N	0.00	\N
46848c84-d1f8-474a-b754-d4c0ddea4033	c1	Input SGST 14%	Duties & Taxes	\N	\N	-7345.55	\N
f5bf95ed-4888-4188-b156-a794d0429607	c1	Input SGST 20%	Duties & Taxes	\N	\N	0.00	\N
448c6f75-1cce-457f-8ef3-ad2b6520e266	c1	Input SGST 2.5%	Duties & Taxes	\N	\N	-52010.22	\N
335a5476-6815-4da7-8aaf-db73e0b9b551	c1	Input SGST 6%	Duties & Taxes	\N	\N	-47093.07	\N
40156663-7391-445a-9ba8-69cfcd8e2b08	c1	Input SGST 9%	Duties & Taxes	\N	\N	-240935.53	\N
d96d815d-87c2-4d60-8350-03e6997f1f6c	c1	Insurance	Indirect Expenses	\N	\N	0.00	\N
f9473f31-aabd-499b-a313-573963e71cbc	c1	Insurance 18%	Indirect Expenses	\N	\N	0.00	\N
3a2eb8f8-5cf2-4061-a7fb-2423da3bc028	c1	Insurance 5%	Indirect Expenses	\N	\N	0.00	\N
ea437861-3ef8-4a5c-b1a1-3a4b239667fc	c1	Interest on Car Loan Account	Indirect Expenses	\N	\N	0.00	\N
e7e02b69-cadc-46f7-97a7-42ac1408730d	c1	Interest on Gst	Indirect Expenses	\N	\N	0.00	\N
69915ccf-447d-4917-ad59-e37f7eb9271e	c1	Interest on Loan	Indirect Expenses	\N	\N	0.00	\N
ba53f4bd-b7f4-40ee-920f-cdd30c7035dc	c1	INTEREST RECEIVED	Indirect Incomes	\N	\N	0.00	\N
923df4a6-7648-4a89-96ba-e056181a740a	c1	Internet Exp	Indirect Expenses	\N	\N	0.00	\N
f04e2062-b764-400f-b5dd-2e80e769bf32	c1	Internet Expemses	Indirect Expenses	\N	\N	0.00	\N
39fadf59-5d6b-4699-9cfd-dffad814744e	c1	IN TOWN MART	Sundry Debtors	09BDSPM3303C1ZO	\N	-6045.98	Regular
734f416e-b03a-4576-aab3-948f3b060457	c1	Intt on CC A/c	Indirect Expenses	\N	\N	0.00	\N
6ae2fa95-ab98-44ab-a466-28495ede45dd	c1	IQBAL AHMAD &amp; SONS	Sundry Creditors	09AUEPS6996H1ZR	\N	0.00	Regular
50fd30ce-25b0-41c8-ba72-9b4247ac1646	c1	Isha Enterprises	Sundry Creditors	09AUBPR7815D1ZJ	\N	67931.00	Regular
782e7751-9ec1-4e99-b497-7603e4074224	c1	ISHANI ENTERPRISES	Sundry Debtors	09AIVPG1432D2ZC	\N	-6840.00	Regular
1c508fbf-a15d-4bc6-90d1-9e107a8ecea1	c1	ISHI ENRERPRISES	Sundry Debtors	09BFTPG8085C1Z0	\N	0.00	Regular
99b60010-c235-4ad4-8016-71ea72602a37	c1	Ishwardas Madho Parasad	Sundry Creditors	\N	\N	0.00	Unregistered
365cb5a9-b470-4f96-b857-d3497d9a32ca	c1	Ishwardas Rajendera Parasad	Sundry Creditors	\N	\N	0.00	Unregistered
a112bbf8-8e25-480d-83ad-2f7c5a1d417c	c1	Jagan Bros.	Sundry Debtors	\N	\N	0.00	Unregistered
37ef8862-0002-495b-a548-a9b42054fc87	c1	Jagdish Electric Works	Sundry Creditors	\N	\N	0.00	\N
fc8e35c7-8e03-4589-a3db-50c8c011ae52	c1	Jai Ambey Traders	Sundry Debtors	09DIKPK2873N1ZH	\N	0.00	Regular
8b7d5929-4d02-4969-86ca-a66b932f9d9e	c1	Jai Conactionary	Sundry Debtors	\N	\N	0.00	Unregistered
2202433f-ba05-47f5-a33b-f4bc7a73c38a	c1	Jai Durga	Sundry Debtors	\N	\N	0.00	Unregistered
fe11f30d-48fe-4950-bdd6-29b3bcc28c1c	c1	Jai Durga General Store	Sundry Debtors	09AAXPK6820H1Z6	\N	0.00	Regular
9e779291-0b68-4717-a889-6180a5e5d259	c1	Jai Mahaveer General  Store	Sundry Debtors	09ABSPJ4679H1ZX	\N	1000.00	Regular
82797873-6ea2-484e-bdef-09b4be0e8a31	c1	JAI MATA DI ENTERTAINMENT PRIVATE LIMITED	Sundry Debtors	09AACCJ1264G1ZP	\N	0.00	Regular
96ebb13a-2679-446d-ada9-1788d21d365e	c1	Jain Brothers	Sundry Debtors	09ABMPJ4676N2ZS	\N	0.00	Regular
e6c99cd4-2ae2-4e16-9a04-ad41a5dffbf3	c1	Jain Brothers (SOKNP_36594 )	Sundry Debtors	09AHCPJ1139N1Z7	\N	0.00	Regular
736e0a73-9ae2-40c9-b4b1-a1b6b8050e3f	c1	Jain Doodh Bhandar	Sundry Debtors	\N	\N	0.00	\N
3d9c97af-bf48-4681-98ee-242d8e840b00	c1	Jain Trading Company	Amazon Debtors	19AEJPB2979L1ZZ	\N	0.00	Regular
669a83d3-435c-4671-94e2-13d8b85876b9	c1	JAI PROVISION STORE	Sundry Debtors	09ENGPS5844K1Z7	\N	0.00	Regular
e30494c4-c9d3-48d7-a41a-fe62e07dc7c4	c1	Jai Shankar Cornor	Sundry Debtors	\N	\N	0.00	Unregistered
bfc24c6c-5c17-45b5-8af6-34da611327b8	c1	Jaiswal Medical	Sundry Debtors	\N	\N	0.00	Unregistered
aa685d64-ece2-4afd-af2a-d3968d0e4c07	c1	Jaiswal Medical Store	Sundry Debtors	09AEUPJ8362A1Z7	\N	0.00	Regular
6bdcfcee-ce48-4c85-9048-97c25a2d1e4c	c1	Jaiswal New (Sisamau)	Sundry Debtors	\N	\N	0.00	\N
2e150a84-5986-48fd-9526-83fadf26bb90	c1	Jaiswal Store	Sundry Debtors	\N	\N	0.00	Unregistered
4d6b747b-5e33-4c29-b1eb-8167cbd2a16e	c1	Jalan Provision	Sundry Debtors	\N	\N	0.00	Unregistered
cf8392ff-aab6-4dc7-958f-a3167d3ab79f	c1	Jamuna Das Bakesr (Varanasi)	Sundry Debtors	\N	\N	-200.00	\N
850721e8-2595-4809-b69f-5461a27eb90d	c1	Jamuna Tarders	Sundry Debtors	\N	\N	0.00	Unregistered
f79b50b5-8380-4860-83d0-448674ae1aa9	c1	Janjeewan Medical &amp; Surgical Store	Sundry Debtors	09AAKFJ5917F1Z5	\N	0.00	Regular
99e3482b-9857-4cce-aee1-1f8536c9629d	c1	Janta Medical	Sundry Debtors	\N	\N	0.00	Unregistered
2fab1602-63cf-4a88-8f28-7e262f6b1752	c1	Janta Pan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
26db26e5-5644-4f6d-8bc3-f1769841f5fd	c1	Janta Watch House	Sundry Debtors	\N	\N	0.00	Unregistered
3937eae3-fc55-4851-bd68-fe6dfa62278f	c1	JANVI MOCTAIL	Sundry Debtors	\N	\N	-1560.00	Unregistered
a3a9d37a-e9af-4549-8ec8-8284364f648d	c1	Janvi Moctail (Naveen Market)	Sundry Debtors	\N	\N	-32.00	\N
5aa59cce-951d-46e8-a319-8e5a968f33ae	c1	Janvi Pan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
96247dd6-ad67-4332-89f7-611b3b45e7db	c1	Japan Radio and Electricals Comapany (Kidwai Nagar)	Sundry Debtors	09AGXPR0809D1Z2	\N	0.00	Regular
7e1e860d-ca72-4ab8-b4c4-dab2505f7886	c1	Japan Radio &amp; Electric Co.	Sundry Debtors	09AGXPR0809D1Z2	\N	0.00	Regular
5e1540ed-680a-4fbf-8c7f-83c1f093eb0a	c1	JAPAN RADIO &amp; ELECTRIC COmpan	Sundry Debtors	09CGQPD4490R2ZE	\N	0.00	Regular
da81258f-4c60-4475-b4a1-4071f54a9d53	c1	Japnico Electronic	Sundry Debtors	09AAYPV4868R2ZW	\N	0.00	Regular
c2a151b4-0b26-484b-981a-96dbd05d28f5	c1	Jasleen Store	Sundry Debtors	\N	\N	0.00	Unregistered
19fe537a-5e3a-4af1-96fb-c4718af8231b	c1	Jassi	Sundry Debtors	\N	\N	0.00	Unregistered
333e87fe-5f91-4123-b8eb-2ffa5ae47bf1	c1	Javed Bhai	Sundry Debtors	\N	\N	-8000.00	Unregistered
b10e06ac-05f5-4ac0-bc05-11859586dad8	c1	Jawala Medical	Sundry Debtors	\N	\N	0.00	Unregistered
fdf2d827-4ec3-4666-8b8d-cd73428ead06	c1	Jay Ganesh Fintech	Amazon Debtors	24AAOFJ6326NIZV	\N	0.00	Regular
100bd7e2-6497-48c4-9f19-3fbcdbd4c37f	c1	Jay Shree Sales Corporation	Sundry Debtors	09ACZPP6555G1ZP	\N	0.00	Regular
5f0684c9-c777-402c-985c-726f19c170ae	c1	Jb Plastice and Packaginig Solution and Coolsyst Co	Amazon Debtors	27AOMPJ8515P2Z5	\N	0.00	Regular
83fddaf3-0d22-4c5e-b042-a09d0f3b5bcb	c1	J.D Chef	Sundry Debtors	\N	\N	0.00	Unregistered
c55f7f0d-800a-4ee3-997e-c7e37f63e11a	c1	JD SALES	Sundry Debtors	\N	\N	-1540.00	\N
fbadb547-d69e-4f1b-ab32-c1b4b104f253	c1	Jeet Provision Store	Sundry Debtors	09ALEPS7901F1ZY	\N	0.00	Regular
79ceeb76-2aee-4327-9360-141f100ea869	c1	Jha Infotech Pvt Ltd.	Amazon Debtors	08AABCJ4370J2ZF	\N	0.00	Regular
aa445960-54e8-462a-8816-85dfd0a907bd	c1	Jhansi Auto Cylinder Reboring Works	Amazon Debtors	35AFUPK1437N1ZW	\N	0.00	Regular
9ef09c64-397a-4481-a4b6-dcff565fc7f0	c1	Jindal Store	Sundry Debtors	\N	\N	0.00	Unregistered
1917c9ee-3c1e-42fd-bc03-bd698aba8940	c1	Jindal Traders	Sundry Debtors	\N	\N	0.00	Unregistered
eb718317-49b1-481c-9788-a988f89c7c0e	c1	JIO FIBER OFFICE EXPENCE	Direct Expenses	\N	\N	0.00	\N
e3b955f6-dfb4-4c61-82d8-4692746a8984	c1	Jiya Store	Sundry Debtors	\N	\N	0.00	Unregistered
6c6427e7-3cf9-448d-903d-4c9fa1f12d2c	c1	JJ BAKERS &amp; CONFECTIONERS	Sundry Debtors	\N	\N	0.00	\N
500a88f1-d0d8-4dab-802e-7946c8717104	c1	J K CONSTRUCTION	Sundry Debtors	\N	\N	0.00	\N
2bac4c31-5f4e-4bd7-9c45-bd0856a5c277	c1	J &amp; K Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
302603c5-0686-486e-a843-0f1fd682b193	c1	JKP UPHAR	Sundry Debtors	\N	\N	0.00	Unregistered
38f75273-d599-42ab-8e98-42ab3cc02a79	c1	Joginder Pal RajPal	Sundry Creditors	03BOYPA8316J1ZP	\N	84574.00	Regular
5024b318-1435-4b86-a865-7e3b6f5ec250	c1	J.P. Store	Sundry Debtors	\N	\N	0.00	Unregistered
e37152f6-5ff3-42f4-a8db-f6279e84ebac	c1	J.P. TRADERS	Sundry Creditors	07AAVPP0605M1Z9	\N	0.00	Regular
c9d9b9f5-b88b-4c54-963e-bcb0f83a5fd3	c1	J.Puneet Store	Sundry Debtors	\N	\N	0.00	Unregistered
4ef9da58-d824-48ac-8b79-e4420c4f4527	c1	J R Trading Company	Sundry Debtors	\N	\N	0.00	Unregistered
12c02985-003f-4816-b69b-2bdb1cafb575	c1	J S Continental	Sundry Debtors	\N	\N	0.00	Unregistered
8f4cfd1d-8ca4-4734-a802-a707fc54251b	c1	JUSHN RESTRO	Sundry Debtors	09AADCJ9829Q2ZJ	\N	0.00	Regular
30e72fca-960a-4328-be57-02261b9957c0	c1	Jyoti General Store	Sundry Debtors	09BIQPS1075J1ZL	\N	0.00	Regular
2cbc9c00-344c-4a72-8f11-6e592c989cc9	c1	Jyoti Kirana Store	Sundry Debtors	\N	\N	0.00	Unregistered
a0e14ffc-0f6c-46de-9aee-d8cbe8cf8101	c1	Jyoti Traders	Sundry Debtors	\N	\N	0.00	Unregistered
a5fd719d-2f53-4893-9f2d-8c1b37cb8fc5	c1	K)	Sundry Debtors	\N	\N	0.00	\N
cc4a7cdb-c572-4c9e-9542-fe8dfe91db7e	c1	Kadambari Store	Sundry Debtors	\N	\N	0.00	Unregistered
c5d60f4d-4d5f-442d-9e9a-f38280c27f59	c1	KAGS INNOVATION	Sundry Debtors	09AAXFK0407G1Z6	\N	-1848.00	Regular
ebb7c481-e4fa-400b-a275-5384020c77a7	c1	Kailian Food Pvt Ltd (Delhi)	Sundry Creditors	07AAKCK0713F1ZU	\N	0.00	Regular
0c3a9e25-c2d4-4441-bfb3-9d9a5d12dc11	c1	Kailian Food Pvt Ltd (Maharashtra)	Sundry Creditors	\N	\N	0.00	\N
c98bbae6-9c5b-4584-8dbc-90aebcba748f	c1	Kajal Departmental Store	Sundry Debtors	\N	\N	0.00	Unregistered
fd543e74-3a85-4464-8d1c-f51b869452fb	c1	Kalyan Baikery Shop	Sundry Debtors	09ABBPA2086J1ZT	\N	0.00	Regular
c4e0528d-54a2-424a-b31f-717df159fa79	c1	Kalyan G	Sundry Debtors	09ADTPA3977C1ZC	\N	0.00	Regular
48b21373-bb57-439c-bc27-669a0d65c0ed	c1	Kalyan G Baikery	Sundry Debtors	\N	\N	0.00	Unregistered
82683247-9b1f-42eb-a3d5-25214c39f1d9	c1	KALYAN G BAKERY &amp; NAMKEEN	Sundry Debtors	09AEYPA9057K1ZP	\N	0.00	Regular
0c316c7f-346b-46a7-9e92-553e64baefd4	c1	Kalyan G Bakery Pvt Ltd.	Sundry Debtors	09AAHCK1335J1ZG	\N	0.00	Regular
e3c67807-6d4c-4042-bae8-2a062b4dc418	c1	Kalyan G  (Ghumti)	Sundry Debtors	09AEYPA9057K1ZP	\N	0.00	Regular
fd172867-cbf9-4f8d-b876-0e6d287d2485	c1	Kalyani B	Amazon Debtors	33ATEPK7140G1ZY	\N	0.00	Regular
fb0403d7-e3bc-4c36-ae52-a325dfc15301	c1	Kalyani Enterprises	Sundry Debtors	09AKPPG0106Q1ZV	\N	0.00	Regular
086b4171-c9d0-40f3-9d43-0d8a621b7ebf	c1	Kalyani Store	Sundry Debtors	\N	\N	0.00	Unregistered
5c249fd4-cf33-4db8-a34d-676f55de43e5	c1	Kamal Store	Sundry Debtors	\N	\N	0.00	Unregistered
1865a52a-3485-49ac-8966-08949489be0c	c1	Kamayani Overseas	Sundry Creditors	\N	\N	0.00	\N
80dbb1d7-e83c-494f-9b07-bae83f1009c1	c1	Kamlesh Paan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
f2dd2df1-cabc-4824-95f6-b06cccf1d87c	c1	Kamps International	Sundry Creditors	07APPPJ8709M1Z5	\N	0.00	Regular
d4949592-6385-4c0b-9943-9f91113ac83a	c1	KANAK RAJESHWARI ENTERPRISES	Sundry Debtors	\N	\N	49101.00	\N
d905faeb-209a-4a9e-8dac-478538d9c146	c1	Kanak Sweet	Sundry Debtors	\N	\N	0.00	\N
88928c9b-80ac-4133-8e4b-1717cd7d42b7	c1	Kanchan Sales	Sundry Creditors	\N	\N	0.00	Unregistered
bb2a9b9e-c558-435b-812c-f1a6ad145918	c1	Kangana Store	Sundry Debtors	\N	\N	0.00	Unregistered
3f702555-bcf7-4719-8dad-aa60d29f2082	c1	Kanhaiya and Sons	Sundry Debtors	09ACEPI5303C1Z5	\N	0.00	Regular
1a18c9c2-8add-43fa-a379-232bd022958e	c1	Kanodia DISTRIBUROS	Sundry Creditors	09AEIPK9718F1Z6	\N	0.00	Regular
9b45da49-8d87-428e-bdc1-d61dc154ff75	c1	Kanoi Hospitality Pvt Ltd	Sundry Debtors	27AAJCK2158H1ZE	\N	0.00	Regular
f096d85d-cda7-47d4-ad15-f2acbd874f4e	c1	Kanoi Plantations Pvt Ltd.	Amazon Debtors	19AABCK3128R1Z2	\N	0.00	Regular
d8a9f6b6-92d1-43cb-8bf6-363ea3412ca7	c1	KANPUR AGENCIES	Sundry Creditors	09BOKPK2046D1Z3	\N	0.00	Regular
445e7684-4ff8-4f3b-a472-ac310d3ab1dd	c1	Kanpur Food Court	Sundry Debtors	\N	\N	-1489.00	\N
63305595-adc0-4404-ad73-b77213f8e8f4	c1	KANPUR NAMKEEN BHANDAR	Sundry Debtors	09AOUPG7519L1Z5	\N	-16574.00	Regular
4111c87e-afb1-40b4-a83b-6d7d8d4fbbb7	c1	Kanpur Wheels	Sundry Creditors	09AHEPK4549F1Z9	\N	0.00	Regular
efa050a8-cf9f-4bee-aae2-880d4c9f4b32	c1	Kanta Watch	Sundry Debtors	\N	\N	0.00	Unregistered
77eb8198-6b92-4f4f-bc85-ec1e90665545	c1	Kanti Radio &amp; Electricals	Sundry Debtors	\N	\N	0.00	Unregistered
c90a49a7-11fc-4919-b7e3-372f3430a14e	c1	Kapil Store	Sundry Debtors	\N	\N	0.00	Unregistered
13caf0c8-915d-4ccf-988a-e9a1adbb74b4	c1	Kapoor Stationars	Sundry Debtors	09ABFPK9373E1ZE	\N	0.00	Regular
0ace667f-cbe8-436b-aaa6-19bf7bc80e78	c1	Kapoor Store	Sundry Debtors	\N	\N	0.00	Unregistered
106a9b44-44b3-4cda-9d6b-1145fb3c4c38	c1	Karan Store	Sundry Debtors	09ABNPC9793N1ZN	\N	0.00	Regular
f91bfb46-bf50-4513-8a91-ee85479bfe60	c1	Karan Traders	Sundry Debtors	\N	\N	0.00	Unregistered
ba1d6335-308f-4e99-ac95-dce6d98daaa6	c1	K AREY WAAH RESTAURANT	Sundry Debtors	09AANFK0329H2Z8	\N	0.00	Regular
e12b42ad-2f2c-4aff-97b7-2467cecfe845	c1	Karina Shatul Masand	Amazon Debtors	27AFFPM8050A1ZQ	\N	0.00	Regular
f0932dd1-ca2f-4dde-82e1-964e8dc577af	c1	Karni Impex	Sundry Creditors	07ABGPD4080J1ZR	\N	0.00	Regular
9d953e6a-1dfe-4e4e-bfae-a4e803818ac7	c1	Kart Foodz	Sundry Debtors	09ABXPB3566C1ZI	\N	0.00	Regular
03483d13-4188-42c6-a75e-d1f7ea1128e9	c1	Karunesh	Sundry Debtors	\N	\N	0.00	Unregistered
468b06ce-a81b-40de-acc0-b200198719f9	c1	Kashish Store	Sundry Debtors	\N	\N	0.00	Unregistered
d521f4e3-706c-49a3-b8d2-10afec1802dc	c1	Katha Store	Sundry Debtors	\N	\N	0.00	Unregistered
58a4ba8c-f768-46e9-81b6-a55329c7cdff	c1	Katiyar Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
e04029fe-1adc-41fc-b0f1-aef70298edfb	c1	Kausar Dates Factory	Sundry Debtors	\N	\N	0.00	\N
c4806736-8438-42e7-880c-9b2f8ecdf3a3	c1	Kaveri Store	Sundry Debtors	\N	\N	0.00	Unregistered
eab178fa-3736-43f9-9511-6aa18318438f	c1	Kavis Fashions Private Limited	Amazon Debtors	27AAACK9496R1ZF	\N	0.00	Regular
caf731bd-b9d1-4e7c-981f-2883b625502e	c1	Kavita Store	Sundry Debtors	\N	\N	-300.00	Unregistered
64dbe844-566e-47f4-969a-5f2ee6746895	c1	Kawality Biscuts &amp; Namkeen Store	Sundry Debtors	\N	\N	0.00	Unregistered
7a512945-beca-44d4-be38-15d50f8536f8	c1	Kawality Restrarent	Sundry Debtors	\N	\N	0.00	Unregistered
8f7dfef0-f5c4-453a-90e5-2c216dec5d67	c1	Kawality Stationers	Sundry Debtors	09AAPFK4118C1ZE	\N	0.00	Regular
cefcb586-5961-4af2-afdd-beed6bbea144	c1	Kawality Store	Sundry Debtors	09ABSPS6594A1Z0	\N	0.00	Regular
b4a0a017-e9b1-4579-b11f-f41a969aa74c	c1	Kawality Store(Lal Banglow)	Sundry Debtors	\N	\N	0.00	Unregistered
1bfaec32-aebb-4646-9fb8-2532936479ef	c1	Kawlity Biscuit &amp; General Store	Sundry Debtors	\N	\N	0.00	\N
5ad58dfa-1dc9-46aa-b2a5-03b5dfd4c953	c1	Kdc Tek Private Limited	Amazon Debtors	27AAICK1411C1Z3	\N	0.00	Regular
ec0a6b56-db3a-4579-b3a6-8f8920b3d9e6	c1	KDM Foods Private Limited	Sundry Debtors	09AAFCK4285P1ZR	\N	-18297.00	Regular
c70dd693-7880-48e4-9cd6-f84ad1fb926c	c1	KESRI GIFT EMPORIUM	Sundry Debtors	09ADUPK0249C1ZI	\N	0.00	Regular
3771bb9d-358f-4ddb-bc6d-99afc279a888	c1	K. G Corporation	Sundry Debtors	09AJZPA8937E1ZN	\N	0.00	Regular
7c9845a2-153a-4b55-bc00-c92c62a0a23d	c1	KHAJOOR GALLARY	Sundry Debtors	\N	\N	0.00	\N
56b57b09-c621-4874-a29d-1cc025522dbd	c1	Khajoor Gallry	Sundry Debtors	09APDPA7945N1ZG	\N	0.00	Regular
d17bfbc6-69eb-45b3-ba4a-eb25d50aa16f	c1	Khan&apos;s Store	Sundry Debtors	\N	\N	0.00	Unregistered
70736755-1579-49a0-ba12-f24f5583c3ce	c1	KHANDELWAL COMPUTOR &amp; STATIONERS	Sundry Debtors	09ADOPK9867G1ZQ	\N	0.00	Regular
d9929d35-0da5-42a1-9d0d-51a1d354c21a	c1	Khandelwal Stationary	Sundry Debtors	09AARPK4123H1ZK	\N	0.00	Regular
9318f1ae-9915-4349-b00c-dcc48d8396c9	c1	KHANNA AGENCIES...XX	Sundry Debtors	09AAKFK6295K1ZK	\N	0.00	Regular
ce54fbf5-5483-46ba-81bc-da82d98336ed	c1	Khanna Store	Sundry Debtors	\N	\N	0.00	Unregistered
7b251ec0-c97d-42dc-a348-e8792c05ce2f	c1	Khatta Meetha	Sundry Debtors	\N	\N	0.00	Unregistered
b4ae0745-32b6-498a-a119-89ccd32de682	c1	Khazana	Sundry Debtors	\N	\N	0.00	Unregistered
215aeea6-acef-40d9-831d-30b23a405b57	c1	Khyati Store	Sundry Debtors	\N	\N	0.00	Unregistered
fe988f17-7df9-4acf-b839-18408cd194db	c1	Kiara Foods	Sundry Creditors	27APXPB9809G1ZD	\N	0.00	Regular
a3babd8e-2de8-4d7c-89c5-9e5469f15b2b	c1	KINGS CHOICE	Sundry Debtors	09AOAPD3322C2ZP	\N	0.00	Regular
d857d8fe-c528-4f5b-b8ee-b6004c7e23c9	c1	Kings Store	Sundry Debtors	\N	\N	0.00	Unregistered
285621cb-b777-4118-b834-032d4215ed11	c1	KIPPS	Sundry Debtors	\N	\N	0.00	\N
004603b9-fdfb-49e0-a955-8d26b6d05d1e	c1	Kipps Super Market	Sundry Debtors	09AIWPK3235B1Z7	\N	30025.00	Regular
c288679d-bd34-4b89-9c55-6c518aa05eed	c1	Kiran Kashi	Amazon Debtors	29AKWPK7854J1Z3	\N	0.00	Regular
f7f5c69d-9b13-4a45-8d36-eb651b5f8a38	c1	Kishan Bros.	Sundry Debtors	\N	\N	0.00	Unregistered
73c7c9c7-58e6-45a8-977a-4c35706998a2	c1	KISHANCHAND NITIN GUPTA	Sundry Debtors	09AASFK1057H1Z1	\N	0.00	Regular
56282bb9-be7e-48c5-9a69-fd96beb25294	c1	K I T E India	Amazon Debtors	27BZXPP1261P1ZD	\N	0.00	Regular
f761b2ee-02c5-49e1-99d3-28a11660306a	c1	KITTY INDUSTRIES PRIVET LIMITED	Sundry Creditors	03AABCK7229B1Z2	\N	0.00	Regular
2903dc24-7d23-4616-b05a-484af775c84a	c1	K.K.S.K.TRADERS	Sundry Debtors	\N	\N	0.00	Unregistered
e7037222-b631-4efc-a493-017ae4e56f6b	c1	K L TRADERS	Sundry Creditors	09ACGPA0786R1Z3	\N	0.00	Regular
63114487-c964-47f6-842b-140db19380c1	c1	Kohli General Store	Sundry Debtors	09ASCPK8897R1ZG	\N	-4541.00	Regular
2aaf5a52-e0fa-42cb-bbdf-f120d1e8f5fb	c1	Komal Departmental Store	Sundry Debtors	\N	\N	0.00	Unregistered
23b41b55-25cd-437f-bd25-21b7f776c965	c1	KOTAK LOAN ACCOUNT	Secured Loans	\N	\N	0.00	Unregistered
41db7600-766b-45bf-9f9f-649b2f6034fd	c1	KOTAK MAHINDRA BANK	Bank Accounts	\N	\N	-30219.10	\N
2698ecd7-70e8-411c-ba34-8b0e794f9883	c1	KOTAK MAHINDRA BANK LIMITED	Sundry Creditors	\N	\N	15.36	\N
8ca4e296-ec47-4338-b5ae-b48cccfc3c2f	c1	Kreios Info Solutions	Amazon Debtors	07AAPFK2470D1ZD	\N	0.00	Regular
21e2ec07-2a91-4a45-981d-e1b6117a5b54	c1	KRIPA TRADERS	Sundry Creditors	09AATPH8294G1ZZ	\N	0.00	Regular
77080adc-c1a1-42e3-83f4-d6b5a8104eba	c1	Krishan Beverages	Sundry Creditors	09BTYPA7408Q1ZQ	\N	37506.00	Regular
c8f2bf0d-33f6-4f3b-9dd2-8b9a3a894dca	c1	Krishan Kumar Distributors Pvt Ltd	Sundry Creditors	09AABCK9711G1ZH	\N	0.00	Regular
73a72afb-f79f-4e93-b768-f0bb5dbb4899	c1	Krishna Agencies	Sundry Debtors	09AUBPA6112G1Z6	\N	0.00	Regular
563d8e49-3979-49c8-ab58-0cfb6faeada6	c1	Krishna Baikery	Sundry Debtors	\N	\N	0.00	Unregistered
1ba52768-74f6-4c85-bcce-903adcfb7ec2	c1	Krishna Electronics	Sundry Debtors	\N	\N	0.00	Unregistered
e748f677-a93d-4a5a-96e1-813d6d06f896	c1	Krishna Infory System	Sundry Creditors	\N	\N	0.00	\N
ab044be4-2cb1-40c5-9e46-168dddaf7d12	c1	Krishna Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
8c0ce9cf-6e8b-4531-a648-b856a120d26e	c1	Krishna Provesion	Sundry Debtors	\N	\N	0.00	Unregistered
0ea27505-458c-4818-98a6-90860fd39b9c	c1	Krishna Traders	Sundry Creditors	03AATFK9518Q1ZF	\N	0.00	Regular
655b253b-10a5-4875-80e0-ab25deff0533	c1	Kritika &amp; Sons	Sundry Debtors	09BBCPK3569C1ZQ	\N	0.00	Regular
669906a7-43d1-4704-904e-243635c9a00e	c1	KRV FOODS	Sundry Debtors	09AAXFK5425A1Z6	\N	0.00	Regular
7171b250-07e3-4ca0-8b06-c67020475979	c1	KRVM ( Z SQUARE)	Sundry Debtors	\N	\N	0.00	\N
ed2050be-3ac1-4d52-a51e-4a25a5b54d2d	c1	K.S. BROTHERS AGENCIES	Sundry Creditors	09AHFPG0775Q1ZT	\N	0.00	Regular
730c23d8-e2f4-4e7b-8476-8fa75447ea56	c1	K S Grinding Works	Amazon Debtors	36CIBPK1558A2ZO	\N	0.00	Regular
fc2975ea-ee45-4309-9b31-8d0a2feb62be	c1	KSN FOOD LLP (Paryagraj)	Sundry Debtors	\N	\N	300.00	\N
d3d78738-71d1-4e07-90b1-16aec58ba130	c1	KTL Private Limited	Sundry Creditors	\N	\N	0.00	\N
a322429f-026e-4c05-b1d6-7b8561f4b49d	c1	KTL PVT. LTD.	Sundry Debtors	09AAACK9621Q1ZW	\N	0.00	Regular
1f4ea412-b259-4083-8a45-6ab5ed074ade	c1	Kudrat Hotel Pvt.Ltd.	Sundry Debtors	09AACCK0583D1ZQ	\N	-11066.00	Regular
1ab8ae72-a17f-4e5b-b554-5640876960db	c1	Kudrat Hotel Pvt Ltd (Baikunthpur)	Sundry Debtors	09AACCK0583D2ZP	\N	0.00	Regular
82426990-7bd1-4891-b544-802cde0df4aa	c1	Kuldeep Watch House	Sundry Debtors	\N	\N	0.00	Unregistered
591e3b89-d797-4c5c-9071-624ba281cb4c	c1	Kuldeep Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
bed56b33-9aab-45df-8d61-39c362afb03d	c1	Kumar Bro&apos;s	Sundry Debtors	09AZYPS1998J1Z0	\N	0.00	Regular
3ed89d57-1712-43eb-a40a-273d0c094b46	c1	Kumar Chemist	Sundry Debtors	\N	\N	0.00	Unregistered
7d8ce0dc-adce-4cae-9938-b3f2beff93f8	c1	KUMAR ELECTRONICS	Sundry Debtors	09AAHFK1355P1ZU	\N	0.00	Regular
088286c6-7414-44dd-a3b8-ac1d91be4d76	c1	Kumar Fancy Store	Sundry Debtors	\N	\N	0.00	Unregistered
17f348c7-a4b3-4d9d-affd-6af8b54c620f	c1	Kumar General &amp; Telecom Center	Sundry Debtors	09AYAPK9905E1ZE	\N	-1551.00	Regular
9d2ffe97-764f-4713-88fc-c51777057633	c1	Kumar Medical &amp; General	Sundry Debtors	\N	\N	0.00	Unregistered
8f3632d4-95a6-4c1e-ade7-38247f7d1b76	c1	Kumar  Medical General Store	Sundry Debtors	\N	\N	0.00	Unregistered
5c7a9c8c-c663-43e3-b44d-710f39f22e03	c1	Kumar Medicos	Sundry Debtors	\N	\N	0.00	Unregistered
3e098a07-4cf2-457d-9aaf-a7511ba20133	c1	Kumra Bhatia &amp; Co.	Amazon Debtors	07AAEFK4747L1ZZ	\N	0.00	Regular
d2111b06-c69e-44f4-813d-32bb21877b44	c1	Kundan Lal &amp; Sons	Sundry Debtors	\N	\N	0.00	Unregistered
bc58a09e-9ada-4f11-bdc4-c7069fb4a49e	c1	KUNJILAL DALSEV WALE (ALIGARH)	Sundry Debtors	\N	\N	-25959.00	\N
60df06d8-9a35-480f-9eef-d32da7ed079c	c1	Kwality Milk Products	Sundry Creditors	07BOYPP1041P1Z6	\N	0.00	Regular
4008521d-a7f7-4832-9e61-34b89dcb46fc	c1	Lakshya Sweets	Amazon Debtors	06BTDPR7367G1ZB	\N	0.00	Regular
84716c24-2170-4f6e-8d27-1865209c6403	c1	LALA RAM CHANDRA GUPTA &amp; SONS	Sundry Debtors	09AAHFL9358B1Z3	\N	0.00	Regular
d9bb0860-d64a-4aaf-8fb6-44ad8f45f47a	c1	LALA VYAPARIMAL &amp; SONS	Sundry Debtors	09ADWPK1371M1ZU	\N	0.00	Regular
2b3727a6-5811-460e-908c-f7247ae700cb	c1	Lala Vyoparimal &amp; Sons	Sundry Debtors	\N	\N	0.00	Unregistered
5ab93cbf-45dc-4681-8185-9b372e039ed1	c1	LAL ELECTRICALS &amp; PAINTS	Sundry Debtors	09AVZPK5829R1Z5	\N	0.00	Regular
3f32c25f-4574-444d-9e60-8af411c947b7	c1	Lalita Store	Sundry Debtors	\N	\N	0.00	Unregistered
3054a17d-4e37-4ea8-8bf0-a1c893ac0560	c1	LALLU MALLU PANSARI	Sundry Debtors	09AFXPG9507N1ZH	\N	-1800.00	Regular
a39677d6-5284-4488-be63-f5718099d873	c1	Lata Electrical and Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
fac70201-cb84-4801-94aa-bd3d6efa1f56	c1	Latika&apos;s  Thalia	Sundry Debtors	09AGPPR6113G1Z3	\N	-33972.00	Regular
1af99cc8-0bed-4fd0-b4e9-4c2b6e2d7302	c1	Laxman DAS	Sundry Creditors	\N	\N	0.00	Unregistered
ea7a8ebc-fb64-4731-8141-1f91400d1841	c1	LAXMI ELECTRIC COMPANY	Sundry Creditors	09ABNPS6537L1ZR	\N	0.00	Regular
20cf0758-efe5-4413-a392-6985f96a430d	c1	Laxmi Kirana Store	Sundry Debtors	\N	\N	0.00	\N
8d1590e0-53fc-42e9-af16-af359c4bc37b	c1	LAXMI STORE	Sundry Debtors	\N	\N	0.00	Unregistered
61f09fbc-82f9-46c3-b8f2-ba3143f798ef	c1	Laxmi Tea Stall	Sundry Debtors	\N	\N	0.00	Unregistered
1b6ae2b8-cd48-4924-a03b-02e9ae1d9089	c1	Laxmi Traders	Sundry Creditors	09BHPPK0927D1ZB	\N	25701.00	Regular
3437f298-fb99-4ddd-badb-4a465ebf7dd9	c1	Laxon Drugs Private Limited	Amazon Debtors	06AAACL2505Q1ZG	\N	0.00	Regular
a135e919-c4a3-49e1-be9a-da90e7c2fec9	c1	L Comps and Impex Private Limited	Sundry Creditors	07AAACL9923A1ZR	\N	0.00	Regular
68737fa0-c68b-4907-8c13-506d9ce265f4	c1	Leer Chem India Pvt.Ltd.	Sundry Debtors	09AADCL3395F1ZC	\N	0.00	Regular
ce6a88b7-56a6-48ac-b65f-5a61c1ae9e55	c1	Liabilities No Longer Required to Pay	Indirect Incomes	\N	\N	0.00	\N
a03f3afc-4530-423b-a631-69de8a9aa4d1	c1	LIMIT LESS RETAILS LLP	Sundry Debtors	09AAIFL6231C1ZI	\N	0.00	Regular
90121914-e060-49bc-b703-775c58a27c83	c1	Link Mart	Sundry Debtors	09AHEPU3512A1ZO	\N	0.00	Regular
567590ce-5a62-40ea-9ffa-845b3eeddb67	c1	Link Overcies Co.	Sundry Creditors	\N	\N	0.00	Unregistered
e898a3cb-fc88-4cef-8f33-e2e97d9dd108	c1	Listing Fees Amazon	Indirect Expenses	\N	\N	0.00	\N
c5f3d2b3-aead-475c-a352-09230d7773a8	c1	Litco	Sundry Debtors	\N	\N	0.00	Unregistered
f06e58a2-3c9c-4b77-8869-4b27b06ee346	c1	LITTLE MART	Sundry Debtors	09ATYPV8721G1ZP	\N	0.00	Regular
91203559-c037-4102-854a-6771d2c96c9f	c1	Live On Stage Entertainment Private Limited	Amazon Debtors	27AACCL4714B1ZY	\N	0.00	Regular
cc36c507-a4f5-4942-bccd-f6ce47dd2ae3	c1	Loading and Unloading Charges	Direct Expenses	\N	\N	0.00	\N
62b86ae6-07da-403d-b012-5a6c9b2f03e7	c1	Local Freight	Indirect Expenses	\N	\N	0.00	\N
196a84f1-e8ca-4370-abcc-9bfb4ccb7d46	c1	Lopa Verma &amp; Associates	Amazon Debtors	07AADFL7600A1ZW	\N	0.00	Regular
d07b5228-3b1b-4529-8485-5bef96e774e1	c1	Lory Radio &amp; Loudspeaker Agency	Sundry Debtors	09BYXPS1009R1ZC	\N	0.00	Regular
85bb70e9-bf20-4be2-b478-8823a0b5bacb	c1	Lounge Luxurio Trading Corporation	Sundry Creditors	09CBDPJ8540C2ZR	\N	0.00	Regular
cc9985d9-b15e-43dc-85f9-c3c6782fe0b0	c1	Love Guru Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
fb03e2c5-5630-48e2-8889-97791f0ffcac	c1	Lovely Store	Sundry Debtors	\N	\N	0.00	Unregistered
9957e4d0-5e5c-46b5-a1a9-66d583695da0	c1	Lucknow Sales Co.	Sundry Creditors	09BGZPM4836N1Z8	\N	0.00	Regular
1b7ce3fb-4b8f-4bd4-85ff-c6ebdff08ba1	c1	LUCY GIFT HOUSE	Sundry Debtors	\N	\N	0.00	Unregistered
723ede46-7912-4853-afd4-cfe0128ea1b2	c1	Luxmi Bakery	Sundry Debtors	\N	\N	0.00	\N
a299e29e-f727-48dd-ad0a-2420ebeb51aa	c1	Luxor Nano Technology Pvt. Ltd	Sundry Creditors	\N	\N	0.00	Unregistered
b91240fb-5470-498e-883f-b74284090a8c	c1	MAA BHAGWATI AGENCIES	Sundry Creditors	09AFBPK1115N1ZJ	\N	0.00	Regular
da673f5b-a21a-4395-adba-bd38bbf5c08a	c1	Maa Bhagwati Chemist	Sundry Creditors	09ABEFM8774C1ZZ	\N	0.00	Regular
7ac52619-5910-4e05-b34d-aa71b176306e	c1	Maa Chandrica Enterprises	Sundry Creditors	09AEOPP8875Q1Z0	\N	0.00	Regular
9bfdf936-7fe9-435e-b1bb-7dba8a07e246	c1	MAA DURGA	Sundry Debtors	\N	\N	0.00	Unregistered
da84c31e-5118-4ef1-817f-ebe962bdaecc	c1	MAA DURGA TRADERS	Sundry Debtors	09BJOPG5044A1ZF	\N	-14400.00	Regular
893c18ae-140d-47a0-b841-ac09f271357f	c1	Maa Sri Textile	Amazon Debtors	08CTEPG3556N1ZA	\N	0.00	Regular
a6c69301-2f3e-4640-984c-c7ae4375fa73	c1	Maa Vaishno Foods	Sundry Debtors	09ABJFM8543J1ZO	\N	0.00	Regular
85f5776a-24d2-4da0-9e3a-29da9efd155b	c1	Maa Vendor	Sundry Debtors	09EGHPS8437Q1Z6	\N	0.00	Regular
fd0581d3-1869-45c9-a667-1f7a5f005a1c	c1	Madhani&apos;s Traders &amp; Suppliers	Sundry Debtors	\N	\N	0.00	Unregistered
b5b9e798-7b49-46d9-a4fd-21f05c95a79c	c1	Madhulika Restaurants LLP	Sundry Debtors	\N	\N	0.00	Unregistered
6d546881-e3fc-4c5d-82af-07f30bb02d1c	c1	Madhur Textiles	Sundry Debtors	09ATLPK0053F1ZU	\N	0.00	Regular
61ad677f-e4ce-4ecb-a6bf-3cff5abd0198	c1	Mahadev Computers	Sundry Debtors	09AQAPS9322D1ZT	\N	0.00	Regular
56dacf2b-3725-4f31-9d46-d9d41bc030c7	c1	Mahalaxmi Store	Sundry Debtors	09AAPPP4492E1Z7	\N	0.00	Regular
f11919e4-fab6-4f95-a4eb-734e82a9bb8f	c1	Maharaja Departmental Store	Sundry Debtors	09ABKPK7258B1ZJ	\N	0.00	Regular
8faf54ea-243e-4da3-b11b-ea3b8a26017b	c1	Maharaja Super Market	Sundry Debtors	09BBWPS6518P1ZC	\N	0.00	Regular
d9e3349e-efad-4e85-b054-da8a21fe45f7	c1	Mahaveer Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
d266a277-2349-49fa-be6b-2d172b813023	c1	Mahaveer Store	Sundry Debtors	\N	\N	0.00	Unregistered
35751c37-ad43-4b90-9a5e-b80d0d87f901	c1	Mahavir Textile	Sundry Debtors	09AAZPG6467C1Z7	\N	0.00	Regular
fef068a6-e07a-4aef-80f6-63fbbce13148	c1	MAHBOOB ALAM STORE	Sundry Debtors	09CFRPA2415M1Z8	\N	0.00	Regular
ad6342e6-9544-4138-bc0f-455c03064c26	c1	MAHESH GENERAL STORE	Sundry Debtors	\N	\N	0.00	Unregistered
8b1c5ebe-7bf4-4eae-9eff-45119906084f	c1	MAHESH KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
2fc38e40-9e18-4924-b48e-1b028d980f65	c1	Mahesh Mansarovar Sweet	Sundry Debtors	\N	\N	0.00	\N
b9cc8ee5-bd40-4986-83ac-a6be9553eed2	c1	Mahesh Store -GR-D-P	Sundry Debtors	09ADTPT2963M1ZG	\N	0.00	Regular
c85e37e5-912d-4723-bffe-180468f84545	c1	MAHESHWARI STORE	Sundry Debtors	09AGYPM8416G1ZP	\N	0.00	Regular
56213f17-9c30-4ec1-8b51-b240032de278	c1	Maheshwari Traders	Sundry Creditors	09AQEPM7450Q1Z3	\N	0.00	Regular
279a272d-0ab9-4cc5-85ed-81ff8eddac96	c1	Mahes Store	Sundry Debtors	\N	\N	0.00	Unregistered
5f847852-13fe-4ba9-801c-13bd2af007b8	c1	Mahima Traders	Sundry Debtors	\N	\N	0.00	Unregistered
ba9e9c7f-e296-49f9-b8ae-ababccae2727	c1	Mahir General Store	Sundry Debtors	09ACZPA2155M1Z3	\N	0.00	Regular
647828d5-2013-4e68-8f5d-4c306ab0dac7	c1	Malik Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
ff7a8113-151e-49fe-a5b4-e897637a48e7	c1	Manas Paras Bhagtani	Sundry Debtors	09CBKPB0144F1Z3	\N	0.00	Regular
e8a22be2-7840-4a2b-9a51-f7ce3ddcbb49	c1	Mangla Apparels India Pvt. Ltd.	Sundry Debtors	09AAFCM0070J1ZI	\N	0.00	Regular
1468ea83-b894-40af-b7b5-b368c56f187b	c1	Manglam Fresh	Sundry Debtors	\N	\N	0.00	Unregistered
40f55ef8-f4e5-4ae0-a51f-9d34a3a0d5a5	c1	Mangla Redimix Pvt Ltd	Amazon Debtors	06AAFCM1490C1ZT	\N	0.00	Regular
8bc5a50b-6787-4e61-981e-c89d412840a8	c1	MANIA HOSPITALITY PVT. LTD.	Sundry Debtors	\N	\N	0.00	\N
73cbcfd6-538b-4eb3-b83b-c5b69c872ab6	c1	Manish Enterprises	Sundry Creditors	\N	\N	0.00	\N
0367bd55-8f15-4387-a400-7f51c605ebc6	c1	Manish Mehrotra	Sundry Debtors	\N	\N	0.00	Unregistered
295b4dd0-773b-4bb4-bfa7-2230729294a3	c1	Manish Store	Sundry Debtors	\N	\N	-1227.00	Unregistered
209b7abe-aaed-4f3c-933d-6ac0981c671f	c1	Manish Traders	Sundry Debtors	\N	\N	0.00	Unregistered
0843efb7-390b-400a-bc89-9e218622da62	c1	Manjeet Singh	Sundry Debtors	\N	\N	0.00	Unregistered
722a1d06-149d-4aad-9bd0-ff938db11282	c1	Manohar &amp; Co.	Sundry Debtors	09AKVPG6678H1ZB	\N	0.00	Regular
21ebebed-2d74-4aea-b034-161ba55a1897	c1	MANOHAR &amp; LAXMAN AGENCY	Sundry Creditors	09AHUPA0685J1ZX	\N	0.00	Regular
6e604b7a-0cad-4377-9832-3e04046e21fa	c1	Manoj Pan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
d91be624-467a-4ded-8538-704adeeb09c5	c1	Manoj Store	Sundry Debtors	\N	\N	0.00	Unregistered
15fdbe95-47b4-419a-8f68-cfde9d1cda11	c1	Manorma Enterprises	Sundry Debtors	07BHTPS5312N1ZL	\N	0.00	Regular
1a1ffa93-a5ab-4e6e-8b9b-482d13933f7a	c1	Manorma Store	Sundry Debtors	\N	\N	0.00	Unregistered
9253e365-27cb-4de2-8938-652eee4e3845	c1	Manpower	Indirect Incomes	\N	\N	0.00	\N
758bb79e-faf6-4081-8463-1c931656270c	c1	Manpreet (Lucknow)	Sundry Debtors	\N	\N	-57.00	\N
98da1ef6-63d0-4a33-9a74-6b25d2efb948	c1	MANU BHAI	Sundry Debtors	\N	\N	0.00	Unregistered
c5eaf909-5c4b-4cae-a0fb-0fd571843475	c1	Mapleleaf Epicurea Pvt.Ltd.(Branch)	Sundry Creditors	07AAACM3213C1Z7	\N	0.00	Regular
62d8db4b-1105-40cd-bfc1-e892562cc4c4	c1	Markowate Technologies Private Limited	Amazon Debtors	06AALCM5460A1ZP	\N	0.00	Regular
f8f27771-b1ec-467b-9ad7-713682bacb7d	c1	Mars Refrigeration / Swastik Systems	Amazon Debtors	27ABYPS0629J1ZX	\N	0.00	Regular
ca67047b-64e6-4554-b71f-5f686f6de43a	c1	Ma Shitla General Store	Sundry Debtors	09AHCPA4836H1ZJ	\N	0.00	Regular
c2de493f-d0d9-4848-9c4c-a11e782a594b	c1	Matrika Foods (Lucknow)	Sundry Debtors	\N	\N	-20032.00	\N
037a0f47-ec78-4ead-9138-2eb381559c13	c1	Maverick Foods	Sundry Creditors	07AAQFM1447H1Z3	\N	0.00	Regular
062d941f-631e-41c5-bb5b-34f0bbee6ec4	c1	MAX INC.	Sundry Creditors	07AACPL1631J1ZY	\N	0.00	Regular
c8b97f20-6746-4126-b946-c0d07b062472	c1	Mayank Agencies (2019-20)	Sundry Creditors	09BAKPS8246M1ZR	\N	0.00	Regular
27397262-5f73-460b-bf8d-a9c6c953eeb8	c1	Mayank Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
6e2dd5f4-fae5-4996-8f05-4a55d323ab68	c1	Mayank.....Xx	Sundry Debtors	\N	\N	0.00	Unregistered
7cd670eb-d4b1-4ad2-b0c9-a9d1b38e2cfe	c1	Mayavid Online LLP	Amazon Debtors	27ABIFM9991R1ZX	\N	0.00	Regular
476645b1-2352-4e38-bcbc-51c2d4199001	c1	Mayfirst Corporation	Amazon Debtors	07ABAPS6694R1ZM	\N	0.00	Regular
30e2075d-2d9c-4b46-b714-faaf37ebc9ee	c1	MCS DEVLOPERS	Sundry Debtors	09AAMFM5328H1ZZ	\N	0.00	Regular
cd797ad4-fdcd-46e6-b4ca-547aab07bade	c1	MCS F AND B PRIVATE LIMITED	Sundry Debtors	09AAHCB7412R1Z3	\N	0.00	Regular
f8d4b0a4-b6df-4656-8057-259b415d8896	c1	MCS Honda	Sundry Debtors	\N	\N	0.00	Unregistered
a547ca1c-558e-4b6a-bccc-220aaeb89d3d	c1	MCS SPIRITIS PVT LTD	Sundry Debtors	09AAZCS8146D1ZO	\N	-15479.00	Regular
9790738d-fc5e-4809-b5b5-4d087180df62	c1	Meena Foods	Sundry Debtors	09AARFN8939L1Z5	\N	0.00	Regular
a65ed956-ea0f-44a8-b3af-827deff6d615	c1	Meenu Store	Sundry Debtors	\N	\N	0.00	Unregistered
8325ded2-3815-4335-b6eb-fc75ea16f81f	c1	Mega Basket	Sundry Debtors	09AADCB0064F1Z2	\N	0.00	Regular
59ad8df4-aa48-4782-8a15-e92fb71e5ac9	c1	MEGA STORE-APNA BAZAR	Sundry Debtors	09BFIPB8087G2Z5	\N	0.00	Regular
0e505757-d4a2-4f9c-a149-e9cd8305806e	c1	MEGHA MEDICAL	Sundry Debtors	09BDFPK7722Q1ZV	\N	0.00	Regular
cb9b4dbf-b6b2-40a1-b027-ba8ff3eda10e	c1	Megha Store	Sundry Debtors	\N	\N	0.00	Unregistered
3d0bd525-93fa-43ed-81fe-e2e9a3010695	c1	MEHAR BABA PROVISION STORE	Sundry Debtors	09AALPN8307J1Z8	\N	0.00	Regular
05c0afc5-5402-4204-8b75-30fc2083cf2d	c1	Mehta Store	Sundry Debtors	\N	\N	0.00	Unregistered
b6440276-f222-43bd-9c70-518a53a55461	c1	Mellow  Bakers	Sundry Debtors	\N	\N	0.00	\N
c7e1cd53-cd85-40c8-9d1e-debe91dc15a4	c1	MELT SHAKE &amp; JUICE	Sundry Debtors	\N	\N	0.00	Unregistered
3e34584a-20dc-4465-823d-478e5f7e1fba	c1	MERRY FOOD	Sundry Creditors	09ABCPT1123A2Z7	\N	0.00	Regular
9b3cb3c4-ff2d-461c-a2eb-1f15be602c14	c1	Metro Essence Mart	Sundry Debtors	09AAFPT5517N1Z2	\N	0.00	Regular
8d642fc7-97bf-4833-9503-dfbc9d5ff2cf	c1	Metro Medicals	Sundry Debtors	\N	\N	0.00	Unregistered
a85f9435-4c90-44aa-be02-fe6514054f31	c1	Miglani Traders	Amazon Debtors	09AIZPM2504L1ZN	\N	0.00	Regular
ca7637d1-4ca4-4eda-bed2-f99d52dd1e7b	c1	Mihir	Sundry Debtors	\N	\N	0.00	Unregistered
ad5543e6-176a-4083-9d32-c1563fcbb107	c1	MI International	Sundry Debtors	09AMYPN4083A1ZO	\N	0.00	Regular
2cc6a96a-79be-474f-b307-7b885dbde89d	c1	Mikky Shop	Sundry Debtors	09ABLPJ9016D2ZM	\N	0.00	Regular
a1fd89af-d708-4031-9e47-915bcef270dd	c1	Mini Bazaar	Sundry Debtors	09ABFPW5213K2Z9	\N	0.00	Regular
b601fae0-3869-43d2-a762-bd6e259582d5	c1	Mini Store	Sundry Debtors	\N	\N	0.00	Unregistered
1eb2322c-710b-4fb0-8d1c-3be33f9972ce	c1	MIOMBO	Sundry Debtors	09BAZPM6546F1ZY	\N	0.00	Regular
ad25bb75-e344-472f-a947-047c6f22c3f2	c1	Misc Exp.	Indirect Expenses	\N	\N	0.00	\N
d37145c5-c37b-43e5-8885-c711155df4d2	c1	Misc. Income	Indirect Incomes	\N	\N	0.00	\N
13237a63-8d73-4bcb-8027-67d92ddc365b	c1	Mishra Departmental Store	Sundry Debtors	\N	\N	0.00	Unregistered
71de3c79-de2c-4f68-b16e-fdc4cd28a14a	c1	Misra Agencies	Sundry Debtors	\N	\N	0.00	Unregistered
40b558c8-6fda-482b-95fe-302a13db9bb3	c1	Mithai Gosai Bhandar	Sundry Debtors	\N	\N	0.00	Unregistered
2cbda7a0-aa29-4000-b60e-6365327a8592	c1	Mithas Foods Pvt. Ltd	Sundry Debtors	\N	\N	0.00	\N
fddd5dca-8173-454c-80da-cfbde55a9b89	c1	Mitra Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
ec0babc7-916b-412e-b631-c9ab5f8decef	c1	Mittal General Store	Sundry Debtors	\N	\N	0.00	Unregistered
960cd3fa-070e-4fa3-b050-8181df5aa18b	c1	Mittal Sales Corporation	Sundry Debtors	09AYGPG8674G2ZZ	\N	0.00	Regular
cce07f14-3ed7-42c8-b476-ec5d828b6c25	c1	M K Hotels &amp; Resorts Ltd	Amazon Debtors	03AABCM0913G1Z5	\N	0.00	Regular
b02fc282-2085-49b3-b5c8-a1a1626e2cfc	c1	MOBILE	Fixed Assets	\N	\N	-23032.71	\N
e18229b8-1310-4b7b-b57c-b166c96126fd	c1	Mobile Wala	Sundry Creditors	09AKAPB2048P1Z4	\N	0.00	Regular
d6df9c47-1250-43e5-b73c-43865154433b	c1	MODEL BAKERY PVT. LTD	Sundry Debtors	\N	\N	0.00	\N
2d603989-32bf-4e41-b564-63bc22f7f815	c1	Modell Coffee Cornor	Sundry Debtors	09ACIPK9638G1Z5	\N	-13757.00	Regular
500398d1-3981-4eef-9010-3c734e1025b0	c1	MODERN CONFACTIONERY	Sundry Debtors	\N	\N	0.00	Unregistered
2f7f0d5c-b480-427f-ab6c-74dec88c2883	c1	Modern Enterprises	Sundry Creditors	09AETPG4367H1Z0	\N	0.00	Regular
7704fd38-47e4-4ae7-98ef-d3fd7e633f73	c1	Modern Shop	Sundry Debtors	\N	\N	0.00	Unregistered
ce5cdd37-e5ef-4f33-88ce-2096478e50c9	c1	Modern Store	Sundry Debtors	09AHFPV7176C1ZY	\N	0.00	Regular
f9750e75-e8ca-4b93-9495-fc4aba0f356b	c1	Modern Top Shop	Sundry Debtors	09BGNPS3969Q1Z0	\N	0.00	Regular
cc387202-869c-4710-bf11-e03fb0aad8cb	c1	Mohan Fancy	Sundry Debtors	09AATPL9291P1ZD	\N	0.00	Regular
65831e88-49dd-4cc4-be94-9843d49edc57	c1	Mohan Fancy Store	Sundry Debtors	09AAPPL8830Q1ZO	\N	0.00	Regular
be2cdfb3-8d37-43d6-836e-403d94ecb335	c1	Mohan Lal Store	Sundry Debtors	\N	\N	0.00	Unregistered
4fbe8aab-4008-4aa5-99c6-05e4d5eed94e	c1	Mohan Store	Sundry Debtors	\N	\N	0.00	Unregistered
ec37516a-bb2b-4593-96ae-5f45a9d489d8	c1	Mohd.Sufian Mohd.Salman	Sundry Debtors	\N	\N	0.00	Unregistered
e9b9000d-9ad1-4031-9eb3-514a8e9611bd	c1	Mohit Ahuja	Sundry Debtors	\N	\N	0.00	Unregistered
380a8166-d9cd-43d0-bee8-7c265f0598a0	c1	MOHIT CORNOR	Sundry Debtors	\N	\N	-1500.00	\N
a5126b5f-af35-44e4-8191-faaf317ba07d	c1	MOHIT GENERAL STORE	Sundry Debtors	\N	\N	0.00	Unregistered
3092d359-83ed-4ae0-84b1-5d8f7494f3ec	c1	Moldura Tech Private Limited	Sundry Debtors	\N	\N	0.00	\N
5a741247-8d7b-4b13-afbe-3ebc530985e8	c1	Mommy&apos;s Kitchen	Sundry Debtors	\N	\N	0.00	Unregistered
4991a95f-3a1c-4098-98c6-b5a12f343ab9	c1	Mommy&apos;s Kitchen (Bengaluru)	Sundry Debtors	\N	\N	0.00	Unregistered
fba88e1b-ebc4-4034-b523-ecd099d98912	c1	Mommy&apos;s Kitchen (Kolkata)	Sundry Debtors	\N	\N	0.00	Unregistered
6f2c2555-32c8-4c00-9808-c71293ee75cf	c1	Mommy&apos;s Kitchen (Mumbai)	Sundry Debtors	\N	\N	0.00	Unregistered
792c1e1a-2b63-40a9-bcf4-4ee4fef42182	c1	MONIN SANGARIA	Sundry Creditors	\N	\N	0.00	Unregistered
bf11842b-9081-4ca5-a313-2fb96a128609	c1	MONIN TIRAMISU 700 ML	Sundry Creditors	\N	\N	0.00	Unregistered
b61e0c62-4937-4267-b1f1-480f5f341657	c1	MONITA TECHNO FOOD (INDIA) PVT LTD	Sundry Creditors	24AAPCM2310R1Z5	\N	0.00	Regular
80efcc79-f382-4fc0-be1a-29778c08a149	c1	Monkey Chaurasia	Sundry Debtors	\N	\N	0.00	Unregistered
234c50fb-dc54-425d-b138-2ea2f5444b5b	c1	Moon Rise Productions	Amazon Debtors	09AARFM1634K1ZU	\N	0.00	Regular
7e4f74b3-e363-4845-9780-12bcc9e5cff8	c1	M PSales Dezzerts	Sundry Debtors	\N	\N	0.00	Unregistered
d66534aa-8b08-48f6-8476-3fc99b504ee3	c1	M P Traders	Sundry Creditors	\N	\N	117957.00	\N
f8bbeee8-e55f-4df8-b437-4e0c5bd2b66c	c1	MRK Foods Private Limited	Sundry Creditors	07AAGCM6925R1ZP	\N	0.00	Regular
6cc9d7c9-6d39-4ae1-8201-c484f3dd307c	c1	M.R.K. FOODS PVT LTD	Sundry Creditors	19AAGCM6925R1ZK	\N	0.00	Regular
bce2766d-a791-4cc7-976d-56310e172cb0	c1	Mrs. Seth	Sundry Debtors	\N	\N	0.00	Unregistered
3e74ba73-b5b9-4542-aa3b-79d13d490f2c	c1	M/s 1856 Monda World	Sundry Debtors	09DZOPMS5700B1Z	\N	0.00	Regular
7d2b35af-07d0-43bc-8c2a-cdef84fa0f29	c1	M/s AGARWAL STORE N	Sundry Debtors	09AQKPA5586H1ZJ	\N	-3908.00	Regular
53a1ec17-5960-430b-bf4c-a0184bbf0493	c1	M/s Ashutosh Enterprises	Sundry Debtors	09BNUPS4336P1ZT	\N	0.00	Regular
11cda560-c6e1-4042-940e-20b5302cc85e	c1	M/S Bahu Enterprises	Amazon Debtors	01BEZPS4289D1Z0	\N	0.00	Regular
9eaf9251-1f81-4d5a-8786-f5c0c608851f	c1	M/S Danish &amp; Company	Sundry Debtors	09AHZPK0185C1Z2	\N	0.00	Regular
d2ac49ef-7dbf-434e-a3de-093da05abc48	c1	M/s Fusion Enterprises	Sundry Debtors	09CAMPG8390M1ZV	\N	0.00	Regular
1356e9b6-5633-4044-911a-d3f40727c843	c1	M/s Getwell Pharmacy	Sundry Debtors	\N	\N	-1632.00	\N
948e84f9-f16a-4b48-abe7-5f27afd6691b	c1	M/S GIRNAR AGENCIES	Sundry Debtors	\N	\N	0.00	\N
7e6f83c9-9641-4381-ae20-3288cbc5bed5	c1	M/s Gnosch Foods Private Limited	Sundry Creditors	07AAHCG1269K1ZD	\N	0.00	Regular
675487bb-063c-4463-bb18-335f72208260	c1	M/S Gupta Sons Sales Depot	Sundry Debtors	09ACEPG0089K1ZH	\N	0.00	Regular
4ed54e7c-0972-49f6-be7f-064a1affdd8d	c1	M/S G Vegetarian Caterers	Sundry Debtors	09ARPPS3739N1ZQ	\N	0.00	Regular
5ce37a46-0697-4ff1-9c76-fbcdd74a3c22	c1	M/S Hari Foods &amp; Catters	Sundry Debtors	09ANAPM4791K1ZJ	\N	45000.00	Regular
0e238817-cf62-4f1a-8c2e-abd048dc165e	c1	M/S INDUSAJANTA PRIVATE LIMITED	Sundry Debtors	\N	\N	0.00	\N
a080e83f-3f5a-4a47-8306-e1d32ad63581	c1	M/s Jai Shree And Co.	Sundry Creditors	09AXLPP4956E1ZZ	\N	0.00	Regular
0cce644d-2dae-46a3-accb-67736d18f816	c1	M/S JAPAN RADIO &amp; ELECTRIC CO.	Sundry Debtors	09CGQPD4490R2ZE	\N	0.00	Regular
8f152263-7f66-440f-b5c4-27c26440e5e5	c1	M/s KHANDELWAL FOOD PRODUCTS	Sundry Creditors	09ADCPK5760A1ZU	\N	112739.00	Regular
a22ad5b3-8662-4135-b880-9154c06e0de4	c1	M/S Khanna Agencies	Sundry Debtors	09AGZPK0157H1ZY	\N	0.00	Regular
5b8aa147-17ed-4f37-9ea0-b87540ac7747	c1	M/S Manohar Trading Company	Sundry Creditors	09ANYPS0768E1Z9	\N	0.00	Regular
23a93302-c710-4f91-9b2c-7b57decd9918	c1	M/S NARAIN DAS &amp; SONS	Sundry Debtors	\N	\N	-40288.00	\N
691e83a4-2164-40a0-b4c3-bfe9ad756231	c1	M/s Nayra Food Factory	Sundry Debtors	\N	\N	0.00	\N
a8a67ee8-eb65-4c57-ba56-b86e134a7937	c1	M/S Northern Auto Sales	Sundry Debtors	\N	\N	0.00	\N
514a90cf-341c-48ae-bf33-242e89747116	c1	M/S NOVA CONFECTIONARY &amp;GENERAL STORE	Sundry Debtors	09AHSPA6322L1Z1	\N	-464.00	Regular
68986e41-0a0f-4d54-98bb-8c8a3b3e4760	c1	M/s Rahul Sweets &amp; Namkeen	Sundry Debtors	\N	\N	0.00	\N
8589f2c5-3f97-4db7-8724-73a2015af278	c1	M/S RAHUL TRADERS	Sundry Debtors	09AOTPS1808M1Z4	\N	0.00	Regular
b3b2111e-af14-4512-abb8-5774ac9897c3	c1	M/s RG SALES GT (SS)	Sundry Creditors	07AIRPG4946L1ZN	\N	0.00	Regular
376ae86a-a2d8-4093-a9cf-734cb532da59	c1	M/S RISHI TRADERS	Sundry Creditors	09ADPPA9732P1ZS	\N	0.00	Regular
c8de6c90-a100-416d-b9a9-00a391000c7a	c1	M/S. R.V. TRADERS	Sundry Creditors	09BDOPS8693H2ZG	\N	0.00	Regular
d414d502-962c-4736-a4ab-85a78d75e8e0	c1	M/s Savitri Traders	Sundry Debtors	09ABAFS2035E1ZJ	\N	-9397.00	Regular
a84be186-4843-4281-adc7-b18db9d81594	c1	M/s Seven Ten Store	Sundry Debtors	09ADZFS7013F1ZK	\N	0.00	Regular
28e50d08-fe06-4618-93bf-bac291f55e25	c1	M/s Shagun Enterprises	Amazon Debtors	09AFTPD0276M1ZY	\N	0.00	Regular
c86a7912-d485-40c9-8bcf-68f86dcb5c46	c1	M/s Shree Somnath Trading Company	Sundry Debtors	09AHJPL1686P1ZI	\N	0.00	Regular
47e2f7ab-f9ab-4f25-b8a5-509247731c90	c1	M/s Shri Maruti Enterprises	Sundry Debtors	09FCSPS3392L1ZG	\N	0.00	Regular
2029812f-dc4f-4308-8ece-032cc350f0e4	c1	M/S Shyam Ji Traders	Amazon Debtors	06BELPN8592L1ZM	\N	0.00	Regular
6c1c5ac5-70a5-49c4-9445-6054edb05951	c1	M/s Swadeshi Agro Products	Sundry Creditors	09ALOPK8992N1ZU	\N	12528.00	Regular
ac3533ec-b6e3-49f7-90e3-c9fb683f909a	c1	M/s The Bharat Hospitality	Sundry Debtors	09AAZPT4570B1Z4	\N	1141.00	Regular
5fd33fc7-4834-49dd-ad10-00b44955d6fb	c1	M.S. TRADERS	Sundry Creditors	09AATPG7495G1ZZ	\N	0.00	Regular
0947e436-0f1d-4ecc-b616-27423735272d	c1	M/S V Krishna Kumar	Sundry Debtors	09AAMPJ1170C1ZZ	\N	0.00	Regular
cb5dc74b-caa1-4d68-943b-763920513312	c1	M/s Wazwan Foods	Sundry Debtors	09ANQPG9337H1ZG	\N	0.00	Regular
33e8cae5-3f68-4a03-b378-b112241e1411	c1	Muhavra Enterprises Private Limited	Sundry Creditors	06AAICM1839L2Z5	\N	50187.00	Regular
370809e5-6e1e-4faf-9cd1-fe1ea3e2b3df	c1	Mukesh Kumar Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
fd90304c-13fe-47ef-b496-2eafeb9a454b	c1	Mumms Kitchen	Sundry Debtors	\N	\N	0.00	Unregistered
123f7393-00f7-4405-a23a-050f779d4ae8	c1	MVR Grand Hotel LLP	Sundry Debtors	09ABMFM8954C1ZT	\N	0.00	Regular
3c7b82c4-a56a-4e7c-b1ce-6a8c0619a72a	c1	Naaz By Noor	Amazon Debtors	\N	\N	0.00	Unregistered
8e01750a-f8e7-44c9-af92-fe67e494ea4d	c1	NAHAR FOODS	Sundry Creditors	07BAWPJ6682G1Z1	\N	830922.13	Regular
4c9b27f5-51d9-4aff-bd01-7d0c1cce7581	c1	Namah Food (Lucknow)	Sundry Debtors	\N	\N	-28450.00	\N
29470b5f-9b68-4d37-a10e-6fb98fd5f428	c1	Namdhari Engg Works	Amazon Debtors	03ACFPS2629L2ZF	\N	0.00	Regular
34cf6928-25f6-4706-b5f3-d23678daf9e7	c1	Nanak Food Mart	Sundry Debtors	09ACLPT6294N1ZG	\N	0.00	Regular
faead616-f11c-4ea0-a172-a491cab79404	c1	Nanak General Store	Sundry Debtors	09AOTPS3535H1ZB	\N	0.00	Regular
6258a1ea-05a0-4d55-b5cb-51cbda64173f	c1	Nanak Masala	Sundry Debtors	\N	\N	0.00	Unregistered
034c4496-8170-4f2b-a473-cf04c78fb884	c1	NANAK MASALA BHANDAR	Sundry Debtors	09AIYPS0211R1ZE	\N	-11542.00	Regular
736f0801-b6ab-4ae5-942d-ea9276658434	c1	Nanak Provision Store (OLD)	Sundry Debtors	09AWQPS6567C1ZU	\N	0.00	Regular
51254ab5-abd6-4f2f-a228-ec27acfe6a8b	c1	Nanda General Store	Sundry Debtors	\N	\N	0.00	Unregistered
25ad81ff-3e33-4a19-ae84-681bbce73b3a	c1	Nanglo All Solutions	Amazon Debtors	05BGTPG5542F1ZC	\N	0.00	Regular
f1b0b262-0acc-4903-a233-13ba2f575d04	c1	Narang Access Pvt.Ltd.	Sundry Creditors	09AAOON5922H1ZE	\N	0.00	Regular
6dbbd580-ac5a-4860-9715-a90258cbedc9	c1	NARANG ACCESS PVT.LTD (DELHI)	Sundry Creditors	07AACCN5922H1ZI	\N	0.00	Regular
083ec972-247a-4257-a0c2-baf5a2927682	c1	Narang Acess Pvt Ltd	Sundry Creditors	29AACCN5922H1ZG	\N	0.00	Regular
da513877-b277-415f-9b8d-be14cf17bbdc	c1	Narang Danone Access  Pvt.Ltd.	Sundry Creditors	\N	\N	0.00	Unregistered
c3c4d544-9aec-4b85-b218-8b40929f2c36	c1	Narangs Hospitality Services P Ltd	Sundry Creditors	\N	\N	0.00	\N
1a0cfce3-610c-4d65-8a8d-cf107ac58982	c1	NASEEM BHAI ATTA	Sundry Debtors	\N	\N	0.00	Unregistered
92257ca4-1648-452a-b615-18a50b76f241	c1	NATHU FOODS (NOIDA)	Sundry Debtors	\N	\N	-11816.00	\N
00c91a51-935c-4d43-9f8b-c88cbcbe99fb	c1	Nath Wani Enterprise	Amazon Debtors	24AAKFN6762G1Z2	\N	0.00	Regular
808a9f96-7ebf-48fc-9bcd-49964bc5fae0	c1	National Insurance	Sundry Creditors	\N	\N	0.00	\N
080f9564-c993-42bf-90fb-ea54db022624	c1	Natraj Overseas	Amazon Debtors	08GEHPS6690B1Z2	\N	0.00	Regular
65772706-bec7-4e4e-8be3-baac31f1cf99	c1	Natural Support Consultancy Services Private Limite	Amazon Debtors	08AACCN1137A1Z3	\N	0.00	Regular
6c1be1d4-ddbe-4489-b76d-5089297b84df	c1	Nature Fresh	Sundry Creditors	\N	\N	0.00	\N
0acc4444-1c87-4fdc-89d7-adad9d0ba389	c1	NATURELL (INDIA) PRIVET LIMITED	Sundry Creditors	\N	\N	0.00	Unregistered
cc48f536-442f-4e13-bca0-db2be89cee62	c1	Naval Kishore Ji	Sundry Debtors	\N	\N	0.00	Unregistered
71bb9ced-11b3-4dc1-84c2-66391fd566cb	c1	NAVEEN KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
a724e444-5f54-4077-9563-41ec7766847d	c1	Naveen Medical Store	Sundry Debtors	09AFFPB8895J1ZV	\N	0.00	Regular
c48cd560-6497-4bbc-8381-49caf750aefb	c1	Naveli Store	Sundry Debtors	\N	\N	0.00	Unregistered
bb64ab31-4ce0-47c9-9b9b-f4139bc7d697	c1	Navrang Bakers (Muzaffarnagar)	Sundry Debtors	\N	\N	-32035.00	\N
be8ddbe8-e58f-403c-890f-83475cadc2bf	c1	NAVYUG TRADERS	Sundry Creditors	09ALQPK6901R1Z7	\N	0.00	Regular
ab7ba72c-9033-475a-8091-79b311f1a01a	c1	Ndedge Informatics Private Limited	Amazon Debtors	19AAGCN2540R1ZW	\N	0.00	Regular
281288ab-e4b7-450d-bda7-7ea780d32ff2	c1	Needs 24	Sundry Debtors	09BKKPC4516N1ZV	\N	0.00	Regular
acb69858-b302-4d6a-a4ac-adb0f982bd4b	c1	NEENA FOODS	Sundry Debtors	09AARFN8939L1Z5	\N	0.00	Regular
57489cb2-e542-4c6d-8d87-66ac13b22ade	c1	NEHA ENTERPRISES	Sundry Creditors	09ABKPA7954N1Z1	\N	0.00	Regular
92cb86c2-48d9-441f-bddc-f2077bb8619f	c1	NEHA HERBALS PVT.LTD.	Sundry Creditors	\N	\N	0.00	Unregistered
a7dd45d9-d677-4572-9b11-83523df2bce7	c1	Neta Ji Paan Shop	Sundry Debtors	\N	\N	0.00	\N
fa48e27f-63ef-49de-9f5c-c7dfdd2e60b3	c1	New Adarsh Corner	Sundry Debtors	09CCJPK9544E1Z9	\N	0.00	Regular
f47138f2-42e1-466d-8155-176f3dd90a64	c1	NEW ADARSH ENTERPRISES	Sundry Debtors	09INUPS1583M1ZP	\N	0.00	Regular
ce012967-74ef-4e54-893f-a797145f44ca	c1	NEW BHATIA CHEMIST	Sundry Debtors	09AIAPB1908J1ZL	\N	0.00	Regular
f936b2df-d256-445e-806d-e4bc8f5b1551	c1	New Bhatia Corner	Sundry Debtors	09ABOPS2668B1ZB	\N	0.00	Regular
f9429299-382b-45a3-a540-3c5ea8040beb	c1	New Bhatia Gumti	Sundry Debtors	\N	\N	-6150.00	\N
68b525eb-a4ec-4a62-b797-5f34a12a9f53	c1	New Dinesh Book Depot	Sundry Debtors	\N	\N	0.00	Unregistered
c053e3a5-9870-4964-b452-faf1092935fc	c1	New Govind Masala	Sundry Debtors	09ABLPS5499M1ZG	\N	0.00	Regular
a41a25cb-63c5-49d3-ba10-19c96149a5e3	c1	NEW GUPTA BROTHERS (Kheri)	Sundry Debtors	09AEJPG3689J1ZY	\N	0.00	Regular
a6ac21fa-cc0e-46ef-8df3-7159c29ded82	c1	New Jawallary House	Sundry Debtors	09ACZPC3195M1ZR	\N	0.00	Regular
dbf1c2c9-e904-4c41-9207-6dd7f9361567	c1	NEW KALYAN G CORNER	Sundry Debtors	09AGMPA3222G1ZR	\N	0.00	Regular
fc9afd8c-6b11-4f3f-a590-81535dc180b9	c1	New Kamal Store	Sundry Debtors	09ACVPM6561D1Z4	\N	0.00	Regular
ee50482a-1d40-422d-b2b7-fd3e99600fb6	c1	New Kohali General Store	Sundry Debtors	09AGLPK1190L1Z0	\N	-589.00	Regular
b0db3e6b-f389-4b11-910e-7d3e72f9d0a6	c1	New Laxmi Store	Sundry Debtors	\N	\N	0.00	Unregistered
c99df4be-58f4-4a63-a5ce-2a3d4339351a	c1	New Mool Chand	Sundry Debtors	\N	\N	0.00	Unregistered
651c075b-8e0e-4ce6-bf2e-eca39c81cf70	c1	NEW NANAK PROVISION STORE	Sundry Debtors	\N	\N	0.00	\N
140f6ac2-f354-4e25-817f-acba7901c284	c1	New Pushpa General Store	Sundry Debtors	\N	\N	0.00	Unregistered
bf5dfe2a-1b81-4911-982d-8ad0d74ac6d3	c1	New Sachdeve Electricals	Sundry Debtors	\N	\N	0.00	Unregistered
3d8acb41-9b05-4c9f-b714-51be228dac22	c1	New Sachdewa Electricals	Sundry Debtors	09ALRPS4738F1ZG	\N	0.00	Regular
efa74573-5215-4467-92f2-71ef8a947314	c1	New Santushti Store......XX	Sundry Debtors	\N	\N	0.00	Unregistered
80ba3f47-35df-49e5-814e-09d4bfcadcd1	c1	New Santusti Store	Sundry Debtors	09AKJPB8367L1ZL	\N	-1553.00	Regular
a11c33c7-44ad-4273-a053-62ae8e9a8332	c1	New Shri G Departmental Store	Sundry Debtors	09BDRPS4195K1ZI	\N	0.00	Regular
91a59970-6fcb-43b6-aedf-56fda9345708	c1	New Singh General Store	Sundry Debtors	09AAGFN2320N1Z5	\N	0.00	Regular
ac62a8d5-dee6-48f1-a2ca-6baeaaf000fd	c1	New Sunny Enterprises	Sundry Debtors	09AAPFN8653B1ZX	\N	0.00	Regular
3bcd121c-6e97-4bff-ae18-e0901aedd19b	c1	New Super Grocery	Sundry Debtors	\N	\N	0.00	\N
f5136e40-d29e-43a4-8982-b8e26aecca85	c1	Nextgen Biosciences	Sundry Creditors	\N	\N	3202.00	\N
461fb904-e9ae-423d-8712-7aa8db629ac2	c1	Nidhi Agarwal	Amazon Debtors	27AGYPA2126K1Z7	\N	0.00	Regular
088df1bd-587b-46ec-a99c-39ae9011c480	c1	Nidhi Sales	Sundry Debtors	09AHWPD5369C1Z0	\N	0.00	Regular
ae2eda28-2de2-48c3-8865-3e954ec2f6c3	c1	NIF PRIVATE LIMITED	Sundry Debtors	\N	\N	-21600.00	\N
e6bac325-275f-43d5-b9c9-d9c2d42a28ae	c1	NIF PRIVATE LIMITED-ICE CREAM DIVISION	Sundry Debtors	09AACCN6483F4Z5	\N	0.00	Regular
8a92f903-561b-4c11-866c-4022fecc1093	c1	Niharika Baikery	Sundry Debtors	\N	\N	0.00	Unregistered
2d12d91f-762c-4ebd-8ad4-7973c660ea22	c1	Nikhil	Amazon Debtors	06BETPN5364Q1ZG	\N	0.00	Regular
ee3267bf-f457-4733-9edb-9cd1b95e7879	c1	Nilon&apos;s Enterprises Pvt.Ltd.	Sundry Creditors	09AABCN8601N1Z4	\N	0.00	Regular
808dddb2-bde0-49f9-84f1-ca6b3cbe2401	c1	Nilons Enterprises Pvt Ltd	Sundry Creditors	27AABCN8601N1Z6	\N	0.00	Regular
f76c3808-93bd-4ec2-b243-4ebf17c85a75	c1	Nima Store	Sundry Debtors	\N	\N	0.00	Unregistered
388d1787-321a-4735-98ef-9e91852400a5	c1	Nine Players Hospitality Private Limited	Amazon Debtors	19AAFCN2230D1ZV	\N	0.00	Regular
027651b1-5416-4a45-9010-b7891371e925	c1	Nishu Trading	Sundry Creditors	09AUTPP8528M1ZG	\N	0.00	Regular
0fe663dc-fe00-4ff3-b418-9eb50cb6c798	c1	NITIN GUPTA	Sundry Debtors	09ANEPG4429Q1ZI	\N	0.00	Regular
fd092215-7259-47a2-885e-efb6beb05ebf	c1	Nitin  Trading Company	Sundry Debtors	09AIDPG4232H1ZJ	\N	-51923.80	Regular
dc62606f-bd2e-4b4b-8ca9-cb015faff8d8	c1	NITYA GENRAL STORE	Sundry Debtors	\N	\N	0.00	Unregistered
a3c0e180-9ac4-4ccb-acbf-38872d93017f	c1	Nityam Ji Store	Sundry Debtors	\N	\N	0.00	Unregistered
e0021d7d-ec6d-4dd3-a914-1e695e3bef5f	c1	NK Traders	Sundry Debtors	\N	\N	0.00	\N
8eceb87a-ddac-4525-9d61-ac6dbee6667e	c1	Nk Traders (Kamla Nagar)	Sundry Debtors	\N	\N	0.00	\N
8c76f266-1d39-4de5-9980-c5c0fee56c79	c1	Nobale Palace	Sundry Debtors	\N	\N	0.00	Unregistered
d87dbdc7-5f89-4c83-925b-c8d56769fd6d	c1	Noble Book Stall	Sundry Debtors	09AALFN7609P1ZE	\N	0.00	Regular
c85f315f-1d6e-466e-baef-db3cd1ded19f	c1	Noble Variety Mart	Sundry Debtors	09AABFZ9760D1ZT	\N	0.00	Regular
80953623-e579-46c2-875a-ea432aa3df0f	c1	NOOR ALI	Sundry Debtors	\N	\N	0.00	Unregistered
0d8b30f0-2a39-4b2e-9630-5cda8247740e	c1	NOOR NISHAN INC	Sundry Creditors	07AAMFN2833N2ZS	\N	0.00	Regular
70bf03db-662f-4f78-b011-e6d9a2d997fb	c1	NOOR NISHAN PRIVATE LIMITED	Sundry Creditors	07AAHCN5237E1ZJ	\N	-42068.00	Regular
16292a28-e8d1-46fa-9751-56888ae1f3d1	c1	Nova Baikery	Sundry Debtors	\N	\N	0.00	Unregistered
31f4e0b3-58a1-405b-9785-1cf6d03604ee	c1	Nova Enterprises	Sundry Debtors	09HZKPS8466Q1ZS	\N	0.00	Regular
4ac01796-4835-4888-af39-03e3a14e2405	c1	Novel Infra	Sundry Debtors	09AAQFN2113D1ZH	\N	0.00	Regular
df1bb8c3-9ad1-4045-8aea-1bfe19457e30	c1	Novelty Store	Sundry Debtors	\N	\N	0.00	Unregistered
0bded4cb-5e15-42cd-afe0-771015724d4b	c1	Novena Enterprises	Sundry Creditors	\N	\N	0.00	Unregistered
f95fe7cb-93a0-4a9b-94fa-35227b6312df	c1	Novena Life Sciences	Sundry Creditors	\N	\N	0.00	Unregistered
280bb08a-0692-49f3-bb57-11600209f060	c1	N P Store	Sundry Debtors	\N	\N	0.00	Unregistered
e8ef91c7-776c-4bc0-a1c7-1d446c4834ae	c1	NRIVAR HOSPITALITY	Sundry Debtors	09AAFCN9807Q1ZK	\N	0.00	Regular
d4b1460c-800b-4d66-8fb5-3b11258c8c46	c1	N.S ENTERPRISES	Sundry Debtors	09EGRPK9250H1ZQ	\N	0.00	Regular
421be81c-0fc1-47a1-9dbf-69f191612f2e	c1	NUKKAD KE BHUKKAD	Sundry Debtors	09DPPPK3697C1ZD	\N	0.00	Regular
311466bf-53ea-43f8-ad0f-e4d5b11f0fb0	c1	N V OIL MILLS	Sundry Creditors	\N	\N	0.00	\N
2a70b5eb-168a-4351-a816-0ec8b3d12cfe	c1	Office Maintenancee Xpenses	Indirect Expenses	\N	\N	0.00	\N
a42667f5-a571-474a-8364-f660c9e1ffec	c1	Office Maintinance	Indirect Expenses	\N	\N	0.00	\N
bf52cc6d-397b-4cc3-a68a-57208b7df68e	c1	Oil Madras Baking Company	Amazon Debtors	33AABCO9820A1ZW	\N	0.00	Regular
af7dbb16-7e08-4654-bf4a-23519646b6ce	c1	OJA Automobiles Private Limited	Amazon Debtors	18AAACO7801N1Z5	\N	0.00	Regular
6ed5e08d-0b9b-4196-b460-16a0f1cb8699	c1	Olivia Bakers (Meerut)	Sundry Debtors	\N	\N	-19491.00	\N
7baab347-4f65-4111-b443-4902542cee9b	c1	Om Agencies	Sundry Debtors	\N	\N	0.00	Unregistered
75acddf6-52db-45f5-8b45-eb8d0b23499c	c1	OM AGENCIES 2018-19	Sundry Creditors	09APJPM8688N1ZO	\N	0.00	Regular
b3eed1ab-cd82-4d5c-a277-c65ac56e717a	c1	OM General Store	Sundry Debtors	\N	\N	0.00	Unregistered
f4d38634-dd3b-4b69-bf8a-e589861d79d1	c1	Omjee &amp; Sons	Sundry Creditors	\N	\N	0.00	Unregistered
919af59a-f0dc-4685-9afc-7a7767ff2a3d	c1	Omni Traders	Sundry Debtors	\N	\N	0.00	Unregistered
c16ecee5-a094-41b0-8c05-08bcc3240d0a	c1	Om Paan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
9aa5de85-c809-4db1-9ead-ae4793a8a507	c1	Om Patanjali Store	Sundry Debtors	\N	\N	0.00	Unregistered
f647b452-e933-4237-aecd-a0163a978f9d	c1	Online Grocery Store	Sundry Debtors	\N	\N	0.00	Unregistered
7265d661-c1a9-4c29-8635-3de42031391b	c1	Only Coffee	Sundry Debtors	\N	\N	0.00	\N
13aba540-6b66-48a3-a44e-8f596509bc90	c1	Options Purchase	Indirect Expenses	\N	\N	0.00	\N
4b1f0dcf-fcc4-43ef-ad95-c15b26a39be3	c1	Options Sales	Indirect Incomes	\N	\N	0.00	\N
53760239-0bea-4f82-b3a0-53617987c31d	c1	O.P.Trading Co.	Sundry Creditors	07BBFPK0393B1Z1	\N	0.00	Regular
302d14d2-1e0a-4ced-858a-23e46ad2bf7b	c1	Orbit Enterprises	Amazon Debtors	20BYGPR4871M1Z0	\N	0.00	Regular
77e5a0b4-a5ce-487f-aa43-f235ab099371	c1	Order Cancellation Fees Amazon	Indirect Expenses	\N	\N	0.00	\N
64da325a-a24c-461f-aadd-7e7a9de0c64a	c1	Ounce Foods Corporation	Sundry Debtors	09AAHFO0529K1Z2	\N	0.00	Regular
7f063406-766f-491b-8dec-06d774e8e50c	c1	Output CESS	Duties & Taxes	\N	\N	0.00	\N
ca51d36d-819a-49f3-a122-e73d605e702d	c1	Output Cess 12%	Duties & Taxes	\N	\N	24454.76	\N
3f1e155b-4259-434b-b0e5-0d63fa9544ad	c1	Output CGST	Duties & Taxes	\N	\N	0.00	\N
731a48a4-05cc-49a5-b3bb-a2cb4255de61	c1	Output CGST14%	Duties & Taxes	\N	\N	31662.04	\N
f7bffa71-87ac-4837-bb8b-1f519f4e38fe	c1	Output CGST 20%	Duties & Taxes	\N	\N	15962.62	\N
4bce020a-d490-403e-9e81-202d391483d1	c1	Output CGST 2.5%	Duties & Taxes	\N	\N	195716.95	\N
8ac870c1-b73e-4800-95b2-8ee13495cac7	c1	Output CGST 6%	Duties & Taxes	\N	\N	207655.40	\N
258f40af-3f4d-464a-8099-c94d8e0dd0fa	c1	Output CGST 9%	Duties & Taxes	\N	\N	357545.21	\N
f6cf5786-a7c6-47eb-a815-3a534d8edc42	c1	Output Igst	Duties & Taxes	\N	\N	0.00	\N
11eb72fb-44b8-4970-81f6-57ea616a2468	c1	Output Igst 18	Duties & Taxes	\N	\N	0.00	\N
19046112-b5ff-4f6f-ad35-76e8796cfa8f	c1	Output SGST	Duties & Taxes	\N	\N	0.00	\N
6bef021d-3620-4cf1-9faf-f3bb052c4ffc	c1	Output SGST 14%	Duties & Taxes	\N	\N	31662.04	\N
a56032db-edf2-4785-9612-f4cbba21a54c	c1	Output SGST 20%	Duties & Taxes	\N	\N	15962.62	\N
c51e3794-123c-4cb8-97b3-8f1f00d801ce	c1	Output SGST 2.5%	Duties & Taxes	\N	\N	195716.95	\N
9470cb59-dcd3-4e65-974b-f3b538315324	c1	Output SGST 6%	Duties & Taxes	\N	\N	207655.40	\N
2db3f3be-8bc7-4043-b2c1-966783479697	c1	Output SGST 9%	Duties & Taxes	\N	\N	357467.99	\N
aed6529b-5a18-4f3c-9784-d37fa20a382c	c1	P2w Ventures Pvt.Ltd.(THF)	Sundry Debtors	09AALCP3420B1ZQ	\N	0.00	Regular
3f3006b9-ef35-4fc8-9ea4-e2420c43f6d7	c1	Packaging Charges(IGST12%)	Direct Expenses	\N	\N	0.00	\N
52db9703-3fbf-431c-8659-4b3fb26dd788	c1	PACKING	Direct Expenses	\N	\N	0.00	\N
d263a95c-8e4c-4842-aa86-03eff39ad31c	c1	Packing Charges	Direct Expenses	\N	\N	0.00	\N
893a3b57-0edd-40d4-9c90-bb3558ebac59	c1	Packing Charges 12	Direct Expenses	\N	\N	0.00	\N
fdea1804-cf90-4835-953a-b5ea5ab51dd3	c1	Packing Charges 5%	Direct Expenses	\N	\N	0.00	\N
c0decff2-a263-4df9-b74d-4530ab925741	c1	Pakaging Charge	Direct Expenses	\N	\N	0.00	\N
8abaaa48-1a1f-4682-bd58-32c7f049ff85	c1	Pandit Paan	Sundry Debtors	\N	\N	-1464.00	\N
1a09f3f6-e0a5-4673-b928-fa8a67085425	c1	Pandit Pan Plaza	Sundry Debtors	\N	\N	0.00	Unregistered
e7ecb921-bb76-41e6-96df-c7e4b4471a5f	c1	Pandit Panshop	Sundry Debtors	\N	\N	0.00	Unregistered
a83440f6-af97-48d8-a936-2391c3bad76d	c1	Panjabi Chaap	Sundry Debtors	\N	\N	0.00	Unregistered
9c34b6c7-db3e-4346-b630-d0b6e2e8ad27	c1	Pankaj Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
1b68ff68-aadb-4208-8f46-7033b7d8d75e	c1	Pankaj Mehrotra	Capital Account	\N	\N	2924594.66	Unregistered
4b58694c-4135-4705-a10e-b08112ae9786	c1	Pankaj Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
ac18b99d-e20e-401d-9439-1a18ccb229b1	c1	PAPPA HOSPITALITY CONCEPTS LLP	Sundry Debtors	\N	\N	0.00	\N
c7f5ca52-b0a2-45df-a8de-df38e7c1134e	c1	Pappu Store	Sundry Debtors	\N	\N	0.00	Unregistered
fd7d4b92-fc39-4dab-921a-21524bf08473	c1	Pappu Store (Nayaganj)	Sundry Debtors	\N	\N	0.00	Unregistered
5a80abf4-9074-421e-aaf3-222966191951	c1	Paras Confactionary	Sundry Debtors	\N	\N	0.00	Unregistered
8c6176d6-740f-4e85-ab49-f42d40c8c1ee	c1	Paras Enterprise	Sundry Debtors	\N	\N	0.00	Unregistered
216fa15e-b213-46c5-9945-ee9d31f0a3a1	c1	Paras Professional (20-21)	Sundry Debtors	09AAKPB3200B1ZK	\N	0.00	Regular
86bd2c66-0270-4431-8236-0d3e92955b6d	c1	Paras Ram	Sundry Debtors	09AAKPB3200B1ZK	\N	0.00	Regular
913204a2-8867-48e8-bb6b-ece41c31bc2b	c1	Pari Sales	Sundry Debtors	09AIIPB8035A1ZO	\N	0.00	Regular
477cd996-f89e-4b19-9210-8426641f0684	c1	Parkash Cake	Sundry Debtors	\N	\N	0.00	Unregistered
9cef3858-d5b8-473e-a780-aaa730ea78fb	c1	Parshwa Game Zone	Sundry Creditors	09AAXFP8688A1ZE	\N	0.00	Regular
a9a93e95-5cf2-4195-bc40-fdeeaa32c066	c1	Parul Store	Sundry Debtors	\N	\N	0.00	Unregistered
3ace4791-257c-4a16-8b18-02142999891f	c1	PARWATI STORE	Sundry Debtors	\N	\N	0.00	Unregistered
2fa1edae-b693-4b8b-90d5-3f6748ecc261	c1	PASARI ENTERPRISES	Sundry Debtors	\N	\N	0.00	Unregistered
0fbc79da-9559-4d30-8ae7-6634808ce967	c1	Pashupati Ayush Trading And Marketing	Sundry Debtors	09ALLPJ0990Q1ZA	\N	0.00	Regular
2afe72ce-ccfc-42ce-927a-f2d7b76e0255	c1	Pashupati &amp; Radhey Co.	Sundry Debtors	09ADGPM7007C1ZS	\N	-6240.00	Regular
e0dac0e1-b09b-460c-be90-0c14e6341b86	c1	Patel Cold Drink	Sundry Debtors	\N	\N	0.00	Unregistered
b8581c4a-5a0c-489a-858d-dd2e7ea319c6	c1	Pawan Electrical House	Sundry Debtors	09AAUPY0004G1ZH	\N	0.00	Regular
42221aa6-2f81-40f4-903e-3e4e1ed3a960	c1	Pawan Electronics	Sundry Debtors	09AASPY1280E1Z7	\N	0.00	Regular
5f5cbaec-c6ee-4261-aea8-4771b9ecd7d7	c1	Pawan Electronics 1	Sundry Debtors	09AASPY1280E1Z7	\N	0.00	Regular
d2b582fe-6b8d-4dd2-ba92-9c84a2a26098	c1	Pca Movers(Opc) Pvt Ltd. Lucknow	Sundry Debtors	\N	\N	0.00	\N
29d2a49b-7782-46de-9314-35ec80962f0f	c1	P.D.Gooba &amp; Sons	Sundry Debtors	\N	\N	0.00	Unregistered
703c270a-3fc8-445e-9f74-fe42d36c32a0	c1	Pegasus Toykraft Private Limited	Amazon Debtors	27AAGCP8676A1Z7	\N	0.00	Regular
f60ff404-87cc-466d-903b-3db40b623690	c1	Perfact Syrgical	Sundry Debtors	09AAFFP2681P1ZK	\N	-19868.00	Regular
cad484ad-b4ca-4d18-85f3-9491d0d65ef3	c1	Perfeccion Hospitality Pvt, Ltd.	Sundry Debtors	09AAKCP6446L1ZQ	\N	-33725.00	Regular
8e2c19f5-3c70-422e-8f79-d8ee1f64bd03	c1	PERFECT PRODUCT (ALIGARH)	Sundry Debtors	\N	\N	-13534.00	\N
d5660a7e-6225-42b6-878e-5271ab40e3cb	c1	Phone Pe Charges	Indirect Expenses	\N	\N	0.00	\N
00a07325-3744-4559-9e20-8e878607cdac	c1	PHONEPE PRIVATE LIMITED	Sundry Creditors	\N	\N	165.00	\N
3cf31d59-a070-4c9a-83fb-6828a8879648	c1	Pick N Pay	Sundry Debtors	09AGZPM3335K1ZN	\N	0.00	Regular
fd0da519-48db-420e-b9ce-4df18d014408	c1	Pine Tree Pictures Private Limited	Amazon Debtors	27AADCB0661J1ZS	\N	0.00	Regular
7ad7e85b-d09e-46d7-80d7-74ba9ab9c6a8	c1	Pink N Choose	Amazon Debtors	01AAIFP3427A1ZY	\N	0.00	Regular
cdf7e49f-3ee1-45e4-b4f8-e74993bca7d8	c1	Pioneer Foods Pvt Ltd (Pioneer Non Food Pvt Ltd)	Sundry Creditors	08AAFCP0623G1ZP	\N	0.00	Regular
f46a3b2b-94f4-4b44-8c96-45f65bbe5a7c	c1	Pioneer Medical Store	Sundry Debtors	\N	\N	0.00	Unregistered
acdb83f4-f657-4de4-9101-1a8fbdf346de	c1	Pioneer Non Fried Foods Pvt.Ltd.	Sundry Creditors	\N	\N	0.00	Unregistered
1bdacfdb-91dd-49a3-b14c-b791a2d2bb4f	c1	PIPALTREE BEVERAGES	Sundry Debtors	27AAJCP4740N1ZW	\N	0.00	Regular
4accc143-7a05-486d-afdc-5a1dc41f2421	c1	PIZZA YUM	Sundry Debtors	\N	\N	0.00	Unregistered
593beb99-8ab7-425d-b1fc-f33a5cd3bb94	c1	P.Kackar Kapoor &amp; Co.	Sundry Creditors	\N	\N	23443.00	\N
fa9eaad4-b74c-4766-9f06-b3de6e0f7ba5	c1	Playground Outdoors LLP	Amazon Debtors	02AAXFP4352K1ZU	\N	0.00	Regular
19e50479-247d-4d44-8103-df8ba6967f19	c1	PLY WORLD	Sundry Creditors	09AOEPK7169Q1ZI	\N	0.00	Regular
2a607fd5-21b0-4ba4-b341-1747854ee7a3	c1	PMS DISTRIBUTORS	Sundry Debtors	09ANGPS2612H1ZY	\N	0.00	Regular
0d0d16ae-a056-4971-ad9b-d750e7241305	c1	Poa Enterprises	Sundry Debtors	09ANAPT4552F1ZW	\N	0.00	Regular
1c390f39-45ed-4625-b418-1ec87c432bdc	c1	Pohey Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
c9753ec7-0fec-452f-af41-6d668d4ff645	c1	Pooja Medical	Sundry Debtors	\N	\N	0.00	Unregistered
f78b6aa1-69f4-4abf-9222-d46315c55de6	c1	Pooja Medical Store	Sundry Debtors	09AAGFP9501K1ZW	\N	0.00	Regular
ddb455a3-7bcb-436a-ba46-98275032c612	c1	Poojan Exp.	Indirect Expenses	\N	\N	0.00	\N
1882c214-f6d6-44f2-8e83-40143ebb3379	c1	Poonam Electricals	Sundry Debtors	\N	\N	0.00	Unregistered
963be02a-4c18-4ed3-ae14-446f6be7ebe4	c1	Poorvi Traders	Sundry Debtors	\N	\N	0.00	Unregistered
69c5f926-c576-4b00-8288-40751af37a2c	c1	Popular Medical Store	Sundry Debtors	\N	\N	0.00	\N
588640f1-d32d-45d6-be20-446de8fd8b9d	c1	Postage Exp.	Indirect Expenses	\N	\N	0.00	\N
7d0ffb1d-5c21-4b0c-99fd-301b13c8017b	c1	Poter	Sundry Creditors	\N	\N	266.98	\N
5dfce3c7-a8d7-437b-9b35-792151f2521d	c1	Poter Service	Indirect Expenses	\N	\N	0.00	\N
e3fd9b97-a39e-4e16-be10-d4bddd880c0e	c1	Power Expence (Office)	Indirect Expenses	\N	\N	0.00	\N
e6c0f070-c77f-413f-a06a-c2256c883ed5	c1	Power Pro Enterprises (2019-20)	Sundry Creditors	23AJMPS8820P1ZF	\N	0.00	Regular
59adca22-1cb2-4b73-934f-f3a2968bcbc9	c1	Prabhat  Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
0bab4d74-e412-49f2-8767-ad8ac13cc01a	c1	Prabhu Kripa	Sundry Debtors	\N	\N	0.00	\N
69ec3989-ed07-404e-a51b-afbdb7e23fff	c1	Pragati Enterprises	Sundry Debtors	09ADMPG8886D1Z1	\N	0.00	Regular
e2d66f2b-aec3-44ff-9d9c-44cd8f965613	c1	Pragati Sales Corporation	Sundry Debtors	\N	\N	0.00	Unregistered
6f1de66b-9e24-4f41-89c0-8c2ef3bb90f0	c1	Prakas G Departmental Store	Sundry Debtors	\N	\N	0.00	Unregistered
01fbe56e-a53f-4d4d-9971-5e524d029d5a	c1	Prakash Electricals	Sundry Debtors	\N	\N	0.00	Unregistered
c20f50cf-0f42-4a82-81a2-d36ec8381efa	c1	Prakash Electric Co.	Sundry Debtors	\N	\N	0.00	Unregistered
14c46fd3-9959-49dc-b524-905fdd542241	c1	Prakash Genral Store	Sundry Debtors	\N	\N	0.00	Unregistered
6af05297-da82-4c02-90da-3ad31a9769e3	c1	Prakash Kirana Store	Sundry Debtors	09BPEPG5612Q1ZI	\N	0.00	Regular
00e80930-27cc-4550-b993-04cc4c96a8d4	c1	Prakas Pustak Bhandar	Sundry Debtors	\N	\N	0.00	Unregistered
0be3dccb-55f4-4a29-bf76-3e9b052ef751	c1	PRASHANT KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
290554ef-203b-43d4-83ae-51f4e3575d1d	c1	Pratap General Store	Sundry Debtors	09AMVPK1463E1ZS	\N	0.00	Regular
2814feca-6804-4996-87fe-db3091e8c5ab	c1	Prateek Enterprises	Sundry Debtors	\N	\N	0.00	\N
fc9adc86-fe60-42f8-9dac-73ced0c90896	c1	Pratha Store	Sundry Debtors	\N	\N	0.00	Unregistered
c0138028-d370-47f2-b112-c6dc83f3bb8e	c1	Praveen Sales	Sundry Debtors	\N	\N	0.00	Unregistered
b88e83b4-bebd-4a44-b574-76a70a434d56	c1	Prem Chemist	Sundry Debtors	09AAQPM6968H1ZU	\N	0.00	Regular
a060556f-7c71-4f7d-8d01-8058246d167d	c1	Prem Drug House	Sundry Debtors	\N	\N	0.00	Unregistered
b192c335-c7c8-43d5-9ad8-b45e83771fe8	c1	Prem Drug Store	Sundry Debtors	09AAQPM6969G1ZV	\N	0.00	Regular
b0f6cff4-2fb3-4098-a95f-4a138f825320	c1	Prem Watch	Sundry Debtors	\N	\N	0.00	Unregistered
202ff219-e6c7-41a7-8405-cffd9dd832c0	c1	Prepaid Insurnace	Loans & Advances (Asset)	\N	\N	0.00	\N
65644854-0c0b-462b-8b0b-92806fdff73e	c1	Prerna Store	Sundry Debtors	\N	\N	0.00	Unregistered
77b1b575-6fbc-4e40-a842-db2c1a5887c6	c1	Prime Creations Pvt Ltd	Amazon Debtors	09AACCP3757A1ZL	\N	0.00	Regular
1ed7db1e-14d9-47ca-a544-21aa7ce357b2	c1	PRINCE ASSOCIATES 2	Sundry Debtors	09AACFP0500C1Z0	\N	0.00	Regular
0ccc1c63-1e16-4bde-91a7-7ea40346eeff	c1	Prince General Store	Sundry Debtors	09ABVPL3332N1ZZ	\N	0.00	Regular
fb0a36d2-1050-4f1a-908f-f8bb91178143	c1	Printer New Laser	Fixed Assets	\N	\N	-4814.00	\N
29e15453-231b-4c17-953d-402b30e35381	c1	Printing &amp; Stationery	Indirect Expenses	\N	\N	0.00	\N
8c5b7919-19ea-4b08-830e-95ec12f36203	c1	Priyam Enterprises	Sundry Creditors	09AMPPS6536G1ZE	\N	0.00	Regular
6925acac-754e-42e0-96b4-1c4cf18f6a87	c1	Priyanka Store	Sundry Debtors	\N	\N	0.00	Unregistered
a9c8e75a-1e90-4e03-9389-54c1509b9cd2	c1	Priya Store	Sundry Debtors	\N	\N	0.00	Unregistered
a6f80f7e-cf2f-444a-bff5-ca616c5ef1ce	c1	P R MARKETING	Sundry Creditors	09AARFP1833H1ZX	\N	0.00	Regular
72ec92db-c67a-4f21-8fcd-7fb7d3c05e41	c1	Proaffluence Advisory Services Pvt Ltd	Amazon Debtors	27AAICP7699B1ZY	\N	0.00	Regular
39a9f675-d926-4c30-be6c-c7916a3d1dd3	c1	Profit &amp; Loss A/c	&#4; Primary	\N	\N	965674.60	\N
920e264c-e789-409a-86df-bcf80e74e912	c1	Profound Developer Pvt. Ltd	Sundry Debtors	09AAHCP0948G1Z9	\N	0.00	Regular
ae05f08c-2859-47e0-bdc9-25af00f77b4d	c1	PUNEET ENTERPRISES	Sundry Creditors	09AQIPK8055H1ZH	\N	0.00	Regular
b3e07bd6-769c-4d9b-9bf6-f4866b7b46bc	c1	Puneet General Store	Sundry Debtors	09BAXPB9703M1ZZ	\N	0.00	Regular
829880c3-1f09-4421-a935-f4303e9643f1	c1	PURCHASE GST 28%+12% CESS	Purchase Accounts	\N	\N	0.00	\N
588ada70-2e35-496a-b1e5-ec0285b9f14b	c1	PURCHASE GST @ 0%	Purchase Accounts	\N	\N	0.00	\N
ee95791d-ca8b-4538-9cbd-83269d672504	c1	Purchase in Pricipal A/c	Purchase Accounts	\N	\N	0.00	\N
7ca72731-7ddc-44cb-b9d9-41b83672f28f	c1	Purchase UPGST 12%	Purchase Accounts	\N	\N	0.00	\N
2b335164-4479-42c5-8c90-a258c023d12a	c1	Purchase UPGST 18%	Purchase Accounts	\N	\N	0.00	\N
7f28467c-4f41-4c53-a8dc-2cd9a3733591	c1	Purchase UPGST 28%	Purchase Accounts	\N	\N	0.00	\N
63335202-24f6-45e6-a377-57151103b0ed	c1	Purchase UPGST 40%	Purchase Accounts	\N	\N	0.00	\N
e98e354d-acad-4fd6-955f-1a4dae02792f	c1	Purchase UPGST 5%	Purchase Accounts	\N	\N	0.00	\N
d8742674-a4fd-4c8b-a8bc-3370223f948a	c1	Purshotam Dass Manna Lal	Sundry Debtors	\N	\N	0.00	Unregistered
2a1d57cb-185d-463a-8585-216bb249a825	c1	Purshotam Lalwani	Sundry Debtors	\N	\N	0.00	Unregistered
c091fb72-7414-4239-a9d0-5801f6e004d6	c1	Pushpa General Store	Sundry Debtors	\N	\N	0.00	Unregistered
5967e35b-53d5-4164-982f-84a9c3706720	c1	Pushp Foods	Sundry Debtors	\N	\N	0.00	Unregistered
bd99e9c4-dfac-44db-a619-88864803277c	c1	Quality Bachat Bazar	Sundry Debtors	09AABFQ0434H1ZH	\N	0.00	Regular
efc91c19-7d79-4beb-a353-3a0737bd008f	c1	QWICK BITE	Sundry Debtors	\N	\N	0.00	Unregistered
b921afb5-0e09-4337-a721-7ff36defbf45	c1	Rachit Cosmetics	Sundry Debtors	\N	\N	0.00	\N
ddfa932b-7b8d-4652-bc1f-e71e3c14bb54	c1	Radha Departmental Store	Sundry Debtors	\N	\N	0.00	Unregistered
8286fca1-ddc8-4504-ad2c-f8376d5c1714	c1	Radha Enterprises	Sundry Debtors	\N	\N	0.00	\N
31ca088c-5483-4543-ae59-7f0131efd82a	c1	Radha Gernal Store	Sundry Debtors	\N	\N	0.00	\N
9db252ca-edc7-4535-bf4b-b809541763f0	c1	Radha Madhav Inc	Sundry Creditors	07AAZFR4246A1Z0	\N	0.00	Regular
bf57f02d-d21e-4e3f-9568-c049546dbe4a	c1	Radha Store	Capital Account	\N	\N	0.00	Regular
a798f2f4-48e4-43fe-8fda-9e53b783370d	c1	Radhey Enterprises	Sundry Debtors	09AGEPG1822G1ZR	\N	0.00	Regular
7f7e2cc1-595f-4d5b-8dd8-09f89c12a5f2	c1	Radhey Lal Rajesh Kumar	Sundry Debtors	09AFGPG9220D1ZP	\N	0.00	Regular
55396d45-d609-453c-bca7-3c7c5007abb2	c1	Radhey Rahdey Sales	Sundry Debtors	\N	\N	0.00	Unregistered
55d7ac9d-b981-490a-8b37-8ce9a03842a4	c1	Raees Pan Shopxxxxxx	Sundry Debtors	\N	\N	0.00	Unregistered
15e579d9-58a0-4358-b466-4e78fc4aed26	c1	Raghav Store	Sundry Debtors	\N	\N	0.00	Unregistered
27c67c80-957e-421d-ae7a-86aace36e8dd	c1	RAHUL ASSOCIATES	Sundry Creditors	07AASFR1374A1Z8	\N	18318.00	Regular
38c3fb76-a76c-48a0-8992-b28ab81e23c6	c1	Rahul Electronicsxxxxx	Sundry Debtors	\N	\N	0.00	Unregistered
1d93674d-7b15-4929-ad12-01db9c41d0fc	c1	Rahul Enterprises	Sundry Debtors	09AIEPM3440Q1ZT	\N	0.00	Regular
715eeff2-ad6c-41d4-b632-c66935e8ec57	c1	Rahul Namkeen	Sundry Debtors	\N	\N	0.00	Unregistered
27ec2ed3-83f3-4b77-9632-5b5e28fa0efd	c1	Rahul Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
23e2ee54-59ca-470c-84c5-cfa2b914e9dd	c1	Rahul Sweets &amp; Namkeen	Sundry Debtors	09AGKPG9047P1ZL	\N	0.00	Regular
3429b981-9458-4291-af3d-e256a5a25406	c1	Rainbow Agencies	Sundry Debtors	09AGUPL2776L1ZG	\N	0.00	Regular
d3573f63-fed1-4f93-8fdd-98004f8db140	c1	Rainbow Commercial Centre	Sundry Debtors	09AEUPG9883M1Z9	\N	0.00	Regular
be5e0401-db6d-43ff-b26d-b8216255443a	c1	Rainbow Traders	Sundry Debtors	\N	\N	0.00	Unregistered
75bb4397-d95e-47c7-b915-5cdf83d7b633	c1	Rais Paan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
f0a4486a-697b-486e-97dc-7b4fbbb4ea05	c1	Raja Bhai	Sundry Debtors	\N	\N	0.00	Unregistered
0971010f-0eed-431e-b2a2-be43387c36ab	c1	RAJA PROVISION STORE	Sundry Debtors	\N	\N	0.00	Unregistered
039a4f67-ef96-4842-86d3-f973d4792eb0	c1	Rajarishi Traders	Sundry Debtors	09DXQPK5191E1ZZ	\N	0.00	Regular
829d88ea-c1ee-4529-abaa-f80628dcf973	c1	Raja Store	Sundry Debtors	\N	\N	0.00	Unregistered
60cba7b7-b604-4c2a-a328-72f9ed0e0f5a	c1	Rajat Kirana Store	Sundry Debtors	\N	\N	0.00	Unregistered
9f4c44bd-d37f-4974-9949-d1a2767bdea1	c1	Raj Biscuits	Sundry Debtors	\N	\N	0.00	Unregistered
7d751ec1-0e4c-4758-8475-ab581bfd2757	c1	Raj Chemist	Sundry Debtors	\N	\N	0.00	Unregistered
b097964e-6bce-4656-bbe9-2e77bf496c71	c1	Raj Confactionary	Sundry Debtors	\N	\N	0.00	Unregistered
dbced317-97f2-43aa-9bb4-2d6ade750bd3	c1	Rajeev Departmental Store	Sundry Debtors	09AOFPK8273C1ZU	\N	2032.00	Regular
0af90cd0-f96a-49b0-9c09-83ca582bf9f3	c1	Rajeev Medical Store	Sundry Debtors	09AAHFR4718B1ZB	\N	0.00	Regular
4c318a36-84af-410e-8a48-6a8ef058e921	c1	Rajeev Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
d7d81d73-079a-46bf-ad49-b0f90d019124	c1	Rajeev Ranjan	Sundry Debtors	\N	\N	0.00	Unregistered
c287f901-b844-496d-bd6d-8e1960d972bf	c1	Rajendra Store	Sundry Debtors	09AFLPJ8094D1Z3	\N	0.00	Regular
cd585a08-07c2-48f3-a743-4607ecf7bbe9	c1	RAJESH	Sundry Debtors	\N	\N	0.00	Unregistered
81785130-b281-41ff-a131-c10711c461d8	c1	Rajesh Paan Shop	Sundry Debtors	\N	\N	176.00	\N
f57a9aad-3840-4bfd-a393-2f42df674299	c1	Rajesh Sales Agencies	Sundry Creditors	\N	\N	0.00	Unregistered
4a42e9b6-427e-46de-8073-0ebca79a9c6b	c1	Rajesh Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
ef304bda-43b6-469c-b8a9-be4b4128eaa5	c1	Raj Essence Mart	Sundry Debtors	09ABKPA8061G1ZO	\N	0.00	Regular
590251db-8527-422b-82b5-05f9d58b311a	c1	Raj General Store	Sundry Debtors	\N	\N	0.00	Unregistered
2f04e2a5-b256-4cb3-a655-d1d2d2e32373	c1	Raj Kalpana Travels &amp; Cargo	Sundry Creditors	\N	\N	14060.00	\N
f79ff80d-7bfc-4471-8b00-dc6e54b5801a	c1	Raj Kamal Departmental StoreXXXXX	Sundry Debtors	09ACYPM3827B1ZA	\N	-4190.00	Regular
e2c25592-cb55-4fae-87a8-ee9bd48cb3be	c1	RAJ KUMAR BRO&apos;S	Sundry Debtors	\N	\N	0.00	Unregistered
29336dc3-b909-4d34-9ba3-5831d6069983	c1	Rajlaxmi Misthan Bhandar	Sundry Debtors	\N	\N	0.00	\N
dc2910cc-1dbc-4549-be85-5a1bc56a4450	c1	Raju Pan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
16f1a9be-71f6-4760-a92f-710dad9d6845	c1	Rajwada Sweets	Sundry Debtors	09AASFV0961D1ZV	\N	0.00	Regular
a1a9e7ea-2483-4c36-977f-82ecfc946adc	c1	Rakesh Store	Sundry Debtors	09ABMPC6260D1ZT	\N	-728.00	Regular
22b4f123-20d0-4e37-bd37-72f88004ac52	c1	Rakesh Traders	Sundry Debtors	\N	\N	0.00	Unregistered
572ffd89-c38e-43d3-872f-ff400239a232	c1	Rakes Provsion Store	Sundry Debtors	09AACPU6407B1ZU	\N	1.00	Regular
7d3c798a-7e29-44bf-8d00-2ed80fc2644f	c1	Rama Electronics	Sundry Debtors	09APZPJ8770N1ZK	\N	0.00	Regular
4a99efb1-4f5e-4b8c-8e61-4a10f35ee30f	c1	Rama Hospital Canteen	Sundry Debtors	\N	\N	0.00	Unregistered
c176a42d-ad05-4bab-8be8-17421080cc6a	c1	Rama Ji Store	Sundry Debtors	\N	\N	0.00	Unregistered
6ac93fbe-cb5b-4e3c-8e89-5a392f609d37	c1	Rama Store	Sundry Debtors	\N	\N	0.00	Unregistered
0c3c5052-1209-4736-bade-bdc0bf55c5cd	c1	RAMA VISION LIMITED	Sundry Creditors	\N	\N	0.00	Unregistered
40109a5c-ec55-424a-a2ca-85f687b05244	c1	Ram Chand	Sundry Debtors	\N	\N	0.00	Unregistered
3de89be1-5d4e-4245-9b0c-0d8f789f634f	c1	Ram Chandani &amp; Sons.	Sundry Debtors	09ABQPR3261D1ZF	\N	0.00	Regular
9dd3dc6e-9603-4155-8be2-88e31235d87c	c1	Ram Chander	Sundry Debtors	\N	\N	0.00	Unregistered
e04ce727-770b-468f-adee-e8d7914e2f60	c1	Ram Chandra Petha &amp; Confationery	Sundry Debtors	\N	\N	0.00	Unregistered
1533f096-b54e-42a3-a9a5-f025bff0122a	c1	Ram Cornor	Sundry Debtors	\N	\N	0.00	Unregistered
055504cc-ab68-4a30-8749-9ba7ba3ed136	c1	Ram Das Ram Mohan	Sundry Debtors	09AAVPG2266P1ZV	\N	-20460.00	Regular
0871ef99-28b3-4be3-8ff5-ee2df5e4e233	c1	RAMDEV AGENCIES	Sundry Creditors	07ABGPD4079D1ZX	\N	0.00	Regular
f13bcc10-0d3c-4c7e-86f9-e4d1084fa0dd	c1	Ramesh Banarsi Pan &amp;  Moctail	Sundry Debtors	\N	\N	0.00	\N
c5ea1d7b-34a5-490b-8a1b-8aca94cb9772	c1	Ramesh Chand Paan Shop	Sundry Debtors	\N	\N	0.00	\N
0b3f5111-f60b-4bd4-9669-f23780ca8b96	c1	Ramesh Chandra Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
74c3d3af-ad0b-48cd-86d7-6e09198eea17	c1	Ramesh Kumar IIT	Sundry Debtors	\N	\N	0.00	Unregistered
c7e931bb-a35c-41ae-87a5-70e19890b60c	c1	RAMESH KUMAR SURESH CHAND	Sundry Debtors	\N	\N	0.00	Unregistered
0ef8a8af-5e12-4bcb-af46-c1955009a74b	c1	Ramesh Kumar Tejumal Depart.Store	Sundry Debtors	09AAFFR8216E1Z6	\N	-31383.00	Regular
d7505123-b642-461b-ab2a-21fd73656f3e	c1	Ramesh Provision Store	Sundry Debtors	\N	\N	0.00	\N
392a9dce-b7cb-44b9-be11-c5e00efd964e	c1	RAMESH STORE	Sundry Debtors	\N	\N	0.00	Unregistered
cc9c8b64-e2af-42ab-9e4c-49ea1e430304	c1	Ram Misthan Bhandar	Sundry Debtors	\N	\N	-22787.00	\N
3ea3848b-8b60-4b4a-9ba8-130c1c58c404	c1	Ram Nath Khandelwal &amp; Sons	Sundry Debtors	09ADKPK9601L1Z3	\N	-7315.00	Regular
8dc4a406-f747-4599-9af8-39a1589dac1f	c1	RAM PRAKA SURAJ PRAKASH	Sundry Debtors	09AIVPG4492R1Z2	\N	0.00	\N
4a997089-dde1-43fd-beca-7d0f7738401a	c1	Ram Raja	Sundry Debtors	\N	\N	0.00	Unregistered
349b17c7-89c3-4f81-8665-027fce5045a5	c1	Ram Sarup Ronak Ram	Amazon Debtors	02ABHPG6320M1ZW	\N	0.00	Regular
4e3fbaec-40a3-4318-886e-a0e8e8184a51	c1	Ram Store	Sundry Debtors	\N	\N	0.00	Unregistered
d4eddeba-b5f2-4012-a713-1b89c5a7a111	c1	Rangan Chakravarty	Amazon Debtors	19ADZPC6530B1ZI	\N	0.00	Regular
84f1f9ca-9b3a-4dcb-8cce-0023224b950d	c1	Ranjan Service Station	Sundry Debtors	\N	\N	0.00	Unregistered
783ce3bd-1278-457a-bc37-8422dca1f558	c1	Ranjeet Store	Sundry Debtors	09ACGPS4292N1ZS	\N	-6930.00	Regular
9601c3f7-5579-41f0-ab21-707159d83c99	c1	Rasheed Pan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
f9e689db-b046-4f5c-afed-51a1b8c9194a	c1	Rasik Gupta	Sundry Debtors	\N	\N	0.00	\N
d4fcfa35-b33b-43a2-9f76-d893a7bf521f	c1	Rate Diff	Indirect Incomes	\N	\N	0.00	\N
a452f5e0-e702-4071-9f77-6c50dad99808	c1	Rate Diff 18%	Indirect Incomes	\N	\N	0.00	\N
2d405ff6-aba3-4b9b-b22c-9c493a7a5ccf	c1	Rate Diff 28%	Indirect Expenses	\N	\N	0.00	\N
ff3042d9-d507-4902-b8bb-55d85d0db6f7	c1	Rate Diff 5%	Indirect Incomes	\N	\N	0.00	\N
23cc2a54-522f-49c4-907b-6d214ddf1f7f	c1	RATE DIFF @12% /5%	Indirect Expenses	\N	\N	0.00	\N
a41b55ca-9ce4-402e-adc7-d42c3afba4ca	c1	RATE DIFF @12 % GURU FOOD	Indirect Incomes	\N	\N	0.00	\N
09ed3fde-c83c-4fc0-bb63-4546dafd09e1	c1	RATE DIFF @5 % GURU FOOD	Direct Incomes	\N	\N	0.00	\N
96993da9-41ed-47d5-9090-918236f8e4ba	c1	Raunak  Ahuja	Sundry Debtors	\N	\N	0.00	Unregistered
212abb6a-4f17-41e8-8e37-a5f728b0e5e3	c1	RAVE@MOTI ENTERTAINMENT PVT.LTD.	Sundry Debtors	09AACCR9012N1Z0	\N	0.00	Regular
d972ccea-1b27-4f97-bce1-897573da4147	c1	Rave Moti@entertainment Pvt.Ltd.	Sundry Debtors	\N	\N	0.00	Unregistered
3c4ceed2-9afc-473f-bc0a-3df55cd5b29e	c1	Rave Real Estate Pvt.Ltd.	Sundry Debtors	09AADCR9766L1ZI	\N	-17287.00	Regular
ec13b48a-42d9-4bde-9c16-9c3c6e0f1874	c1	R D Enterprises	Sundry Creditors	07AXNPG2491D1ZI	\N	0.00	Regular
a876183d-4185-4391-a820-a61a977b9a7e	c1	R &amp; D HOSPITALITY	Sundry Debtors	09ABIFR1706R1ZL	\N	0.00	Regular
e02591ca-d990-4e50-8a38-671524906ea2	c1	REALTA VENTURES PVT. LTD	Sundry Creditors	27AALCR2337M1ZX	\N	0.00	Regular
3c60b45b-eef5-4ff3-9b4e-fa0c210f8d97	c1	Rebate &amp; Discount A/c	Indirect Incomes	\N	\N	0.00	\N
a37839d8-479d-4060-afac-84162337bf6b	c1	RED ORCHID	Sundry Debtors	09ARIPJ1974D1ZQ	\N	0.00	Regular
13b110df-46d7-44a2-a415-54e494ab10c7	c1	RED ROSE INTERNATIONAL	Sundry Debtors	\N	\N	-2443.00	\N
1ad18a40-502f-4ff2-8d36-34e8f62f6c7e	c1	Refund Processing Fees Amazon	Indirect Expenses	\N	\N	0.00	\N
f9743ec8-b5cc-4e1b-9886-6a511470185f	c1	REGENTA M FOODS	Sundry Creditors	24AHTPA0223D1Z1	\N	0.00	Regular
c4fa7ad4-2ebe-4cb4-ae8d-c8bf4afe65eb	c1	Reliance Media Works Ltd.	Sundry Debtors	\N	\N	0.00	\N
5f555b94-0a06-4def-b626-01b29acdf2fb	c1	Reliance Medical Works Ltd.	Sundry Creditors	\N	\N	0.00	\N
72364142-c928-4463-95cc-27730a365f99	c1	Rent	Indirect Expenses	\N	\N	0.00	\N
36ddf25d-19d7-4f93-8153-5233ae20791a	c1	Rent Payable	Provisions	\N	\N	0.00	\N
06148b98-073c-4e89-bc6a-90966511f8e0	c1	Rent Security	Deposits (Asset)	\N	\N	-7000.00	\N
79b52bf7-136b-4050-890b-efbba9955530	c1	REWANT HOSPITALITY PVT.LTD.	Sundry Debtors	09AABCR1442H1ZK	\N	450.00	Regular
6d4dc499-98ab-48a6-b655-168711e5c5b7	c1	Riddhika Enterprises	Sundry Creditors	09ASZPP5351Q1ZF	\N	0.00	Regular
341c32a9-0e94-4591-b91c-1ea9f0d664e6	c1	Rimjhim Ispat Limited	Sundry Debtors	09AAACR6582K1ZV	\N	0.00	Regular
3d85524a-d367-403b-8ccd-04dd218c0cba	c1	Rishabh	Sundry Debtors	\N	\N	0.00	Unregistered
8e6ec275-37b0-46bc-99fd-4c4c1ff4715c	c1	RISHABH JAIN	Sundry Debtors	\N	\N	0.00	\N
6333ff09-2889-46aa-9ec6-a2bd39b6bce9	c1	RITIKA ENTERPRISE	Sundry Debtors	\N	\N	0.00	\N
0ab83050-2228-4e17-b5fb-6b356df4bb14	c1	RITIKA SALES CORPORATION	Sundry Creditors	07ADQPG1099N1ZX	\N	0.00	Regular
9221fc55-aa33-46ed-8994-f4bdd33e2d27	c1	Ritik Enterprises	Sundry Debtors	09AHSPD5221H1ZB	\N	0.00	Regular
8d16b87f-1f24-4be1-9209-c4412dc46e52	c1	Ritusha Consultants Pvt Ltd.	Amazon Debtors	09AACCR6885K1ZN	\N	0.00	Regular
a65d42f6-3ad0-40b8-a707-e34081353173	c1	Rivigo	Creditors Others	06AAFCT0838F2ZH	\N	0.00	Regular
4f6492ae-c693-4dc2-aaba-4681ed81ebd9	c1	Riya Ayurvedic Store	Sundry Debtors	\N	\N	0.00	Unregistered
d3d332e6-543f-4595-b871-6d49bde4efe1	c1	Riya Store	Sundry Debtors	\N	\N	0.00	Unregistered
ebde102c-19d8-427e-b1c0-3907f4baffed	c1	Riya Traders &amp; Spices	Sundry Creditors	\N	\N	0.00	\N
a0755797-8f4d-46b1-8c62-42c3d0493291	c1	R.K AGENCY	Sundry Debtors	09CMXPP1897H1ZZ	\N	-2300.00	Regular
a9ab6506-f64c-4022-b7cc-d8a2b334ecd4	c1	R. K. ENTERPRISES	Sundry Creditors	09AENPC7388C1Z9	\N	0.00	Regular
2bd00092-b103-449f-b47d-10d289273408	c1	R M HERITAGE AND HOTELS PVT.LTD.	Sundry Debtors	09AAFCR7408F1ZA	\N	-77378.00	Regular
20f0af6d-b14e-4bfa-9769-368d226d5697	c1	ROHINI TRADING &amp; MARKETING	Sundry Debtors	09AHAPG4997M1ZQ	\N	0.00	Regular
3e17bd14-676e-4093-a708-f1952abee0f2	c1	Rohit Store	Sundry Debtors	\N	\N	0.00	Unregistered
fb7e3ec5-647c-450c-b926-cf9a42ed7f00	c1	Rohit Vedio CD Library	Sundry Debtors	09AGDPN9883F1ZU	\N	-1800.00	Regular
7405c014-e101-4de6-b679-e6644c9fd056	c1	Rojus Cafe	Sundry Debtors	09AACCS7773F1Z0	\N	0.00	Regular
63684575-8118-4d31-9ef9-437a30ac3a2f	c1	ROMA TRADERS	Sundry Creditors	09BFFPS6017G1ZA	\N	0.00	Regular
beff5986-caea-43f5-9691-d6d6a7be7d0a	c1	ROOSI BROTHERS	Sundry Debtors	09ADAPC6619A1Z4	\N	0.00	Regular
6dbbfeb4-b794-49d2-bb47-c2d9411b5492	c1	Rose Merry Ice Cream Parlour	Sundry Debtors	\N	\N	0.00	\N
d90df02e-13d0-4fd3-85fa-43733c8573a1	c1	Rose Wood	Sundry Debtors	\N	\N	0.00	Unregistered
bedd86a7-faa0-4607-b3a4-95357126a7a1	c1	Roshani &amp; Company	Sundry Debtors	09AUJPS8358N1ZH	\N	0.00	Regular
0f7deac6-a522-4ab0-b542-8f0acde27eaa	c1	Roshani Store	Sundry Debtors	\N	\N	0.00	Unregistered
632b4f0c-1c20-4d7a-b545-a5ae1fc55633	c1	Round Off	Indirect Expenses	\N	\N	0.00	\N
5f2fbf88-e3d2-4077-9c24-7367ea6ad692	c1	Roxy Gernal Store	Sundry Debtors	\N	\N	-1450.00	\N
2c0d0380-ff49-4329-bc9b-99deba329a07	c1	Royal Bakery	Sundry Debtors	\N	\N	0.00	Unregistered
967b16bf-2d96-4ba7-b58b-4b81389a3443	c1	Royal Surgical	Sundry Debtors	\N	\N	0.00	Unregistered
c8e164e9-6c21-4562-83f4-67154a5e9ea0	c1	Royal Surgical &amp;Medical	Sundry Debtors	09AKGPB5718E1ZE	\N	0.00	Regular
5a67bb86-01e5-491a-bb3f-8c0635190c0d	c1	Roy Delight	Amazon Debtors	10BRIPR7350G1ZU	\N	0.00	Regular
f73079e4-65fa-48ba-93e5-a5e1c24338a2	c1	R.P.C.FOODS	Sundry Creditors	07AAIFR6992E1ZS	\N	0.00	Regular
5b67e9e4-159d-478c-801f-3f1f4516ebac	c1	RPC FOODS PRIVATE LIMITED (Haryana)	Sundry Creditors	06AAGCR8209M1ZZ	\N	-1416.00	Regular
33eb6d90-5e21-4fec-9319-fac62c846212	c1	RPC FOODS PRIVET LEMITED ( New Delhi)	Sundry Creditors	07AAGCR8209M1ZX	\N	0.00	Regular
43561881-ae41-4b28-9ec0-422a16d5222f	c1	R.P.ENTERPRISES	Sundry Creditors	09ABCFR0160K1Z7	\N	0.00	Regular
7d07f9dd-984c-47db-aa22-cbfd916a0c92	c1	R P Gourmet Foods Pvt.Ltd.	Sundry Creditors	07AAECR2739Q1ZS	\N	0.00	Regular
6aa6c141-7d03-4e6a-b336-b107efe5a523	c1	R.R. Foods	Sundry Debtors	09ABFFR2104L1Z6	\N	-52228.00	Regular
330664a8-b735-4074-8f52-239c84f54974	c1	R.S. AGENCIES	Sundry Creditors	09KJMPS4256K1Z7	\N	0.00	Regular
2d956752-9825-4993-9cba-c7128bf43c2b	c1	R.S  Creation	Sundry Debtors	09ADQPT1587Q1Z9	\N	0.00	Regular
5b91ba37-f7ff-450e-95e4-bc87ad9853f9	c1	R S Electronics	Sundry Debtors	\N	\N	0.00	\N
b269abf5-bf79-4a96-9eaf-c00e0b447051	c1	R S Engineers and Consultants	Amazon Debtors	19AAQFR3165D3ZW	\N	0.00	Regular
680ffde1-0169-4817-a426-1a40c5fa24c5	c1	R S FOOD	Sundry Debtors	09HHZPS9816R1ZG	\N	0.00	Regular
b54b4fe6-ef28-47f3-bd38-7806c8e088ec	c1	R.S.Hospitality	Sundry Creditors	09AARFR5707L1ZH	\N	0.00	Regular
fcebf307-2353-4fb5-96a4-dc54acd4d010	c1	Rspl Limited	Sundry Debtors	\N	\N	-5700.00	\N
319a3f5e-b7aa-4f67-b1cb-2b5276ed2980	c1	R S Solution	Sundry Debtors	\N	\N	0.00	\N
5395c400-a18d-4bee-aacb-b917b3910052	c1	Ruchi General Store	Sundry Debtors	\N	\N	0.00	Unregistered
8210bd34-b986-4a87-92ca-d149f07cb498	c1	Ruchima	Sundry Debtors	\N	\N	0.00	Unregistered
0883bffb-4859-49de-ad44-4ec9288ce86a	c1	Rudra Filling Station (Prabudh Shukla)	Amazon Debtors	23ASGPS8174D2ZK	\N	0.00	Regular
05a928e8-910c-4815-b3a4-8a6d4818fe59	c1	RUPESH AGENCIES	Sundry Debtors	09EBEP39043A1ZK	\N	0.00	Regular
efa90e4d-eabe-4afc-83a0-d50f83c85188	c1	R.V. Logistics	Creditors Others	07BKWPS9950G1Z6	\N	0.00	Regular
a03d1374-1b93-4cce-9449-e36a0dcbc697	c1	SAAR MERCANTILE	Sundry Creditors	\N	\N	0.00	Unregistered
aac6c30e-7898-4c32-839b-1ba54aa82584	c1	Sachin Traders	Sundry Debtors	\N	\N	0.00	Unregistered
733f0b62-7bbb-4765-88fb-f1734fdd8ba1	c1	SADHIK INTERNATIONAL	Sundry Debtors	09AIFPA9885L1ZL	\N	-1320.00	Regular
e7611257-ec33-4692-9b60-9ca0fd9109ad	c1	Sadhna Stores	Sundry Debtors	\N	\N	0.00	Unregistered
119aa6f6-d597-4843-8caa-1ee4265fca9d	c1	Safe Harvest Pvt Ltd.	Amazon Debtors	36AAMCS8705P1ZI	\N	0.00	Regular
efe75c2a-d1aa-49f3-9acd-49a7f66fc471	c1	SAFE &amp; SECURE LOGISTICS PRIVATE LIMITED	Sundry Creditors	27AAGCS5100E1ZR	\N	0.00	Regular
5821b45c-89a9-4c0b-a690-064a08e4ae1b	c1	Sagarika Exim Private Limited	Sundry Creditors	07AAQCS2811J1Z4	\N	0.00	Regular
721ac4cb-5ea6-4a21-bc56-5edc49c2317f	c1	Sagar Verma	Sundry Debtors	\N	\N	0.00	Unregistered
4ba3077c-9a79-419a-aaeb-3bb7ecbfdaea	c1	Sahani Medical &amp; General Store	Sundry Debtors	09ABQPS6134A1ZI	\N	-678.00	Regular
ca9b4630-39dc-4d0e-93cd-b35540eee929	c1	Sahara Departmental Store	Sundry Debtors	\N	\N	0.00	Unregistered
f7073659-e32a-4aa5-ba3b-458efdf0a1ca	c1	Sahitya Baba Traders	Sundry Debtors	09ADRPT3147K4ZP	\N	1605.00	Regular
9b13a663-05ba-4b09-9be1-65437bacaaaf	c1	Sahu Home Appliances	Sundry Debtors	\N	\N	0.00	\N
514c701d-09be-425c-9e50-11c6356b01cf	c1	Sai Bakers (Bareilly)	Sundry Debtors	\N	\N	0.00	\N
f468f22d-086e-465f-836f-d46a672c530c	c1	SAI CIBO INDIA PVT LTD	Loans & Advances (Asset)	07AAUCS3638K1ZN	\N	0.00	Regular
2db659e1-2af3-494b-aad5-5cbe7b431903	c1	Sai Cibo India Pvt Ltd (Haryana)	Sundry Creditors	06AAUCS3638K1ZP	\N	-10079.00	Regular
920ee52a-3d12-46c0-84ce-efb5065a8922	c1	Saif Faisal Design Workshop	Amazon Debtors	29FUDPS7870G2ZV	\N	0.00	Regular
fc7a7082-fade-46a0-a471-0211bdcf1442	c1	Sai Gernal Store	Sundry Debtors	\N	\N	-2800.00	\N
f2345c01-81ac-49f8-94e9-4f6825ac4af4	c1	Sai Global	Sundry Creditors	07ABSFS6728E1ZP	\N	0.00	Regular
cb18d0dc-648c-4cda-9ef4-7dfbf0620c7a	c1	Sai Global Haryana,	Sundry Creditors	06ABSFS6728E1ZR	\N	0.00	Regular
ab60fcbe-6628-4242-adbb-d89a254112fe	c1	Sai Marketing	Amazon Debtors	36ABRPB6033G1ZR	\N	0.00	Regular
b6e59946-8a79-4be2-8ca1-074b7e4689f8	c1	Sai Medical	Sundry Debtors	\N	\N	0.00	Unregistered
a9c3cd44-95e3-4f30-ade4-8182141a9f2a	c1	Sai Ram Areca Products	Amazon Debtors	33AMHPB9561E1Z9	\N	0.00	Regular
9e05133d-2275-4165-aa8f-89e478b330c9	c1	Sai Trading	Sundry Debtors	\N	\N	0.00	\N
edaa476f-fe7f-40c6-b1c9-e567e4252f85	c1	SAI TRADING COMPANY	Sundry Creditors	09AIYPK4311Q2ZE	\N	0.00	Regular
1ffd23aa-a113-48f5-a60a-0eaa5a37c884	c1	SAJJAD ENTERPRISES	Sundry Creditors	\N	\N	0.00	\N
7f42f5de-bf98-4a1f-bca3-7a5cc6fb0e6e	c1	Salary	Indirect Expenses	\N	\N	0.00	\N
00cad02e-b26b-4fe7-995f-ea1a4df34747	c1	Salary Payable	Provisions	\N	\N	0.00	\N
3d1b7e88-8e4c-408d-a190-409900191aff	c1	Sale of Space for Advertisement on Amazon	Indirect Expenses	\N	\N	0.00	\N
3f520181-5dd1-4eff-9d89-7d90c5be354b	c1	Sales Korner	Sundry Debtors	09AGBPA2906N1ZI	\N	0.00	Regular
52c69e34-31bb-4aae-aea4-01bc3105f142	c1	Sales Promotions	Indirect Expenses	\N	\N	0.00	\N
3226f36e-fc4e-4dc0-adcb-59c747380d6e	c1	Salman	Sundry Debtors	\N	\N	0.00	Unregistered
9a0082fd-098a-44a0-a354-4f554de9faa8	c1	Saluja Dairy	Sundry Debtors	\N	\N	0.00	Unregistered
e568ba6f-5c14-42ab-a7d6-3561ea88ce04	c1	Samarpan Arts And Handicrafts	Amazon Debtors	08AFUPJ7283B1Z3	\N	0.00	Regular
7f218427-8fae-470a-828b-62a7f60385d1	c1	SAMIS DELI (CLOUD KITCHEN)	Sundry Debtors	\N	\N	0.00	Unregistered
e66f2292-db37-4ed6-9ab7-a7bc51af9c47	c1	Samocha Ventures Pvt Ltd	Sundry Debtors	09ABCCS0055R1ZW	\N	0.00	Regular
7e9a8147-2606-4555-8f00-ae1b2476ec8a	c1	Sampels	Sundry Debtors	\N	\N	-28.00	\N
361357a3-1326-4192-8f7a-d890ab720f8d	c1	SAMPOORN MARKETING	Sundry Creditors	\N	\N	0.00	Unregistered
2790b44a-2648-4a1e-ab44-514e53fd5134	c1	Samriddhi Store	Sundry Debtors	\N	\N	0.00	Unregistered
6d5f4317-be95-44cf-8292-81fced6d9ac1	c1	Samridhi Caterors Kanpur University	Sundry Debtors	\N	\N	0.00	Unregistered
dcf254c0-6cd0-43c0-ba46-99c5adb40972	c1	Sangam Pan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
b27928da-8fc4-475d-b3b8-14f1edc3d69a	c1	SANI STATIONAR	Sundry Debtors	\N	\N	0.00	Unregistered
ef2aa318-132b-4763-b086-1f6b00562181	c1	Sanjay Bakery	Sundry Debtors	09AOLPB3487R1Z4	\N	0.00	Regular
ced734ea-b05f-49e6-a4d2-3f41bc6da120	c1	Sanjay Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
be01689e-8311-458f-9533-d4a6791e59e7	c1	Sanjay Ji	Sundry Debtors	\N	\N	0.00	Unregistered
508e10d7-023b-4e14-9b74-d20b277e484e	c1	Sanjay Kirana Store	Sundry Debtors	\N	\N	0.00	Unregistered
694f5376-d970-48b9-9cf6-ebf2e4a250e0	c1	Sanjay Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
9293d693-5a12-4248-801b-186d203110d0	c1	Sanjay Mehrotra	Unsecured Loans	\N	\N	0.00	\N
6fd2754e-11c4-45ee-98e5-28161f5d588d	c1	Sanjay (Online Transfer)	Sundry Debtors	\N	\N	0.00	Unregistered
2bcaf712-d2bb-42b4-856e-c0a82a567e67	c1	SANJAY PHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
a30468b9-c696-4711-9b0b-568d441e5871	c1	Sanjay Tandon	Sundry Debtors	\N	\N	0.00	Unregistered
43773e58-07fe-4061-ae31-65f88a9c307f	c1	Sanjeet Traders	Sundry Debtors	\N	\N	0.00	Unregistered
df03c385-3f06-4c20-a87d-9f3d979dfde3	c1	Sanjeevani Medical Store	Sundry Debtors	\N	\N	0.00	Unregistered
d4af2f4b-b3db-41de-b134-f1c6ed739d19	c1	SANT TRADERS	Sundry Debtors	09GHVPS1912M1ZE	\N	0.00	Regular
eafec541-70e4-4a53-bbf6-c456f2732549	c1	Santusht Stores	Sundry Debtors	09ACVPK6795M1ZB	\N	0.00	Regular
8bec3b8e-8cc3-4c27-8036-42574bbed90c	c1	SANZYME (P)LTD.	Sundry Creditors	\N	\N	0.00	Unregistered
332e6e3f-06f2-420f-88df-bef9973268f8	c1	Sapna Store	Sundry Debtors	\N	\N	0.00	Unregistered
4454bf92-a682-48a6-a483-a01e0cac3a2f	c1	Sarala Agencies(Birhana Road)	Sundry Debtors	09ACMPK8365Q1ZI	\N	0.00	Regular
d2288068-bcb0-459e-af26-2f2456397e08	c1	SARALA AGENCIES (SYSTEM)	Sundry Creditors	09ACMPK8365Q1ZI	\N	0.00	Regular
011f57c5-8993-48be-a519-f61e99d1ba0c	c1	Sarala Electronic	Sundry Debtors	\N	\N	0.00	Unregistered
8dc61388-d0cd-444d-ab6f-fa5b18490035	c1	Sardar Radio Watch Company	Sundry Debtors	\N	\N	0.00	Unregistered
c983eae2-8222-4c98-ba51-cec3f3017b68	c1	Sargam Aahar	Sundry Debtors	09BUMPM3409E1ZK	\N	0.00	Regular
b59907a2-8e26-4675-8e02-32151f8a5a21	c1	Sarla Agencies	Sundry Debtors	09DABPS7070C1ZN	\N	-3751.00	Regular
eb418915-4d5a-4e45-b3fd-5c794989ae81	c1	SAROJ KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
5df4f47f-0ba4-4678-970e-6fc460bbd42e	c1	Sarover Hotels Pvt.Ltd.	Sundry Debtors	09AAACS8083L1ZS	\N	0.00	Regular
fa5933fb-83bb-476a-adb2-1f8aaa38a1f7	c1	Sarveshwari Agencies	Sundry Debtors	\N	\N	0.00	Unregistered
f75933a5-e1be-4e7a-ac65-92b2233d5ec5	c1	Satiya Nutraceuticals Private Limited	Amazon Debtors	27ABDCS4338J1Z3	\N	0.00	Regular
27810cbe-fa80-4335-9610-62d83686ec06	c1	Sa Traders	Sundry Debtors	\N	\N	0.00	Unregistered
98f4ed8a-3bf4-4c5d-ad60-4557d3854290	c1	SATVIK CONSULTANTS PRIVET LIMITED	Sundry Creditors	\N	\N	0.00	Unregistered
3cc33641-190e-4629-a735-d82c80e545ca	c1	Satyam General Store	Sundry Debtors	\N	\N	0.00	Unregistered
bb57b95f-5339-408f-8aae-4d4656dfcb56	c1	Satyam Kirana Store	Sundry Debtors	\N	\N	0.00	Unregistered
a879c0ef-40e0-4896-aa8f-86da913b3b08	c1	SATYA SHIV AGENCY	Sundry Debtors	09ACRPR2105A1ZT	\N	0.00	Regular
c40aa0a0-28ff-49dc-86c7-e66ea01373a7	c1	Satyendra Srivastava	Sundry Debtors	\N	\N	0.00	Unregistered
4484817e-832b-4d01-8a2a-81404bf8ef4d	c1	Saurabh Malhotra	Sundry Debtors	\N	\N	0.00	Unregistered
d8c1b5fe-536b-4f84-8484-8e8ac840e6cf	c1	Saurabh Mehrotra	Unsecured Loans	\N	\N	0.00	\N
8872ff02-27dc-48a5-8cf2-d57690c7a90f	c1	Savannah Lifestyle Private Limited	Amazon Debtors	27AAJCS3735N2ZR	\N	0.00	Regular
03c13687-7c7d-43b3-9816-39a1708e8078	c1	Savri	Sundry Debtors	\N	\N	0.00	Unregistered
6a436c11-ecf7-4c2f-a8e3-95e3e8f86700	c1	S.B.B.J INTERPEISES	Sundry Debtors	\N	\N	0.00	\N
3cb49eb6-6f7d-48c8-9415-43a71e534a9b	c1	S B Castle Pvt.Ltd	Sundry Debtors	09AAKCS5715M1ZR	\N	0.00	Regular
3b2e691e-9c8a-4ed0-ae57-eb290fe9ba3e	c1	Sbi Car Loan	Loans (Liability)	\N	\N	414671.00	\N
183ebf2f-af81-484e-9ff3-6b5503c3be1a	c1	Scentials Beautycare And Wellness Pvt Ltd.	Sundry Creditors	27AAZCS6251R1Z3	\N	108596.00	Regular
00224b3c-4bb8-46b5-9187-5d797a82b2dd	c1	Scheme and Incentive	Indirect Incomes	\N	\N	0.00	\N
328b4417-e602-4fee-9ca7-11a718e4d578	c1	Scooter ( Eterno )	Fixed Assets	\N	\N	-1812.00	\N
3740d89b-2e7b-4123-94be-9e735d3b15ec	c1	Scooty Maintanance	Direct Expenses	\N	\N	0.00	\N
00311670-6880-4f70-bbf2-fcfc7acbd761	c1	S.C TRADING CO.	Sundry Creditors	09CCKPP0615C1ZT	\N	0.00	Regular
a6898e11-e9b2-443e-a416-95e79d9b6d1c	c1	SDN ENTERPRISES	Sundry Creditors	09CPUPS5254R1ZH	\N	0.00	Regular
4f971740-6a79-4528-b241-7accb7d3440d	c1	Seema Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
3daab71c-52d4-492b-a885-7db2b00f8507	c1	Sehgal Store	Sundry Debtors	\N	\N	0.00	Unregistered
ccb8f85c-b23a-4eb6-a403-70b2e989deee	c1	Select Walk	Sundry Debtors	\N	\N	0.00	Unregistered
b289ba91-76fb-4ad2-bf01-7dda83741881	c1	Self	Sundry Creditors	\N	\N	0.00	\N
c9199a08-b31f-489a-9525-f6c3662e30f0	c1	SEPOY BEVERAGES LLP	Sundry Creditors	\N	\N	0.00	\N
12f9f39b-1c2f-41a5-84db-18a51c8af2d5	c1	Sepoy Sample	Indirect Incomes	\N	\N	0.00	\N
d0dde568-d981-4818-821b-bd9c446761aa	c1	SERAH ENTERPRISES	Sundry Creditors	33LWUPS6788J1Z2	\N	0.00	Regular
72f7d674-fb9b-44e5-87d2-7f72a6693e44	c1	SETH RAM MOHAN SONS	Sundry Debtors	09AICPG0836E2ZN	\N	-29935.00	Regular
cad88a72-4dbd-4efc-bbd0-bb7b99d57dac	c1	Sevak Brothers	Sundry Debtors	\N	\N	-2466.00	\N
c63fe450-0a55-4ade-b6c2-307803324754	c1	Seven Ten Mini Store	Sundry Debtors	\N	\N	0.00	Unregistered
2639bf81-cb3c-481d-a24c-615df38eb9b6	c1	Sewak Brother&apos;s	Sundry Debtors	\N	\N	0.00	Unregistered
6bfbc9b1-9d38-4338-96ca-0329a73613f1	c1	Sewak Brotrhers	Sundry Debtors	\N	\N	0.00	Unregistered
14f89244-b8b6-4a80-b3a5-edc2484bde47	c1	S.G.H GOURMET FOODS	Sundry Debtors	09HSQPS1496K1ZK	\N	0.00	Regular
05a1b447-6501-4492-b342-fe57c4d2f6f6	c1	S G K Global Scientific	Amazon Debtors	29COGPK4611D1Z5	\N	0.00	Regular
0b250062-e2a1-45d7-acc6-e407f489d41e	c1	Sgst Cash Ledger	Loans & Advances (Asset)	\N	\N	0.00	Unregistered
2881c165-fc77-47b1-a905-f99d8fd68744	c1	Sgst Payable	Duties & Taxes	\N	\N	0.00	\N
ded4dea9-b068-4682-8bb7-49ed6ef0d8fa	c1	Sgt Hotels PVT LTD.	Amazon Debtors	09AAVCS1253M1ZN	\N	0.00	Regular
2e4654b7-a175-4e96-8131-c040c454eebe	c1	Shahanshah Foods	Sundry Debtors	09GFGPK7872R1Z8	\N	0.00	Regular
6610f84a-8d31-4c49-8cd4-6e5edde58b1f	c1	Shahid	Sundry Debtors	\N	\N	0.00	Unregistered
9813aec1-a1b9-47fd-a343-f086eb0af21c	c1	Shakeel Pan Shop	Sundry Debtors	\N	\N	0.00	Unregistered
23e527d3-da9e-48e4-a312-1233ebb95007	c1	SHAKTI AGENCIES (RETAIL)	Sundry Debtors	\N	\N	0.00	Unregistered
b663445a-8b26-48fe-95ed-38558a7e21d0	c1	Shakti Agencies Retail Medical Store	Sundry Debtors	\N	\N	0.00	Unregistered
859d8ced-a5a1-4fa3-ad12-b0fd96ece359	c1	Shakti Baikery	Sundry Debtors	\N	\N	0.00	Unregistered
58d7e09c-e049-49fe-bac3-0198af132003	c1	SHAKTI DEPARTMENTAL	Sundry Debtors	\N	\N	0.00	\N
d2cfe58d-228b-49ba-a2bb-661e80c0afb4	c1	SHAKTI DEPARTMENTAL STORE XXXXX	Sundry Debtors	09AQCPA2083K1ZY	\N	0.00	Regular
cb662e4a-887a-4ebe-9f1f-6598a5bdf947	c1	Shakti Store	Sundry Debtors	\N	\N	0.00	\N
80eba844-09d3-426f-8b8b-97d0bb88f2c5	c1	Shalini Gupta	Amazon Debtors	07AITPG7460R1ZA	\N	0.00	Regular
f135937c-fab8-46c2-9c9d-bd84445fc0a9	c1	Shamsi Traders	Sundry Debtors	09AAFPE3717R1ZB	\N	0.00	Regular
953c61fb-d8fe-4f77-a9b9-e49a89922433	c1	SHANGHAI CHINESE RESTAURANT	Sundry Debtors	09HBIPS5827K1ZS	\N	0.00	Regular
0bc7d7de-ad05-4c6d-b577-78b019afdc3a	c1	Shankar	Sundry Debtors	\N	\N	0.00	Unregistered
94345024-3a4b-4c6b-b0e9-27d4c8b64f71	c1	Shankar Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
418e6c7d-eb28-4d3d-a593-b21c36c83ca5	c1	Shankar Pan House	Sundry Debtors	\N	\N	0.00	Unregistered
fe21a6b4-f8cb-4569-a018-1520de225c20	c1	SHANKAR TRADING COMPANY	Sundry Debtors	09AAVPM5119M1ZX	\N	0.00	Regular
9bf88da6-936b-4c61-aea8-160110a3eb58	c1	SHANKER HERBAL CARE	Sundry Creditors	\N	\N	28011.00	\N
23c3d531-25e3-49d5-81b0-48e650903fb4	c1	Shanker Trading	Sundry Debtors	\N	\N	0.00	Unregistered
0a0c6ab1-4f6d-4103-8788-6d0749960a0f	c1	Shanti Traders	Sundry Debtors	\N	\N	0.00	Unregistered
d24d105f-3fce-4504-97e5-104a707435e1	c1	Sharma Enterprises	Sundry Creditors	\N	\N	0.00	Unregistered
60685064-2c76-43af-8251-37f50b708164	c1	She Cosmatics	Sundry Debtors	\N	\N	0.00	Unregistered
4b700c70-6cb9-459d-815a-014f48214e1f	c1	Sheer Cham India Pvt Ltd	Sundry Debtors	\N	\N	0.00	Unregistered
f93355d0-d40d-48b8-bd90-51b859063881	c1	Shefali Store	Sundry Debtors	\N	\N	0.00	Unregistered
fef11f2a-7359-4c1e-84a8-bae64864bd78	c1	She Novelties	Sundry Debtors	\N	\N	0.00	Unregistered
75edf88f-2fc7-42cb-a568-0a6794d1cadc	c1	Shipping Charges 0%	Indirect Incomes	\N	\N	0.00	\N
43af2775-916b-44b6-9328-94820eb88671	c1	Shipping Charges 12%	Indirect Incomes	\N	\N	0.00	\N
628c5375-97df-4410-a0f4-98480f59ea27	c1	Shipping Charges 18%	Indirect Incomes	\N	\N	0.00	\N
5f7cd037-2866-469d-9c9c-50d50e777012	c1	Shipping Charges 5%	Indirect Incomes	\N	\N	0.00	\N
c0232564-5b9b-4ec1-8337-a85fff236ebd	c1	Shipping Charges Amazon	Indirect Expenses	\N	\N	0.00	\N
1af1ae14-7e88-43a5-b3a7-4d33b6dc39dd	c1	Shipping Charges Up 0%	Indirect Incomes	\N	\N	0.00	\N
be92ec3d-06f2-409b-9ea0-afdc9568746b	c1	Shipping Charges Up 12	Indirect Incomes	\N	\N	0.00	\N
d44f8d93-5113-4cd9-9ab1-70b1eb99e5ae	c1	Shipping Charges Up 18	Indirect Incomes	\N	\N	0.00	\N
44e3c2ff-d653-4628-96a9-229af680a335	c1	Shipping Charges UP 5%	Indirect Incomes	\N	\N	0.00	\N
232a513a-b364-4c81-9a7c-715e9cde22dd	c1	Shipping Fees Amazon	Indirect Expenses	\N	\N	0.00	\N
6721e0d2-2d32-45b8-a812-59a200499b02	c1	Shipra Departmental Store	Sundry Debtors	\N	\N	0.00	Unregistered
4228e066-5dd0-4bb1-9bca-8018fc7ca6b3	c1	Shiri Balal Ji Marketing	Sundry Debtors	\N	\N	0.00	Unregistered
48e8630c-8234-45b6-9e3b-e7b9ae419f7c	c1	SHIVAAY FOOD	Sundry Creditors	\N	\N	0.00	\N
8203d60b-f114-4122-aae1-16f701f6a370	c1	Shiva Electricals	Sundry Debtors	09AAMPB2856K1ZF	\N	0.00	Regular
40624769-f735-4e48-8c04-50f683a44182	c1	Shivam Agencies	Sundry Debtors	\N	\N	0.00	Unregistered
df60f45d-4bdd-43cb-8fcd-52ceadb0aaac	c1	Shivam Auto Corp	Sundry Creditors	09ANGPG5577R1Z3	\N	0.00	Regular
86924b6c-2c7b-436a-be55-7b714197af91	c1	Shivam Bamba Road	Sundry Debtors	\N	\N	0.00	Unregistered
9c25f48e-9c41-4657-8456-df991d6a4ce3	c1	Shivam Marketing	Sundry Debtors	\N	\N	0.00	\N
1c3bb2d0-a2e4-4521-a46d-ff623a98fd0d	c1	Shivangi Pan Shop	Sundry Debtors	\N	\N	-1000.00	Unregistered
a6ccf71b-a3e1-4cd2-9ab5-abc4be995a57	c1	Shivani Cafe &amp; Restaurants	Sundry Debtors	09ACVPK6804H2Z3	\N	0.00	Regular
c47a3199-8893-4f41-8448-a23164815c17	c1	Shivani Store	Sundry Debtors	\N	\N	0.00	Unregistered
242ed791-0ff0-41b2-8684-f3bebe45c27f	c1	Shivanya Kirana Store	Sundry Debtors	\N	\N	0.00	Unregistered
ba703757-f353-4bbb-9f6b-ff7c4c205178	c1	Shiva Trader	Sundry Debtors	09AVOPS9310G1Z3	\N	0.00	Regular
f08a5ad8-430e-496a-bdef-fa0f41da321e	c1	Shiva Traders	Sundry Debtors	\N	\N	0.00	\N
d6dc2f9f-0aee-4556-b185-d2db1b516b2f	c1	Shiv Enterprises	Sundry Creditors	09AASPC4722H1ZM	\N	0.00	Regular
36d390e8-c687-4684-a7de-cc1c33d84314	c1	Shivi Enterprises	Sundry Creditors	09BBGPA0885F1ZT	\N	0.00	Regular
d14194b4-8886-46db-8d5e-5f566d876369	c1	SHIV KANTI	Sundry Debtors	09BGHPJ9579B2ZZ	\N	0.00	Regular
21406e26-70da-41c1-be1f-d58d0bd48ff8	c1	SHIV KRIPA	Sundry Debtors	09AQXPJ7927L1ZR	\N	490.00	Regular
6b6a8617-bab5-49bb-9848-d7bb29b4677b	c1	Shiv Shankar Book Stall	Sundry Debtors	\N	\N	0.00	Unregistered
8ba8a769-02f9-487f-aa0b-547a95d4fb92	c1	SHIV STORE CHEMIST	Sundry Creditors	07ADAFS6221L1Z0	\N	-8416.00	Regular
1711b4f2-b26f-4177-98cb-c1bbb0ec4942	c1	Shiv Store Exim	Sundry Creditors	07AAQHP8910C1Z0	\N	0.00	Regular
2228cd0a-5849-45c4-95ee-6d3de53bb073	c1	Shlok Ji Store	Sundry Debtors	\N	\N	0.00	Unregistered
8ba19469-0691-414b-a129-cd61037769c3	c1	Shobha Kirana	Sundry Debtors	\N	\N	0.00	Unregistered
c7d5abe5-5678-4df5-8fff-9dea137777ad	c1	Shoppers Choice	Sundry Debtors	09ADTPH8566Q1Z9	\N	-6784.00	Regular
ff70c26a-39bb-47f1-8165-d898bbf7568f	c1	Short &amp; Excess	Indirect Expenses	\N	\N	0.00	\N
0e5a7ca7-c32e-4fc5-a7c0-600ab57c1f26	c1	SHORT STOCK	Indirect Expenses	\N	\N	0.00	\N
f37f29fb-7b83-44b6-992a-f087a4fa490b	c1	Shree Annapurna Agencies	Sundry Creditors	09AACHH1416F1ZP	\N	0.00	Regular
814d0f38-b94c-4193-b0f0-fa849debd377	c1	SHREE ANNAPURNA BHANDAR	Sundry Creditors	09AEAPP3998J1ZU	\N	0.00	Regular
c4bf0509-8511-4145-8376-4eead07a281d	c1	Shree Ashutosh Roadways Corporation	Sundry Creditors	\N	\N	9506.00	\N
d916bc46-d1f8-4cfa-a109-76b8d9b6ec9a	c1	Shree Ashutosh Transport Company	Sundry Debtors	\N	\N	0.00	Unregistered
93c7382b-623e-4de5-9c28-1d14d34ca30b	c1	SHREE BALA JI MEGA MALL	Sundry Debtors	09AMCPK2410L1Z7	\N	0.00	Regular
9e866a81-9f43-4b7d-87d4-ba9972e05965	c1	Shree Balaji Surgical &amp; Medicals	Sundry Creditors	\N	\N	0.00	Unregistered
5c0fb950-0151-4fb9-bab3-4248177a5515	c1	SHREE BANKEBIHARI PHARMA	Sundry Creditors	09AOLPC3339M2ZL	\N	0.00	Regular
ebdc6d49-a59e-4120-8035-8e2febc8b5ea	c1	Shree Bhojnalay &amp; Restaurent	Sundry Debtors	09ABRFS2218J1ZQ	\N	0.00	Regular
4345bce1-b54d-42f9-9cbc-84c92bbfde88	c1	SHREE BIHARI JI SALES	Sundry Creditors	\N	\N	0.00	Unregistered
ad8ce2ee-4100-4d6a-ba84-b2604b4a8579	c1	Shree Brijwasi Sweet &amp; Restrarent	Sundry Debtors	\N	\N	0.00	Unregistered
6139a68b-25bc-447f-aa94-29ac43719c8b	c1	Shree Electricals	Sundry Debtors	\N	\N	0.00	Unregistered
d8caf4d2-9623-4cd9-b358-20d1b51ab164	c1	SHREE ENTERPRISES	Sundry Creditors	09AUKPK1478N1ZX	\N	0.00	Regular
1d307cb9-715e-4f47-a593-771395c2ba1f	c1	Shree Enterprises Distributors	Sundry Debtors	\N	\N	0.00	Unregistered
4156938a-0225-40f1-a4eb-bc0c41893345	c1	Shree Gajanan Industries	Amazon Debtors	36AAFFS1099A1ZD	\N	0.00	Regular
4e581386-1ca5-46b8-af35-67ad2fcdd53a	c1	SHREE GANESH TRADERS	Sundry Debtors	\N	\N	0.00	Unregistered
b6d80269-3bfe-46a0-92da-9f7d74a65b2a	c1	SHREE GANGA AGENCIES (Sitapur)	Sundry Debtors	09ACZPG2913P1ZT	\N	0.00	Regular
7d91203a-a6ca-4847-adc8-b74158828f48	c1	SHREE GANGA VALLY INFRA PROJECT	Sundry Debtors	09ACXFS4869A1ZG	\N	0.00	Regular
6eba1454-d081-49f3-a895-07e07e450c3c	c1	Shree Govind Agencies	Sundry Debtors	09ABOFS4418F1ZW	\N	0.00	Regular
6e8845ba-ffb7-4c19-864e-47f777d610b9	c1	Shree Ji Naturals	Amazon Debtors	09ADSFS7677N1ZO	\N	0.00	Regular
0ed01c44-a8ff-44f9-a8e8-dc3bbac319bd	c1	Shree Krishna Enterprises	Sundry Debtors	\N	\N	0.00	\N
e1d9e396-2caa-4370-8f21-9b67cc8568cb	c1	SHREE MAA STORE	Sundry Debtors	09BWWPJ8899M1ZW	\N	0.00	Regular
3bcb5636-6eb5-4a3f-a148-3d65c6b05b3c	c1	Shreem Shivaay Foods &amp; Bevarages Pvt Ltd	Sundry Debtors	09ABGCS8986D1ZP	\N	0.00	Regular
1bc019b1-051b-4276-a6a9-f97f7a06b8a1	c1	Shree  Multi Services	Sundry Creditors	27ANUPB8906F1ZQ	\N	0.00	Regular
d3846eaf-d6ee-4961-bcac-6c9cc520a750	c1	Shree Nath Electricals	Sundry Debtors	09AGBPA5116C1Z5	\N	0.00	Regular
5dc88098-4cfe-418f-afd5-98a5712365e8	c1	Shree Nath Ji Enterprises	Sundry Debtors	09ALIPG9557H1ZM	\N	0.00	Regular
d5a76fdf-c390-464b-9000-c859eccf7e2c	c1	Shree NSM Enterprises	Sundry Debtors	09ABVFS6554P1ZV	\N	0.00	Regular
b3351b29-56c7-41d8-98bb-d9c36f3d0283	c1	Shree Ram Sweet	Sundry Debtors	\N	\N	0.00	\N
17a51d2a-9ce9-491c-852d-b99cdc8286db	c1	Shree Retails	Sundry Debtors	09AEMFS1402A1ZG	\N	0.00	Regular
a22c47f6-e545-4160-9f90-1b11afdb0363	c1	Shree Shyamji Traders	Sundry Debtors	\N	\N	0.00	Unregistered
bd3fae17-fb63-4a4e-aa17-4ac9f626433f	c1	SHREE SHYAM MARKETING	Sundry Creditors	\N	\N	0.00	\N
cb80bdc6-eb42-45ef-9853-7f13d4d7c277	c1	Shree Somnath Trading Co.	Sundry Creditors	09ADIPL4569N1ZR	\N	0.00	Regular
f4ce6cd2-83ac-4297-bd9a-fe8420564929	c1	Shree Somnath Trading Company	Sundry Debtors	\N	\N	0.00	Unregistered
5c102544-8251-48ae-931c-2bfc0682236f	c1	Shree Swad Baikery	Sundry Debtors	\N	\N	0.00	Unregistered
99652dab-81d8-45bd-aabe-f750a056f655	c1	Shree Vishwakarma Udyog	Sundry Debtors	09AXPPS6907E1ZX	\N	0.00	Regular
c53f5f13-089d-4a59-b177-2210a9fc1cc7	c1	Shreya Enterprises	Sundry Creditors	09BQLPB5548N1Z9	\N	0.00	Regular
9838c2e2-c3bc-4aad-a39d-878fc730bb8b	c1	Shri Balaji Enterprises	Sundry Creditors	09BIXPA3864L1ZJ	\N	0.00	Regular
6faa305e-6024-4e5c-bdf5-92e76f7577fd	c1	Shri Balaji Infarstructure	Sundry Debtors	09ACSFS3945G1ZI	\N	-3476.00	Regular
d1fdcfcf-948f-4cd9-947a-c26a1fcc0e67	c1	SHRI BALAJI TRADERS	Sundry Creditors	\N	\N	0.00	\N
ac0d034c-60df-4f0a-9960-3589933cdf59	c1	Shri Bhawani Jewellers	Amazon Debtors	08DTOPS9908D1Z0	\N	0.00	Regular
f60aa391-22e0-44ad-a503-d899d6b3d7ad	c1	Shri Durga Fruit Co.	Sundry Debtors	09ADTPK4860E1Z6	\N	0.00	Regular
a1e77c83-fe9c-4add-af7a-c85b24d4bdbe	c1	Shri Hari General Store	Sundry Debtors	\N	\N	0.00	Unregistered
b184af23-a44c-49fb-b2ea-06b51c414ba5	c1	Shri Hari Om Industries	Amazon Debtors	03AAYPA9918R1ZT	\N	0.00	Regular
7b8dd1cd-1f9f-4a15-9d23-e3e18bab623b	c1	Shri Laxmi Store	Sundry Debtors	\N	\N	0.00	Unregistered
9e61544c-4121-4ffc-ba1b-ee3325d0a2db	c1	Shri Laxmi Stores	Sundry Debtors	09ARRPK6451H1ZA	\N	-13019.00	Regular
0c1ac06c-6790-4584-a6e8-ad0efafceb4c	c1	Shri Nath Electricals	Sundry Debtors	\N	\N	0.00	Unregistered
43ed6c05-cd72-48ac-9f04-dbafb6b90441	c1	Shri Rajkamal Bakers &amp; Sweets	Sundry Debtors	\N	\N	-5982.00	\N
3bd3b5c4-6c78-449c-bb8d-47ff78c65e9d	c1	Shri Ram Exim International	Sundry Creditors	07AANFS4301F1ZD	\N	0.00	Regular
555092cd-f97a-499f-be27-bb2d8f60da61	c1	Shri Ram General Store	Sundry Creditors	07AAGPA4299P1Z7	\N	0.00	Regular
869e49b2-0659-42f6-9c7d-f7d95910c2c5	c1	Shri Sai Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
984bed70-21a1-4e32-b56b-3507de315f30	c1	Shri Shakti Enterprises	Sundry Debtors	09ACUFS0968B1ZP	\N	0.00	Regular
6bd2e47e-fa6d-4581-9384-c5553297e2cd	c1	Shri Shani	Sundry Debtors	\N	\N	0.00	Unregistered
983f87ee-e050-4dbd-b2ae-5a7fce708546	c1	Shrivatsa Securities LLP	Amazon Debtors	07ADHFS0916P1ZN	\N	0.00	Regular
2bcdfaac-5bc0-436a-98ea-878fd60dcad0	c1	SHS GLOBAL DELHI	Sundry Creditors	07ACTFS7432D1ZT	\N	0.00	Regular
75b76b6e-ad7a-49d7-9c27-11bc55a4c8c2	c1	SHS GLOBAL (MUMBAI)	Sundry Creditors	27ACTFS7432D1ZR	\N	-9567.00	Regular
e3aeb6bb-ebbf-4a1f-a546-16e6cd194643	c1	Shubham Book Saller	Sundry Debtors	\N	\N	0.00	Unregistered
0e4eef77-d31f-43ca-b342-03619432e5ff	c1	SHUBHAM COMPUTRONICS	Sundry Creditors	\N	\N	0.00	\N
2e451e1f-6f71-46e4-9682-eb77187799e2	c1	Shubham Dixit	Sundry Debtors	\N	\N	0.00	Unregistered
1f73eecf-28cb-4fed-832e-a707b18b0bc5	c1	Shubham Enterprises	Sundry Debtors	\N	\N	0.00	\N
a32316c4-bde6-48f0-8fe1-82b1a208c736	c1	Shubham Genral Store	Sundry Debtors	\N	\N	0.00	Unregistered
65751646-5af9-44b1-9436-0cdb0ba75538	c1	SHUBH ENTERPRISES	Sundry Creditors	09AUWPG6075D1Z7	\N	0.00	Regular
a11ecfc5-60da-4114-80cf-07d1cf2da0c5	c1	Shubh Enterprises 1	Sundry Debtors	09BLKPS1598B1ZQ	\N	0.00	Regular
d51e48e2-cf45-42d5-ad74-ab302379218f	c1	SHUBH ENTERPRISES(F)	Sundry Debtors	09NFVPS2198J1Z1	\N	0.00	Regular
4e37f54c-3d52-4195-8d99-ab875f9c35ef	c1	Shukla Agencies	Sundry Debtors	09CHXPS4241K1ZG	\N	0.00	Regular
8fa59e3a-63fd-47ce-a1e6-c41b5c82b8c6	c1	Shunty Bunty Motors (P) LTD.	Sundry Creditors	09AAGCS7652F1Z2	\N	0.00	Regular
8c5d136d-bb7d-40f4-9386-c41d5ee61637	c1	Shweta Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
72e82dd6-1b8d-490a-9d7a-0a85e2f15763	c1	Shyama Club and Resort	Sundry Debtors	09ADMFS5554L1ZA	\N	0.00	Regular
a6fe9237-d3c2-47f9-b256-97b10e356a6c	c1	Shyam  Electronics	Sundry Debtors	\N	\N	0.00	\N
5e6e4e26-b57d-43c2-971d-280af6b7fd78	c1	Shyam Sales	Sundry Debtors	\N	\N	0.00	\N
15f51b03-cdee-4561-a548-5e8279a3b261	c1	Shyam Swaad (Lucknow)	Sundry Debtors	\N	\N	-56576.00	\N
e086703f-d9ef-4d61-85fa-c29adf93a538	c1	Shyam Trading Company	Amazon Debtors	08ABWPA2195H1ZD	\N	0.00	Regular
79928115-2d9d-437f-9ef6-0493a532a7a2	c1	Siddharth General Store	Sundry Debtors	09AFHPJ2983D1ZD	\N	0.00	Regular
4f9c927d-4360-48a4-8bd3-c5b127322479	c1	Siddharth  Store	Capital Account	\N	\N	0.00	Unregistered
54ab675b-9fe5-4685-87a1-9f3c032d0178	c1	Sikandar Paan Shop	Sundry Debtors	\N	\N	-1440.00	\N
cce717ca-5ed0-4980-bbdb-f649a3831a8a	c1	Simar Store	Sundry Debtors	\N	\N	0.00	Unregistered
4fa2604d-c185-4798-8eb8-617854809889	c1	Simran Agencies	Sundry Debtors	\N	\N	0.00	\N
fc51fff2-a196-407b-81e1-6ab12c880e1a	c1	Sindh Sweets Pvt Limited(Aligarh)	Sundry Debtors	\N	\N	0.00	\N
8d486a1f-24cc-4141-8a9a-e0748d4f3bbd	c1	Singh General StoreXXXX	Sundry Debtors	\N	\N	0.00	Unregistered
980516c5-c7c6-4aa0-b165-400db85c0ede	c1	Singh Gernal Store	Sundry Debtors	\N	\N	117.00	\N
740fd0f5-6e85-494b-9816-0c6a354cb7c2	c1	Singh Parvinder Singh	Sundry Debtors	09BZJPS3019Q1ZK	\N	0.00	Regular
52061c98-38d6-4e6f-9ce6-24483a5d0b55	c1	Singh Provision Store	Sundry Debtors	09AFGPS9758G1ZO	\N	0.00	Regular
785f8779-fee7-451b-8415-64a17916cb28	c1	Singh Services	Sundry Debtors	09HKDPS3156R1Z6	\N	0.00	Regular
b1acb6c1-0e35-466f-a724-72120ff509ed	c1	Singh Traders	Sundry Debtors	09BPJPS5057L1Z4	\N	0.00	Regular
98460959-5c28-421f-9370-9729e5f89c4e	c1	Sippers Inc.	Sundry Debtors	\N	\N	0.00	Unregistered
f8f28825-76d4-4f18-b517-aea912a655ee	c1	Sita Store	Sundry Debtors	\N	\N	0.00	Unregistered
228586f1-2638-43fb-872e-c6c537ec70d6	c1	Siya Enterprises	Sundry Debtors	\N	\N	0.00	\N
0177e7bc-c000-4588-b19f-01a7cc905e6c	c1	Siya Genral Store	Sundry Debtors	\N	\N	0.00	Unregistered
e3bcf0ac-7e89-4e50-bda7-2a114754e4a2	c1	Siya Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
bb5e936f-3980-45b2-8993-2a456bfec17a	c1	Siya Ram Agency	Sundry Creditors	\N	\N	0.00	\N
0559cb0e-1b71-40d0-9a24-b8498a2a50de	c1	S.J.Trading Company	Sundry Creditors	07FJPPS4757H1ZE	\N	0.00	Regular
e91935d6-79d7-494d-8570-91ad5b3d5b26	c1	S.K General Store	Sundry Debtors	\N	\N	0.00	Unregistered
40dcaf6e-183f-4596-9313-4a9506d84e1e	c1	S K GROUP	Sundry Debtors	\N	\N	0.00	Unregistered
d9bfebf0-ea66-42ad-afff-71abc1e0c804	c1	S K V HOSPITALITY PVT.LTD.	Sundry Debtors	09AAZCS1805K1ZP	\N	0.00	Regular
b5c7f676-8f6d-4909-b0fb-bf6dc6228394	c1	SMAAASH LEISURE LTD	Sundry Debtors	09AAECP6342B1ZM	\N	0.00	Regular
10a096fd-dfb9-4523-b9a9-01e2bceedd2e	c1	S.Mag &amp; Sons	Sundry Debtors	09AESPA9652E1Z7	\N	-4336.00	Regular
a0908c4c-dc42-469d-89b8-1a6c408ee0e6	c1	Smart Automation Systems	Amazon Debtors	32ATZPM6978P1ZA	\N	0.00	Regular
df987e76-158a-4b7f-a852-76b52d1a18e7	c1	Smart  Shopping	Sundry Debtors	\N	\N	0.00	Unregistered
bed00c93-fc02-41a1-a1cd-a5a8a4522a09	c1	Smart Solutions	Sundry Debtors	09AFCPG0408B1Z9	\N	0.00	Regular
57977054-db30-4e10-a4a0-2f48cfe839a4	c1	Smayan Impex India	Sundry Creditors	07ACPPD3607H1ZQ	\N	143262.00	Regular
d45eab6e-9cdd-4896-b153-ac94fb436450	c1	Smitha Provision Store	Capital Account	\N	\N	0.00	Unregistered
1081b612-abc6-47af-973c-ffb5db414d1a	c1	Sneha Namkeen Bhandar	Sundry Debtors	\N	\N	0.00	Unregistered
a15e13e9-5a6a-4df8-94d4-8dd6baf3c291	c1	Snowlan Epicure Pvt. Ltd.	Sundry Creditors	27AAXCS4310F1Z6	\N	0.00	Regular
c3b6890f-6061-415f-af46-93c84aff6362	c1	SODHI MEDICAL STORE	Sundry Debtors	09ABMFS6378J1ZA	\N	0.00	Regular
14f6d5e9-d728-4fde-9b57-27e6160c8f6d	c1	Software ( Tally)	Fixed Assets	\N	\N	0.00	\N
d6734a36-0fa4-4484-a42b-eb957b0b3a06	c1	Sohams Foundation Eng. Pvt.Ltd	Sundry Debtors	\N	\N	0.00	\N
854cceb5-1088-4557-b8ee-c86a4cf48429	c1	SOHUMS SWEET	Sundry Debtors	\N	\N	0.00	\N
5e0cd8b8-5129-4e88-ac0f-6471f79a1b81	c1	Sohums Sweets	Sundry Debtors	09AAOPB1118N1ZM	\N	0.00	Regular
e6081c4a-b4e1-403e-9679-1d82d4556657	c1	SOIREE SNACKS	Sundry Debtors	09AEEFS6817D1ZX	\N	0.00	Regular
e3e6f653-a412-46b9-a735-d7c652600f97	c1	SOLEJA CATERERS	Sundry Debtors	09CLBPM8926M2ZE	\N	0.00	Regular
454d72d1-7469-4a50-ab9e-cb3c760928ca	c1	Soma Products	Sundry Debtors	\N	\N	0.00	\N
0d44efb5-2e2c-4917-acbe-cf5b16293793	c1	Sona Impex	Sundry Creditors	\N	\N	0.00	Unregistered
6cfefefd-5083-4b78-828d-db5cccc07008	c1	Soni Traders	Sundry Debtors	\N	\N	0.00	Unregistered
e097ad32-de00-423c-965c-79006ec00f22	c1	Sonu	Sundry Debtors	\N	\N	0.00	Unregistered
cd39f7ff-3b45-4079-ba12-5f471280cb91	c1	SONU AGENCY	Sundry Debtors	\N	\N	0.00	Unregistered
aa705c3b-f00c-49a7-82a7-41586b1bd867	c1	Sony Traders	Sundry Debtors	\N	\N	-2848.00	\N
1dd23317-e566-4470-ad5e-0922ea5a8d56	c1	Sparkles	Sundry Debtors	09JHCPS3850L1ZN	\N	0.00	Regular
17ed3373-ed4f-4e8a-bd83-c120bfb86ba7	c1	Special Discount	Indirect Incomes	\N	\N	0.00	\N
ad6db031-3f08-43f4-8176-795e1a6dc76b	c1	SPECTRUM BUSINESS SOLUTIONS	Sundry Creditors	09AEBPS5397D1Z6	\N	0.00	Regular
247f7589-e980-4f3c-81e9-eba6c00e08f3	c1	Spencer&apos;s Retail Ltd.	Sundry Debtors	\N	\N	0.00	Unregistered
c4f707e9-657b-42d9-8921-2fb389f635f7	c1	Spencer Retail Ltd. ( Security )	Deposits (Asset)	\N	\N	0.00	\N
c30cbc78-10da-4cc9-820f-7116c08632de	c1	S R Agency	Sundry Creditors	\N	\N	29376.00	\N
60767aa1-0434-4763-b314-e01d22b364b1	c1	S.R.Distributors &amp; Suppliers	Sundry Debtors	\N	\N	0.00	Unregistered
d77392ca-609c-4439-97ad-a69f265746ac	c1	S.R ELECTRO WORLD	Sundry Debtors	09AATPM2300E1ZV	\N	0.00	Regular
128c9a89-4ac3-4a5c-a580-0cdc4668dab4	c1	SRESTA NATURAL BIOPRODUCTS PRIVET LIMITED	Sundry Creditors	09AAHCS9571J1ZM	\N	25757.00	Regular
6c645b54-0f52-4efa-b39b-8ccd37f9f549	c1	S R G Marcantile P. Ltd.	Sundry Creditors	\N	\N	0.00	\N
cb698fdd-4527-4422-82b4-ded00ca3ee12	c1	Sri  Agency	Sundry Debtors	\N	\N	0.00	Unregistered
26e7a2dd-75f6-455b-a276-6d1360987a73	c1	Sri Balaji Marketing	Sundry Debtors	\N	\N	0.00	Unregistered
dce3f13e-3bb3-415c-ad37-1d6855500520	c1	Sri Balaji Traders	Sundry Debtors	\N	\N	0.00	Unregistered
9633b7ba-d1de-4ad4-a4ac-529561ee6e48	c1	Sri Chand &amp; Son&apos;s	Sundry Debtors	\N	\N	0.00	Unregistered
0f287b04-41ce-47e7-8a97-0f46096f08c0	c1	Srichand Sons	Sundry Debtors	09ADPPM6518H1Z3	\N	0.00	Regular
9ae4b801-85da-4474-82a4-07f31a0392dd	c1	SRI GURU KRIPA ENTERPRISES	Sundry Creditors	\N	\N	396513.00	\N
ea406229-dfe1-4576-a581-663f927ff1d7	c1	Sri Laxmi	Sundry Debtors	\N	\N	0.00	Unregistered
875ea413-7a3b-400d-ad73-62312bc96ddb	c1	Sri Laxmi Prabha Engg Industries Pvt Ltd.	Amazon Debtors	03AAPCS1315N1ZX	\N	0.00	Regular
a3c3a6ac-1b28-49fc-a8e3-5acff02efd80	c1	SRI NATH JI MARKETING	Sundry Creditors	09ABAPA1928J1ZX	\N	0.00	Regular
67f59de8-8641-4cb3-909f-c445f4efbbf4	c1	S.R. INTERNATIONAL	Sundry Debtors	07AAYPT5008P1ZP	\N	0.00	Regular
929e3bc0-9526-4889-bc8c-481952b06377	c1	Sri Parbhu Dayal Provision Store (Lucknow)	Sundry Debtors	\N	\N	0.00	\N
6917b893-9caf-4936-92b4-52d54e281792	c1	Sri Radehy Enterprises	Sundry Debtors	09FKYPB2246C1Z2	\N	0.00	Regular
b2b5ce2b-8223-4093-a6e4-475c0f87bb1b	c1	Sri Roda Foods	Sundry Creditors	07AAYFS5573Q1ZV	\N	523911.00	Regular
fb83b806-37e7-4597-85cf-4ccf6ac0a96c	c1	Sri Shive Mahima Bhandar	Sundry Debtors	\N	\N	0.00	Unregistered
f7ca0f07-b3cb-46cc-b25b-07bceca4448d	c1	S R S DEVELOPERS	Sundry Debtors	\N	\N	-24236.00	\N
5995bb52-edf7-4e22-a3a1-6a0d7c632380	c1	S S AND COMPANY	Sundry Creditors	09CLLPS6293R1ZP	\N	0.00	Regular
116461fb-8e27-4815-8866-51c0a779688f	c1	S.S ENTERPRISE	Sundry Debtors	09AYTPA9309H1Z1	\N	1.00	Regular
e26ac0a0-54bb-4965-a622-61aadc930e38	c1	S.S Enterprises	Sundry Creditors	09BMWPM7490P1ZM	\N	0.00	Regular
8d0350ec-359c-4c8b-a257-762cf27a4736	c1	S.S MINI MART	Sundry Debtors	\N	\N	0.00	Unregistered
d4c63383-2b0b-46cb-8f17-43968202484a	c1	Staff Salary	Sundry Debtors	\N	\N	0.00	Unregistered
fe353a49-1ef3-4440-9b7d-e1d60182e5dd	c1	Staff Welfare Exp	Indirect Expenses	\N	\N	0.00	\N
1c5d2f9a-62fc-440a-925c-9735b04b9fad	c1	Standard Marketing	Sundry Creditors	\N	\N	0.00	\N
c6f3b89c-7228-4319-a695-41797a6585b4	c1	Star Auto Sales	Sundry Creditors	09CNHPS6113G3ZR	\N	0.00	Regular
e88e652a-13b3-45d8-a30f-fd6f5d2fb970	c1	STARLITE INTERNATIONAL	Sundry Creditors	07ACUFS1761L1ZF	\N	-397.00	Regular
dd0eb368-5398-4edc-b9ec-468649ee2381	c1	Stationery Account	Indirect Expenses	\N	\N	0.00	\N
2a9474d1-2af8-42b5-8c3e-834c7529e108	c1	STORIA FOODS &amp; BEVERAGES LLP	Sundry Creditors	09ADAFS7400H1Z6	\N	0.00	Regular
7eb46e0f-9085-4202-83ae-84cafcdcb905	c1	Subhash Agency	Sundry Creditors	\N	\N	0.00	Unregistered
519325af-88f1-4d0c-a644-df86712d6762	c1	Subh General Store	Sundry Debtors	\N	\N	0.00	Unregistered
c6060b0c-b86f-45a7-bcf0-7b203bb682aa	c1	Sudha Associates	Sundry Creditors	\N	\N	0.00	Unregistered
8ba92fd9-fc57-464e-ac7c-654ed57ee0b5	c1	Sufiyan Ansari	Sundry Debtors	\N	\N	0.00	Unregistered
b15579b2-97a2-4168-bf08-1130ac176688	c1	Sugam Electricals	Sundry Debtors	\N	\N	0.00	Unregistered
5dead26d-36ed-45d3-a640-0db9d7bf126f	c1	Sugam Electronics	Sundry Debtors	09AFPPJ7546C1Z6	\N	0.00	Regular
79bfece3-aef5-48f1-8302-d80941aa79c7	c1	Suhana Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
53ddc967-e7ed-4d68-bede-39e0874c2d02	c1	Sukhmani Sales Private Limited	Sundry Creditors	07AAYCS7350Q1Z6	\N	0.00	Regular
65bd206e-458a-4fac-8e2e-9e9c167fa2c0	c1	Suman Mehrotra	Unsecured Loans	\N	\N	378000.00	\N
d2759c84-3048-431c-bed9-b4bb57b84f0a	c1	Sunaina Store	Sundry Debtors	\N	\N	0.00	Unregistered
d074b893-e332-4974-92f2-9829951734dc	c1	SUNBEAM  ENTERPRISES	Sundry Debtors	09BXLPS6088K1ZF	\N	0.00	Regular
1c9a00ae-014b-43c9-ac45-59ba710aeb55	c1	Sundar Watch House	Sundry Debtors	\N	\N	0.00	Unregistered
e059a3f3-63d1-454b-b661-7035f107fdb2	c1	Sunder Enterprises	Sundry Creditors	\N	\N	0.00	\N
bc87e933-3ef9-48f5-8942-ab88f3fcc150	c1	Sunheri Marketing Pvt Ltd.	Amazon Debtors	06AAJCS5229H1Z8	\N	0.00	Regular
e1ac08a8-a99c-4c67-ac7e-cbe31b8d4748	c1	Sunil Dubey	Unsecured Loans	\N	\N	247998.00	Unregistered
c966b1df-655f-4c89-ae5d-0395c8bd9e62	c1	Sunil General Store	Sundry Debtors	\N	\N	0.00	Unregistered
e65281f9-1748-4317-bcfd-e7f30c6aaa99	c1	Sunil Store	Sundry Debtors	\N	\N	0.00	Unregistered
203b4380-180a-4a49-8bd3-fba7015cdb33	c1	Sunny Paan Shop	Sundry Debtors	\N	\N	0.00	\N
17d559c5-c52a-497e-b836-b03da7f1026f	c1	Sunshine Retail	Sundry Debtors	09AEEFS8982H1ZB	\N	-18027.00	Regular
ecbf1d8d-f97f-401e-b50b-622dc98d6bd6	c1	SuperZone	Sundry Debtors	09BSVPS7451M2ZH	\N	-3122.00	Regular
ae0c0eec-8333-4720-85a0-52062acd2c8f	c1	Suphion	Sundry Debtors	\N	\N	0.00	Unregistered
a4bad0ef-0d91-4b3b-ae27-10d3c42d2e52	c1	Supply Expenses	Direct Expenses	\N	\N	0.00	\N
b6d065f3-f7d9-402c-873b-dce4f16f90e6	c1	Suprash	Sundry Debtors	\N	\N	0.00	Unregistered
17c41216-f6a6-4925-b48e-f08676ac15c0	c1	Suprash Provision Store	Sundry Debtors	09AESPJ0274R1ZN	\N	-14766.00	Regular
6019db61-f4a3-4599-9496-cd67b34e9eb2	c1	Supreme Agencies	Sundry Debtors	09AAZPK2301H1ZK	\N	0.00	Regular
8c9d3da6-e7e4-44a2-8ed9-c0085d17cb21	c1	Supreme Electronics	Sundry Debtors	09AATPK9775B1Z2	\N	0.00	Regular
602fad75-6906-4fdc-9020-07eced36fa16	c1	Supreme Enterprises Delhi	Sundry Creditors	07AABPG2211L1Z6	\N	34137.00	Regular
54b4c5a9-0dd9-48a5-88bd-cc4111edc4c2	c1	Suprem Electonics	Sundry Debtors	\N	\N	0.00	Unregistered
053a3799-0a18-40f8-a073-1b12fd9af5b7	c1	Suraj	Sundry Debtors	\N	\N	0.00	Unregistered
995f1e1f-252f-4162-a9a7-818a7716ddda	c1	Suraj Trading Co.	Sundry Creditors	09AEBPK2546Q1Z2	\N	2900.00	Regular
bb58e8cf-b8e8-490e-a04f-2ee47a42bf87	c1	Surendr General Store	Sundry Debtors	09AJCPB2384H1ZE	\N	0.00	Regular
fea0d146-078c-49ae-b619-1b0c3a3da1fc	c1	Suresh Chandra Gupta	Sundry Debtors	09ABMPG1695G2ZD	\N	0.00	Regular
35aa0511-21c1-40a9-b390-dbb48a6dfa40	c1	Suresh Chandra Mahes Chandra	Sundry Debtors	09ADJFS8090G1ZJ	\N	0.00	Regular
26328a1b-5c49-44a8-b83d-89447f666c6b	c1	SURESH KUMAR &amp; CO(IMPEX)PVT.LTD(2022-2023)	Sundry Creditors	07AAICS8587K1ZH	\N	1397.00	Regular
f3071f42-853d-4ce4-8508-b65700a2180f	c1	Suresh Prov.Store	Sundry Debtors	\N	\N	0.00	Unregistered
3c60b946-bb8c-4523-948f-e5410af4d279	c1	Suresh Tea Stall	Sundry Debtors	\N	\N	0.00	Unregistered
b4bb14e3-9349-4460-9a2b-6c6b5b688067	c1	SURYA TUCK SHOP (NOIDA)	Sundry Debtors	\N	\N	-153569.00	\N
5d3fd772-d520-4a92-8f99-1ac642e6f2d0	c1	Suspences	Suspense A/c	\N	\N	28811.00	\N
3e984a1e-46f5-4630-8c49-9e821a4e38d2	c1	Sutthimani Foods Private Limited	Sundry Debtors	09AADCG8466C1ZH	\N	0.00	Regular
a65bfa82-a15f-41e9-9193-100aa802995a	c1	Suvidha Genral Store	Sundry Debtors	\N	\N	0.00	Unregistered
6dbf4084-2e65-4d83-8afe-3a4d27f644ea	c1	Svoboda Healtcare Pvt Ltd	Amazon Debtors	24AAXCS3661B1Z8	\N	0.00	Regular
ce38c6e0-744e-4e3a-9207-b76374348af1	c1	Swasti Foods	Sundry Debtors	09ABYPL8731C1Z6	\N	0.00	Regular
5e1e58bc-2429-4aac-9709-34a9d944cb05	c1	Swati Cakes N Bakes	Sundry Debtors	\N	\N	0.00	Unregistered
f7634917-229d-4fbd-b606-b889590a2fa1	c1	SWATI GENERAL STORE	Sundry Debtors	\N	\N	0.00	Unregistered
33f35bc6-8a48-49aa-bfea-0bea1803c5a5	c1	Swati Sales Corporation	Sundry Debtors	09AGNPD1643F1ZK	\N	0.00	Regular
78daeaa6-2068-49fc-b7a4-5555486d4ea9	c1	Swati Tiwari	Sundry Debtors	\N	\N	0.00	\N
00c28e78-fc5a-4f46-810b-41b0c9790467	c1	Swiggy Customer Debtors	Sundry Debtors	\N	\N	0.00	Unregistered
4fdf9a62-7ddf-4e33-9938-9093604aace7	c1	SWISS BAKE INGREDIENTS PVT. LTD	Sundry Creditors	09AARCS3831R1ZD	\N	0.00	Regular
4c5cef4e-b29d-44fc-be53-ce2bcabed85f	c1	SYSTEMS &amp; TECHNOLOGY	Sundry Debtors	\N	\N	0.00	\N
cc6ad3fa-6cdc-4b6e-af7b-eac863932a0b	c1	Talk of the Town	Sundry Debtors	\N	\N	0.00	\N
8a366b2d-393c-422a-885e-a99d7cf97cd6	c1	TALLY RENEWAL CHARGES	Indirect Expenses	\N	\N	0.00	\N
db612dab-4ee4-4f48-a20c-25748b87c6b6	c1	Tandon Printers &amp; Stationers	Sundry Debtors	09AAPPT3744D1ZC	\N	0.00	Regular
2649f764-0af8-4ba0-b04c-8a80c14fe6b9	c1	Tara General Store	Sundry Debtors	\N	\N	0.00	Unregistered
7ee5fab5-a382-4ab6-a495-40c8a9653a32	c1	TARAN GENERAL STORE	Sundry Debtors	\N	\N	0.00	Unregistered
a59e2935-1e2d-4873-b4bc-4d0e56ceddbd	c1	Tara Pan Shop	Sundry Debtors	\N	\N	0.00	\N
313d187d-1348-425c-a335-f247beebbb69	c1	Tarun Book Depot	Sundry Debtors	\N	\N	0.00	Unregistered
509ea15a-9a84-4ce8-a86f-e9eba7c4b8d2	c1	Tarun Book Store	Sundry Debtors	09AOWPS1998H1ZT	\N	0.00	Regular
4cf24057-176a-4daf-aebd-fffc4ea35b4c	c1	Tarun Book Store(A.S)	Sundry Creditors	\N	\N	-18906.00	\N
fe3a41b6-dd1a-42bf-b803-7e9a12f114fb	c1	Tarun Shukla	Sundry Debtors	\N	\N	0.00	\N
2efb9773-ebde-4c8e-9d66-f1b67e09803c	c1	TATA AIG GENERAL INSURANCE COMPANY LTD.	Sundry Creditors	\N	\N	0.00	Unregistered
30542f1a-dd41-4931-af0f-2e15f1b85f89	c1	Tax on Reverse Charge	Current Assets	\N	\N	0.00	\N
e1338966-c1e5-4251-913c-8a764cb4b3b7	c1	TCS	Loans & Advances (Asset)	\N	\N	0.00	\N
56b251f1-0339-44fb-a2c6-8f701769b42f	c1	TCS 2020 - 2021	Loans & Advances (Asset)	\N	\N	0.00	\N
d5645b1e-b16f-4f49-a252-6d8e991908ab	c1	TDS	Loans & Advances (Asset)	\N	\N	0.00	Unregistered
a7fe23df-bbe8-4d2c-a961-4295d6ee4a38	c1	TDS 2012-2013	Loans & Advances (Asset)	\N	\N	0.00	\N
55a26c32-70ba-49f7-8739-ef9031497d96	c1	TDS 2013-2014	Current Assets	\N	\N	0.00	\N
5f59874a-b688-4a53-b5fc-bacf7dcde53c	c1	Tea Partner Foods LLP	Sundry Debtors	09AALFT2520K1ZY	\N	0.00	Regular
547e6cd1-e820-4e42-b2c4-e2f01926383c	c1	Techno Power Engineers	Amazon Debtors	27DYOPS7380N1Z7	\N	0.00	Regular
406737f1-6fe0-4ce7-a733-de481cf8c58c	c1	Tejal Agencies	Sundry Debtors	09AADFT9194M1ZA	\N	7035.00	Regular
d3ad11cb-91ce-4573-9522-bbb283507b24	c1	Tejamal General Store	Sundry Debtors	09AIPPA1665A1ZK	\N	4800.00	Regular
c12cf221-5f80-4d32-81fa-56d387e37112	c1	Telephone Exp.	Indirect Expenses	\N	\N	0.00	\N
7b01f2d4-f34a-4098-8cb4-5bd11e1fc70d	c1	Testy House	Sundry Debtors	\N	\N	0.00	\N
21fe57b9-7513-41b6-9b1b-f562fa235d57	c1	THAILAND RESTRO, LOUNGE &amp; BAR	Sundry Debtors	09AKWPG0987A2ZV	\N	0.00	Regular
dd99742a-c6ac-444d-a0b6-e2a16aa6cf59	c1	THAKUR PROVISION STORE	Sundry Debtors	\N	\N	0.00	Unregistered
5cefbf6f-867e-402d-b822-66db5e7a747c	c1	The 3rd Dimension	Amazon Debtors	06BHAPS4974F1Z5	\N	0.00	Regular
6b8646d0-df20-475e-8dbd-0e62fe4c08d0	c1	The Agency Source	Amazon Debtors	07AAJFT1200E1ZQ	\N	0.00	Regular
b27a238a-0d24-4efe-8894-dafe7796db04	c1	THE BELGIAM WAFFLE	Sundry Debtors	\N	\N	0.00	Unregistered
fbef7b6a-6681-459e-81b4-6bc85551597e	c1	The Bharat Hospitality	Sundry Debtors	09AAZPT4570B1Z4	\N	0.00	Regular
0730ab65-fb0b-4dd8-87b5-1ddfa5946b15	c1	The Care Takers	Sundry Creditors	\N	\N	0.00	\N
61334a4c-9bfb-4955-bdfa-2ba924de015b	c1	The Caretekers	Sundry Creditors	\N	\N	0.00	\N
9e46cb52-ef3a-4c6e-8876-66935be27d4a	c1	The Chakna Factory (TCF)	Sundry Debtors	09ESLPM7116N1ZZ	\N	0.00	Regular
89f6f3a9-7520-4335-851d-fd08a73743a4	c1	The D N Brothers	Sundry Debtors	09BWLPB6615E1ZM	\N	0.00	Regular
255d4567-235f-45cc-b5b4-e8834036e3c6	c1	The Down Town	Sundry Debtors	09AAOFJ9314L1ZP	\N	0.00	Regular
0c36a327-6b48-4cda-8559-d01d6468fe2a	c1	The Dream Cakes	Amazon Debtors	36AECPJ4301D1Z7	\N	0.00	Regular
21a8b062-55c2-4170-8133-079b189bf855	c1	The Eclair Bakery	Sundry Debtors	09AARFT8012G1ZU	\N	0.00	Regular
e96a1be8-b92d-4f56-bb66-df70888fc729	c1	THE ESSENTIALS	Sundry Debtors	09AWLPK5970A1ZE	\N	0.00	Regular
7360e57c-0fbe-4a2d-97ad-ef384fb27af9	c1	The Forest Grill	Sundry Debtors	09DLWPK1905A2Z2	\N	0.00	Regular
13748b0a-eb03-49a9-b7ca-c8d96aed4da0	c1	THE GANGES CLUB LIMITED	Sundry Debtors	09AAACT6177A1ZF	\N	-6250.00	Regular
718f69f5-302e-46ff-864e-8215a7ab9649	c1	The Landmark Hotel	Sundry Debtors	09AAOCS1821N1ZU	\N	-54184.00	Regular
86a24961-c83d-496e-9c7d-64640a19cc13	c1	The Millionaire Suites	Sundry Debtors	09AANFT1192R1Z8	\N	274994.00	Regular
e1c9471c-ebfe-4211-b329-c419d7cf2e4c	c1	THE NEW INDIA ASSURANCE CO LIMITED	Sundry Creditors	\N	\N	4244.00	\N
005b9c36-aa4e-4bf2-b487-7a3d09209d23	c1	The N H Club	Sundry Debtors	23AJQPB9371C1ZB	\N	0.00	Regular
539de7b0-4808-4743-ae10-03489d41c8a8	c1	The Offbeat India	Amazon Debtors	05BAYPS8166G1ZV	\N	0.00	Regular
db9333a0-5fc7-4019-8673-c3963c13fd9b	c1	The Pan Shop	Sundry Debtors	\N	\N	0.00	\N
c523a338-7a90-48a0-99b1-792fe03efef8	c1	The Pint Room Hospitality (Amazon)	Amazon Debtors	07AARFT1927E1Z0	\N	0.00	Regular
eb37879b-298d-434d-95ef-f6b8e55ee978	c1	The Reefer Cafe &amp; Eatery	Amazon Debtors	03BJAPA2839P1ZB	\N	0.00	Regular
47b5ec64-1cca-4b92-8ab4-c746fada666f	c1	The R S Belvedere	Amazon Debtors	02AALPC4464B1ZC	\N	0.00	Regular
c4df6c26-028f-416b-928f-d806bfcb1acc	c1	The Veggie Foundry Kitchen	Amazon Debtors	29ACLPB7685D1ZC	\N	0.00	Regular
527a849b-313d-4b6c-b26a-f10cfa213ffb	c1	Third Eye Camera	Amazon Debtors	27AABPP8211B3Z2	\N	0.00	Regular
874e855c-f9ff-4ec2-a1a7-519e711d2dee	c1	Thirsty Sip	Sundry Debtors	09AAPFT1640J1ZT	\N	0.00	Regular
2842efaa-9290-4794-9563-9ddfc68033d9	c1	Tillu General Store	Sundry Debtors	\N	\N	0.00	Unregistered
a6486637-93f6-4ac2-85b0-10eab32b6302	c1	Tina Store	Sundry Debtors	\N	\N	0.00	Unregistered
52884125-3d7f-4bb3-82f0-bc032348f1d7	c1	TISHYA IMPEX	Sundry Creditors	09BIJPS3141Q1ZJ	\N	0.00	Regular
38bd9f3c-d618-4a01-b6b2-211406306387	c1	Tiwari Freight Carriers	Sundry Debtors	\N	\N	-400.00	Unregistered
3fbf1d5c-a4e1-4c69-8b0a-c3c91567851c	c1	Tiwari General Store	Sundry Debtors	09ABGPT7032A1ZS	\N	-1500.00	Regular
5f964ff9-fabc-4494-b622-7ec8c4eb64e7	c1	Tiwari Paan Shop Bakers	Sundry Debtors	\N	\N	-1106.00	Unregistered
f618d213-8c58-4e77-a5de-00eb353ec515	c1	Tiwari &amp; Sons	Sundry Debtors	\N	\N	0.00	Unregistered
b59007af-72ed-40e7-a1f7-4d610983be1d	c1	Tiwari Sweets ( Z Square Mall)	Sundry Debtors	\N	\N	-4455.00	\N
42909d13-1cf2-488c-8d92-3e951f8f7cfd	c1	Tondon Kirana Store	Sundry Debtors	\N	\N	0.00	Unregistered
ad55c661-2a73-420f-b022-d92607aff1ed	c1	Tong Garden Food Marketing (India) Pvt. Ltd	Sundry Creditors	07AADCT2914J1ZC	\N	0.00	Regular
cd589f17-43f1-4d8f-b59f-90f98f0fa9fd	c1	Tong Garden Food Products(India)Pvt Ltd	Sundry Creditors	24AADCT2767P1ZT	\N	0.00	Regular
35016af0-5792-42b5-8aee-17e31378a8bc	c1	Torrent Gas Limited	Sundry Debtors	09AAGCT7889P1Z1	\N	0.00	Regular
e2efdcd5-9d61-4a1e-9b0c-3a26f1f8d8da	c1	Tranquil Solutions	Amazon Debtors	24AAPFT9702K1ZO	\N	0.00	Regular
836446db-a5db-4b3b-8154-688a5f63a3df	c1	Travelling Exp.	Indirect Expenses	\N	\N	0.00	\N
db88c800-796f-4c8a-a7b1-88fd737bad09	c1	Treat Conveneance Foods	Sundry Debtors	09AABFT4138M1ZU	\N	-9675.00	Regular
24942f3e-2da6-4340-b919-cdcb1bc28409	c1	Treelogical Foods LLP	Sundry Creditors	\N	\N	-230.00	\N
3a0991b8-ccef-417a-9380-6c828c678f12	c1	TR Enterprises	Sundry Creditors	\N	\N	0.00	\N
e2016c17-2a14-4ee4-9a41-6f1a65a7a777	c1	TRILOK CHAND &amp; SONS	Sundry Debtors	09ABBPK9331J1ZH	\N	0.00	Regular
039e3cca-425c-4943-8be1-7ce5a6017968	c1	TRIMS N TAPES	Sundry Debtors	09AAZPO3220D1ZK	\N	0.00	Regular
cc3515a1-83a6-4d21-99c4-28897cdfd0e6	c1	TRP Associates	Sundry Debtors	09AATFT4069M1Z6	\N	0.00	Regular
e079d815-0be8-4198-89c0-ba46c8fdfef2	c1	Truffle Nation	Amazon Debtors	07AQMPL2519B2Z2	\N	0.00	Regular
a93716ee-549d-421e-b8f8-bcb2186206fc	c1	TRUMPP FOODS	Sundry Creditors	07AAKFT8071A1Z6	\N	0.00	Regular
4515ffb5-89d1-435b-a7ac-8b2f8d3d342f	c1	Tru Taste Rate Diff 12%	Indirect Expenses	\N	\N	0.00	\N
ff2f17c2-858d-4def-807c-b8d4f6de973c	c1	TSH Sports Complex	Sundry Debtors	\N	\N	0.00	Unregistered
78c51266-8324-4fd9-ba3e-75175670cde1	c1	TWEKSBURY HOSPITALITY PRIVATE LIMITED	Sundry Debtors	09AAFCT9384C1ZZ	\N	0.00	Regular
a73e9ae0-e049-450e-9402-54bd2c2f5a28	c1	U.A. Fitness	Sundry Debtors	\N	\N	0.00	\N
d9920169-20f6-45e8-bdf6-edc8c47d9b67	c1	UCL Distribution Pvt Ltd	Sundry Creditors	07AADCU1077H1ZC	\N	9320.00	Regular
e4bdda77-6767-4120-af35-a75f2b01ea67	c1	Udta Punjab	Sundry Debtors	09BGOPA2731H2ZH	\N	0.00	Regular
380242e3-b11f-45aa-a3c0-f9fb9566367e	c1	Umar General Store	Sundry Debtors	\N	\N	0.00	Unregistered
f1a186a5-00ec-4ec5-b6cb-adeb9d2fdecd	c1	Umeash Chand Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
bd9f32ef-5c43-4ea1-bcc8-a5356cac61cc	c1	Uncles Fast Foods	Sundry Debtors	09AAXPM5358A1ZB	\N	0.00	Regular
c8527ddf-162c-4feb-82e1-e23025dc6607	c1	Unibic Biscuits India Pvt.Ltd.	Sundry Creditors	\N	\N	0.00	\N
ba00cb98-3db7-4961-9342-446c610d5c98	c1	UNIBOURNE SPECIALITIES LLP	Sundry Creditors	07AAHFU0738L1ZV	\N	0.00	Regular
f9942e40-d49d-444f-a899-d57edd2b2c10	c1	Unicorn Foods and Beverages	Amazon Debtors	07AAGFU7565G1ZS	\N	0.00	Regular
0a8419f6-9a27-4f9e-820a-a78f0fb06d9e	c1	Unique Alied &amp; Chemicals	Amazon Debtors	09AAEFU2447H1Z1	\N	0.00	Regular
9afea998-86ec-4855-a5c1-95e7d7995d1b	c1	Unique Palace	Sundry Debtors	\N	\N	0.00	\N
d44313cb-2d21-49c1-9c7a-f45ea232c98a	c1	UNITED DISTRIBUTORS INC.	Sundry Creditors	07AAEFN3108Q1Z1	\N	-22709.00	Regular
7019d97e-b481-48a8-b457-c3825ab307bc	c1	UNITED (INDIA) INTERLINKS	Sundry Creditors	\N	\N	0.00	\N
d63f3bfb-22e1-4490-aa57-f134bbcdb633	c1	Universal Corporation Ltd.	Sundry Creditors	09AAACU3756A1ZJ	\N	672031.40	Regular
4d47e77f-577a-4d54-a5c1-4cfea51ba19f	c1	U.P Rajya Karamchari Kalyan Nigam	Sundry Debtors	\N	\N	0.00	\N
b33b83a5-0fd0-40f9-b04f-58c114d792d6	c1	U.P Rajya Karamchari Kalyan Nigam Medical StoreXXXX	Sundry Debtors	09AAATU0957AAZE	\N	0.00	Regular
d4b4cc02-bf09-4229-815f-807d6e475530	c1	USD Enterprises	Sundry Debtors	09AAGFU9286N1Z3	\N	0.00	Regular
7662a0c9-d729-44e8-af0b-393b26894a60	c1	Usha &amp; Sons Enterprises	Amazon Debtors	07BHGPM3803B1ZT	\N	0.00	Regular
a333f8f2-d7c1-4018-a714-169b00d735ae	c1	Uttam Sugar Mills Limited	Sundry Creditors	09AAACU2186Q3ZM	\N	0.00	Regular
89cc0d0e-9862-441d-b529-7b1f6e05f23c	c1	Vaaho Foto	Sundry Debtors	\N	\N	0.00	\N
deef753f-27a8-48fc-a9d8-166f0243e3a3	c1	V A NINE PRIVATE LIMITED	Sundry Debtors	09AALCM5495R1Z9	\N	0.00	Regular
2d7028b1-5e4e-493d-83fa-1f49df432a0b	c1	Varaity Chmeist	Sundry Debtors	\N	\N	0.00	\N
f7fd5a43-1bfe-4591-bf6d-3101f62f5c75	c1	Vardhaman Overseas - (2018-2019)	Sundry Creditors	07AAOFV7208H1ZT	\N	0.00	Regular
ae0a7f00-b065-426e-af3c-c7d9a72dfb65	c1	Vardhman Enterprises	Sundry Creditors	09BAGPG7162Q2Z1	\N	0.00	Regular
b1f2d058-a8d4-4668-a496-a2ada78215fb	c1	Vardhman Traders	Sundry Debtors	\N	\N	0.00	Unregistered
49ac0515-2e4e-43f5-bcd8-32f209d29945	c1	Varun	Sundry Debtors	\N	\N	0.00	Unregistered
a5d9bebe-8eef-45f5-93fe-e76e0ea74ac5	c1	Varun Bhaiya	Sundry Debtors	\N	\N	0.00	Unregistered
13b18daa-6c67-464b-b2c9-ac3762ba085d	c1	VARUN ENTERPRISES	Sundry Creditors	09AOUPC9063R1ZU	\N	0.00	Regular
dfb27dcd-a519-4bad-98a6-328c28dfd593	c1	Varun Vishal Transport	Creditors Others	09AJQPP8323A1Z1	\N	0.00	Regular
2a3a546c-68b1-459a-9246-2f078e8927c6	c1	Vashnavi Department Store	Sundry Debtors	\N	\N	0.00	Unregistered
87e2775c-31a9-4e4e-a431-05d7793822c7	c1	Vatsal Kirana Store	Sundry Debtors	\N	\N	0.00	Unregistered
62644dac-567c-4542-8ab9-2e3e9615d866	c1	VAVE AGENCIES	Sundry Creditors	09AAQFV7212B1Z3	\N	0.00	Regular
82091dd0-e5ab-4690-a7f7-e9a93195f92b	c1	V Chetan Associate	Sundry Debtors	09ADSPA2136N1Z9	\N	0.00	Regular
c9e6a662-d05f-4828-b8c6-37877640ff1a	c1	VEDAANTTA RETAILS PRIVATE LIMITED	Sundry Debtors	09AAGCV9836Q1Z6	\N	-29257.56	Regular
ee17dab7-4125-4676-bdff-88a9a931dcea	c1	Veeraj Essentials	Sundry Debtors	09EFRPK5018E1Z8	\N	12305.00	Regular
5eba5101-d873-4eb7-b24b-58619153ff19	c1	Veggie&apos;s Hub	Sundry Creditors	\N	\N	0.00	Unregistered
ac5baeba-f2db-46fa-ab03-0fe4b147f2bc	c1	Vehicle Repairing &amp; Maintenance	Indirect Expenses	\N	\N	0.00	\N
d38164fd-2b07-4dc4-8201-0c3b0c305129	c1	Vidyut Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
88674650-88a5-4ff8-97e6-8c6e0306348d	c1	Vijay	Sundry Debtors	\N	\N	0.00	Unregistered
e69fd30e-2db9-4b58-a5b0-b24ccb675ac4	c1	VIJAYA ENERPRISES	Sundry Creditors	07AALFV2004Q1ZT	\N	0.00	Regular
311889b5-6746-4e36-8f1a-2cc2f75b6e71	c1	Vijayam Papads	Current Liabilities	\N	\N	0.00	\N
26792e9f-8fc3-41b2-a061-2bdaef8bf37f	c1	Vijay Chaurasia	Sundry Debtors	\N	\N	0.00	\N
1439ff3a-221d-48c2-b3ac-acfb463f47ce	c1	VIJAY INFRATECH (INDIA)PVT.LTD.	Sundry Debtors	09AACCV9022A1ZL	\N	0.00	Regular
e548bf9d-19ee-4a70-aa1f-4aae261a8424	c1	VIJAY KIRANA STORE	Sundry Debtors	\N	\N	0.00	Unregistered
d0f75efe-daa5-4f92-8c08-5f440a4635fe	c1	Vijay Laxmi Transolutions Pvt Ltd	Creditors Others	07AADCV3900G1ZL	\N	2650.00	Regular
484555cc-1e63-4781-9448-0c105dd96f32	c1	Vijay Store	Sundry Debtors	\N	\N	0.00	Unregistered
6210c50e-acd7-433f-a6d2-a366de098ce6	c1	VIJSUN STORE	Sundry Debtors	\N	\N	0.00	Unregistered
ea00f346-1ecf-4f4b-998f-54d9cee4317e	c1	Vikas Genral Store	Sundry Debtors	\N	\N	0.00	Unregistered
284ac728-2ffe-4f39-9824-72e5676865a6	c1	Vikas Pneumatics India	Amazon Debtors	03ACVPJ4827D1ZM	\N	0.00	Regular
c76910d7-48bc-4dcf-bc53-6184756e2d0d	c1	Vikas Verma	Sundry Debtors	\N	\N	0.00	Unregistered
1a0f5003-763a-4953-88bf-715b28f8d2ea	c1	Vikki Photo Deals	Sundry Debtors	09AFKPH3255C1ZC	\N	0.00	Regular
7a951a33-f3f7-4aea-b3a1-e4ef0c4ba68e	c1	Vimta Labs Limited	Amazon Debtors	36AAACV7244E1ZE	\N	0.00	Regular
89d80fc8-e0fd-42f5-88fb-c3dd0b2be8e7	c1	Vinayak Enterprises	Sundry Debtors	09ALDPM4950B1ZA	\N	0.00	Regular
14cbd76e-d4fd-4367-81d9-a1b8bb39bdcb	c1	Vinayak Enterpriss	Sundry Debtors	\N	\N	0.00	\N
bfdea0d4-30b3-468e-a262-6464e83ca228	c1	VINAYAK INTERPRISES	Sundry Debtors	09ASOPT8321M1ZU	\N	0.00	Regular
accae31d-c108-4ef7-96c2-7c6bc7a08dfe	c1	VINAYAK STORE	Sundry Debtors	\N	\N	0.00	Unregistered
d133c6e0-a8eb-418c-9940-f977977deb61	c1	Vinay Paan Shop	Sundry Debtors	\N	\N	0.00	\N
eaa8e6ff-cd6b-4e43-a771-99be4dfa4521	c1	Vinod Agency	Sundry Creditors	24ADWPD9732F1ZB	\N	0.00	Regular
7c08909d-719a-4d56-b23c-e901ec6da09e	c1	Vinod Food Mart	Sundry Debtors	\N	\N	0.00	\N
2e746c43-30e3-47b9-8a6f-0b8fe0390403	c1	Vipin Agency	Sundry Debtors	\N	\N	0.00	\N
b6f670f2-94bb-4c92-896e-629f40b925cc	c1	Vipin General Store	Sundry Debtors	\N	\N	0.00	Unregistered
460efbf5-6ca9-4582-bc29-9d897b108707	c1	VIRAAJ AGENCIES	Sundry Debtors	09BEHPJ6169M2ZS	\N	0.00	Regular
296aca5c-4ade-4026-8914-816772235eab	c1	Viraindersingh &amp; Sons	Sundry Debtors	\N	\N	0.00	Unregistered
656f9c63-1dad-4275-8d1f-321eef005e6c	c1	Virendra Srivastava	Sundry Debtors	\N	\N	0.00	Unregistered
146407da-8e17-4e21-bd4a-930e18dc9f63	c1	Vishakha Singh Avtar Singh (Old Gst)	Sundry Debtors	09AEFPS9048R1ZD	\N	0.00	Regular
ee5f393a-0bee-43eb-b26c-d750b46ce876	c1	Vishakha Singh Mahender Singh	Sundry Debtors	\N	\N	-3660.00	\N
d5a742ce-6980-4f47-9bb7-d270bc26b3db	c1	Vishakha Singh Mahender Singh (OLD GST)	Sundry Debtors	09AFGPS9748Q1Z5	\N	0.00	Regular
e6ef8c11-e468-47c8-bf88-ad596eec8b4d	c1	Vishal	Sundry Debtors	\N	\N	0.00	Unregistered
33066564-55a3-413e-a19d-52f69778c1ed	c1	Vishnu General Store	Sundry Debtors	\N	\N	0.00	Unregistered
db248359-d3be-4642-9f58-259da15e28e2	c1	VISION HOSPITALITY	Sundry Debtors	09AATFV9621R2ZT	\N	0.00	Regular
ad6118ec-9951-46be-b8d4-1d937385b2a5	c1	Vivek Essence Mart	Sundry Creditors	09AAGPT9094H1ZY	\N	0.00	Regular
28b03ec7-b486-49ab-b142-b091e46ec19b	c1	Vivek Singh	Sundry Debtors	\N	\N	0.00	Unregistered
7bd1d52c-c0ac-4ae7-a63a-ec7a73483b11	c1	V N B Stationers	Sundry Debtors	\N	\N	0.00	\N
5b41c666-e04d-48b9-81aa-d28c287b71e9	c1	V N Enterprises	Sundry Debtors	\N	\N	0.00	\N
1aa722d0-6fb7-4f62-ab9b-ad71a595838e	c1	Vohara Electricals	Sundry Debtors	09ABFPV6408B1ZN	\N	0.00	Regular
008e115c-d175-4c6b-89f6-be392442a8d5	c1	Vohra Electrical	Sundry Debtors	\N	\N	0.00	\N
a81d0b51-ec88-4c45-a611-76aa91f2e8d9	c1	Vookiz Store	Sundry Debtors	\N	\N	0.00	\N
f1b4ef6d-63de-489d-83f5-e59fe61eb34c	c1	Vos Technologies India Pvt Ltd.	Amazon Debtors	07AACCV5922B1ZM	\N	0.00	Regular
29b978f4-6339-4e3d-9090-99f670983de8	c1	VRIDDHI SPECIA;ITY FOODS PVT LTD	Sundry Creditors	09AABCE1185C1ZZ	\N	0.00	Regular
fc1e2ad0-2e90-41f9-8b42-e7d48bcd789d	c1	Vriddhi Speciality Foods	Sundry Creditors	09AANFV9885B1ZF	\N	0.00	Regular
0877d046-9533-4347-aa0c-353e23d97bd9	c1	VRL LOGISTICS LIMITED	Sundry Creditors	\N	\N	0.00	\N
7ccf4c1f-1593-4fa4-b3c8-6baf3a972138	c1	Wadhva Enterprises	Sundry Debtors	\N	\N	0.00	\N
7aee4340-b2a8-4ad8-a24b-94521cc35115	c1	Welcom Mini Mart	Sundry Debtors	\N	\N	0.00	\N
84e3dc01-5ff1-41ea-a596-2e5653945d1c	c1	Wellknown Computers Private Limited	Sundry Creditors	09AAACW5557F1Z4	\N	0.00	Regular
4fb6bb52-54a8-4ff8-89bf-e36842cc0cd3	c1	Wizqart Private Limited	Amazon Debtors	27AACCW2854K1ZZ	\N	0.00	Regular
1bc9a3aa-2e1a-450b-abd9-d3a39ead64fa	c1	Workout Essentials	Amazon Debtors	07AGZPJ4777G1ZN	\N	0.00	Regular
e7b51ca7-6d03-44c2-9fa6-ec2c295aaa7b	c1	Written Off	Indirect Expenses	\N	\N	0.00	\N
d1082f7c-4c8e-44f1-ae34-9ef6b5a3b6d6	c1	Yash	Sundry Debtors	\N	\N	0.00	Unregistered
fdf0aec5-6555-4147-823e-5e1a581d9bb0	c1	Yash Digi Mart	Sundry Debtors	\N	\N	0.00	\N
1bca891e-36a8-414e-a084-520e5eb7b9d5	c1	Yashi Provision Store	Sundry Debtors	\N	\N	0.00	Unregistered
9061bf73-11dc-4456-aad3-7eb8e2f439c9	c1	Yashi Traders	Sundry Creditors	\N	\N	0.00	Unregistered
d9985d2c-6f18-4d85-9cda-50789a62f642	c1	Yellow Baikery	Sundry Debtors	\N	\N	0.00	\N
d793c33d-f694-4ef0-90f8-b775957f3145	c1	Yemmek India	Amazon Debtors	27AIVPB0519L1Z1	\N	0.00	Regular
32fbab32-92b5-427d-b8d6-32c3d48e8869	c1	Yohan Store	Sundry Debtors	\N	\N	0.00	Unregistered
111e762b-da21-43dc-a137-1882778a2748	c1	YOUNITED HEALTHY CONCEPTS	Sundry Creditors	\N	\N	0.00	\N
a7084525-8ec4-447f-b796-991592a06932	c1	Younited Technologies	Sundry Creditors	09AACFY1086A1ZC	\N	0.00	Regular
435650a6-de1f-4e93-af91-f2e3ed7fe5be	c1	Your Local Grocery	Sundry Debtors	09CRZPG1833R2ZQ	\N	0.00	Regular
5966c8fd-8b8f-43ed-b917-93ed4d5ae086	c1	Yuvraj Store	Sundry Debtors	\N	\N	0.00	Unregistered
0e7a4b32-4cc4-4a9c-9141-7f71d72b9de0	c1	Zairo International Private Limited	Sundry Debtors	09AABCZ0555F1ZC	\N	0.00	Regular
0a293df8-3f64-4063-ab80-c4e745d360f3	c1	Zara Genral Store	Sundry Debtors	\N	\N	0.00	Unregistered
0cf8fc04-af83-44d6-9055-4943d2260020	c1	Zaz and Zaz Private Limited	Amazon Debtors	09AAACZ2162K1Z3	\N	0.00	Regular
2ba01eb1-b50f-473c-9506-6a0b647dbd3b	c1	Zed Enterprises	Sundry Debtors	09BVBPD1058G1ZX	\N	0.00	Regular
8576c991-3d6f-4d50-82c8-9f00565d9271	c1	Zenpack Premium Industries Private Limited	Sundry Creditors	24AABCZ2009E1ZT	\N	0.00	Regular
72a2da81-f25d-466a-a536-7e08de2bec19	c1	Zindagi Medical Store	Sundry Debtors	\N	\N	0.00	Unregistered
edb8548f-89c5-4bc3-bf7c-adcc72ebe8c4	c1	Zomato Debtors	Sundry Debtors	\N	\N	0.00	Unregistered
310687b0-0d91-4ef8-8b41-648a252314ac	c1	ZOMATO MEDIA NODAL	Sundry Debtors	\N	\N	0.00	Unregistered
\.


--
-- Data for Name: LineItem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LineItem" (id, "billId", description, "hsnCode", quantity, unit, "unitPrice", "discountPercent", "gstRate", amount, "tallyLedger", "tallyStockItem") FROM stdin;
cmo4nd7wj004wq4bk8saesdwy	b_1776535341654	Lotus Biscuite Spread (5%)	19053100	240	Pcs	425	0	5	102000	\N	Lotus Biscoff Spread (18%)
cmo4nd7wj004xq4bkwjl1piav	b_1776535341654	Lotus Biscuite (5%)	19053100	50	Pcs	200	0	5	10000	\N	Lotus Biscoff Biscuits (Imp)
cmo4nd7wj004yq4bkm04v5hmk	b_1776535341654	NUTELLA 750gm Mrp 819/- (5%)	18069010	120	Pcs	548	0	5	65760	\N	Nutella 750 GM MRP 799
cmo4nd7wj004zq4bke7gqw11p	b_1776535341654	Ramen Noodle 300g*40 Green Label	19021900	80	Pcs	55	0	5	4400	\N	Ramen Noodel 300g
cmo4nd7wj0050q4bkp60ta2wg	b_1776535341654	PassGochujang 500gm (5%)	21039040	24	Pcs	195	0	5	4680	\N	Gochujang Korean Chilly Paste 500 Gm
cmo4nd7wj0051q4bkpkmny7sz	b_1776535341654	NOORI SHEET	21039040	100	Pkt	135	0	5	13500	\N	Sakura Noori Sheet 28 Gm
cmo4nffj2005kq4bk10caeyd9	b_1776535570635	Lotus Biscuite Spread (5%)	19053100	240	Pcs	425	0	5	102000	\N	Lotus Biscoff Spread (18%)
cmo4nffj2005lq4bkuv6khgcm	b_1776535570635	Lotus Biscuite (5%)	19053100	50	Pcs	200	0	5	10000	\N	Lotus Biscoff Biscuits (Imp)
cmo4nffj2005mq4bk4aiycxic	b_1776535570635	NUTELLA 750gm Mrp 819/- (5%)	18069010	120	Pcs	548	0	5	65760	\N	Nutella 750 GM MRP 799
cmo4nffj2005nq4bk6ja4orzp	b_1776535570635	Ramen Noodle 300g*40 Green Label	19021900	80	Pcs	55	0	5	4400	\N	Ramen Noodel 300g
cmo4nffj3005oq4bkex5p8n6z	b_1776535570635	FassGochujang 500gm (5%)	21039040	24	Pcs	195	0	5	4680	\N	Gochujang Hot Pepper Paste 500 Gm
cmo4nffj3005pq4bkoa58znnw	b_1776535570635	NOORI SHEET	21039040	100	Pkt	135	0	5	13500	\N	Sakura Noori Sheet 28 Gm
li_1776537696035_0	b_1776537696035	DU UL AA SBL 8X12X6 OLPP IN LE TP INR 440	85068090	216	PCS	269.83	\N	18	51872.22	\N	\N
li_1776537696035_1	b_1776537696035	DU UL AAA SBL 8X12X6 OLPP IN LE TP INR 440	85068090	216	PCS	269.83	\N	18	51872.22	\N	\N
\.


--
-- Data for Name: StockGroupCache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockGroupCache" (id, "companyId", name, parent) FROM stdin;
cmo4n6fbf0004q4bk0oknv2cq	c1	Abeist Drink	&#4; Primary
cmo4n6fbm0006q4bku8j7v825	c1	All Items	Food
cmo4n6fbo0008q4bk6c64jbgx	c1	ALMOND DRINK	SHS GLOBAL
cmo4n6fbq000aq4bkzk6otkm9	c1	BABY PRODUCTS	&#4; Primary
cmo4n6fbr000cq4bkx9o82nm6	c1	Baby Stroller	&#4; Primary
cmo4n6fbu000eq4bk2igogs3l	c1	Barquillo Chocolate	&#4; Primary
cmo4n6fbw000gq4bkvpppz0wj	c1	BASIL DRINK	SHS GLOBAL
cmo4n6fbx000iq4bkppvqeeor	c1	BATTERY	Universal  STOCK
cmo4n6fbz000kq4bk0wrstowk	c1	Biscuts	&#4; Primary
cmo4n6fc2000mq4bktcxsynka	c1	Blue Tokai	Food
cmo4n6fc3000oq4bk8ulivavv	c1	Box	&#4; Primary
cmo4n6fc5000qq4bkxshxa9jh	c1	CAMEL	&#4; Primary
cmo4n6fc7000sq4bkbgefspzw	c1	Chocolate	&#4; Primary
cmo4n6fc9000uq4bk50nykd0c	c1	Cleanor	&#4; Primary
cmo4n6fcb000wq4bk0w62jtt7	c1	COCOCNUT	&#4; Primary
cmo4n6fcd000yq4bkptlifz9z	c1	Confationery	Food
cmo4n6fcf0010q4bkptcbpjaw	c1	Cosmatics	&#4; Primary
cmo4n6fch0012q4bk6khnxvyy	c1	Dairy Products	&#4; Primary
cmo4n6fcj0014q4bkvdijmml5	c1	Deo	&#4; Primary
cmo4n6fcl0016q4bkaio3jcpk	c1	Devak Food	&#4; Primary
cmo4n6fcm0018q4bkesuktf7q	c1	Drinks	&#4; Primary
cmo4n6fco001aq4bk0i7fn1k1	c1	Drycell	Electrical Goods
cmo4n6fcq001cq4bkq5o6gpr3	c1	Electrical Goods	Universal  STOCK
cmo4n6fcs001eq4bk5e5yhbsv	c1	Energy Drink	&#4; Primary
cmo4n6fct001gq4bkbsxf0mlm	c1	Equal	Sugar Free
cmo4n6fcv001iq4bke7ighp4c	c1	Farm Dilight	&#4; Primary
cmo4n6fcx001kq4bk7t4lwvs6	c1	Food	&#4; Primary
cmo4n6fcz001mq4bk04eah1td	c1	Ghee	Devak Food
cmo4n6fd1001oq4bkuk821ap5	c1	Golden Crown	&#4; Primary
cmo4n6fd3001qq4bkhkbxoyf8	c1	Good Vibe	SHS GLOBAL
cmo4n6fd5001sq4bkoujg4oms	c1	Grains	Food
cmo4n6fd7001uq4bk7lzhd82v	c1	GURU FOOD	&#4; Primary
cmo4n6fd8001wq4bkkusfy3ka	c1	HUL	Food
cmo4n6fda001yq4bkc5r6xdna	c1	Ibizza	Drinks
cmo4n6fdb0020q4bkemwp0v56	c1	Indica Amla	&#4; Primary
cmo4n6fdd0022q4bk57c55fmi	c1	Italian Garden	&#4; Primary
cmo4n6fdg0024q4bka94p74s0	c1	JAGGARY	&#4; Primary
cmo4n6fdi0026q4bkwr1c0af9	c1	JUICE	Drinks
cmo4n6fdj0028q4bk1m009xfm	c1	Khakhara	Devak Food
cmo4n6fdl002aq4bksvs793pp	c1	Lamp Oil	Devak Food
cmo4n6fdm002cq4bk7ui9mzmy	c1	Namkeen	&#4; Primary
cmo4n6fdo002eq4bkz7ndbsga	c1	NATURAL MEHANDI	&#4; Primary
cmo4n6fdp002gq4bkkq1n8itn	c1	Nilons	Food
cmo4n6fdr002iq4bkdtd3g7va	c1	OATS	Universal  STOCK
cmo4n6fdt002kq4bk10d2zcbw	c1	Oil	&#4; Primary
cmo4n6fdv002mq4bkko7th5pn	c1	One 8 Deo	Cosmatics
cmo4n6fdy002oq4bk1v5vz24m	c1	Organics	Food
cmo4n6fdz002qq4bk76kc78gu	c1	PAAN	&#4; Primary
cmo4n6fe1002sq4bk8ei0x7oq	c1	Packing Material	&#4; Primary
cmo4n6fe3002uq4bk5nvhlww6	c1	Papad	Devak Food
cmo4n6fe5002wq4bk9j3ct1bj	c1	Party Snacks	&#4; Primary
cmo4n6fe6002yq4bkdzyboi9c	c1	Pasta	Universal  STOCK
cmo4n6fe90030q4bkcfkaj87g	c1	Pathlogical Goods	&#4; Primary
cmo4n6fea0032q4bkvt7m8ufb	c1	Pickel	Indica Amla
cmo4n6fec0034q4bkw7l6b267	c1	Plane B Coffee	&#4; Primary
cmo4n6fef0036q4bkytfkgwg4	c1	Rani 180 Ml	&#4; Primary
cmo4n6feg0038q4bkmhh830jm	c1	Rani Can	SHS GLOBAL
cmo4n6fei003aq4bk95xg5psm	c1	RICE	&#4; Primary
cmo4n6fej003cq4bk8tumynmh	c1	ROYAL GROVE	&#4; Primary
cmo4n6fel003eq4bk9bd2e2vs	c1	Sanatry Napkin	&#4; Primary
cmo4n6fen003gq4bk3fdtcnuz	c1	Seed	&#4; Primary
cmo4n6feo003iq4bkp0jz0rt2	c1	SEPOY DRINK	&#4; Primary
cmo4n6feq003kq4bkz5c86qrs	c1	SHS GLOBAL	&#4; Primary
cmo4n6fes003mq4bkz65cbdrr	c1	Sohan Papadi	Devak Food
cmo4n6feu003oq4bk2aku733r	c1	Spices	&#4; Primary
cmo4n6few003qq4bkpztp5ei4	c1	Sugar Free	&#4; Primary
cmo4n6fey003sq4bkxlpwx2gq	c1	TEA	Drinks
cmo4n6fez003uq4bkjmbaejzg	c1	TEA FLAVOURED	Drinks
cmo4n6ff1003wq4bk7usv9twl	c1	Tricycles	&#4; Primary
cmo4n6ff3003yq4bkk1x4da8y	c1	Tru Taste	&#4; Primary
cmo4n6ff40040q4bkgt92dv0l	c1	Tryceles	&#4; Primary
cmo4n6ff60042q4bk7wgvvpar	c1	United Distributor	&#4; Primary
cmo4n6ff80044q4bkk5p11s82	c1	Universal  STOCK	&#4; Primary
cmo4n6ff90046q4bkdhnab56q	c1	Vatika Pickel	Indica Amla
\.


--
-- Data for Name: StockItemAlias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockItemAlias" (id, "companyId", "stockItemCacheId", "billItemName") FROM stdin;
cmo4nd0fw004nq4bk6i1mkqsf	c1	0b3158ad-bb01-4329-8234-7b2043d0d1ff	passgochujang 500gm (5%)
cmo4nd0f40049q4bkc80gk9uz	c1	c48d249e-a881-4ea2-80a3-8e8cf9de3d56	lotus biscuite spread (5%)
cmo4nd0ff004hq4bkf5qtxftc	c1	bc5b2a7a-66ba-4a4c-9d67-a6180b93c290	lotus biscuite (5%)
cmo4nd0fk004jq4bkwagf98sf	c1	21a1948c-e891-4f10-992e-a96ea47ddd62	nutella 750gm mrp 819/- (5%)
cmo4nd0fp004lq4bk491erren	c1	e6553aa7-8feb-4b7f-9cf2-3e3f7da9248e	ramen noodle 300g*40 green label
cmo4nffm0005zq4bk9l0lywsp	c1	44794c04-4f05-4bbc-902c-4211329fef4b	fassgochujang 500gm (5%)
cmo4nd0g1004pq4bkuy8hdqr2	c1	5453528d-6da7-4fd1-a7b4-0dd8107a738f	noori sheet
\.


--
-- Data for Name: StockItemCache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockItemCache" (id, "companyId", name, "group", unit) FROM stdin;
ed58e3a4-80e6-4638-b030-ee3ef032525f	c1	Black Rice	Food	Pcs.
bacdf7b0-a213-4980-8110-297f5ea47f4c	c1	Alfredo 180g.	Chocolate	Pcs.
1ab9d29c-7d42-4545-9c3e-b7257f30cbf3	c1	Bael Candy-500g	Food	Pcs.
49d04842-ab03-453a-9340-78dc2c58c150	c1	Chlt.Awsome 125g	Chocolate	Pcs.
acce6d87-6fa8-4927-8009-a52f786791e2	c1	Green Tea	TEA	Pcs.
017e39b3-bd7c-4a27-99a8-c077d43a5d36	c1	Maggie Veg Cube	Food	Pcs.
b2076442-e733-4519-afc7-3938f2fe209a	c1	12% Akadia White Feta 500 Gms	Dairy Products	Pcs.
e7f34397-6b65-4e21-8a64-83909cbdf7ee	c1	12% Cheese Akadia Combi White 200 Gm	Dairy Products	Pcs.
9d30635e-d62b-4685-a969-03a43bfefb4b	c1	12% Cheese Breton Camembert 125 Gm	Dairy Products	Pcs.
eba4ff1d-fbcd-46de-ac66-7b08c62d7dd1	c1	12% Cheese Emborg Brie	Dairy Products	Pcs.
53add8d2-ab18-4105-8526-e66993d3bc2c	c1	12% Cheese Frico Edam Wedges 235 Gm	Dairy Products	Pcs.
3ab3ba57-aba9-417d-b1f2-2a91586eab33	c1	12% Cheese Frico Gouda Wedges 295gm	Dairy Products	Pcs.
6aa6a075-fbf8-4963-9a24-969d62fe71f4	c1	12% Cheese Granarolo Grana Padano 1/8 (4.5 Kg)	Food	kg.
29a41687-c5f0-430e-b7f9-89d654ae7e70	c1	12% Cheese Granarolo Quattrocento 150gm	Dairy Products	Pcs.
161f8b47-f53c-407e-a88b-dfa5f7a0ed9f	c1	12% Cheese Mild Coloured Cheddar Cheese 200 Gm	Dairy Products	Pcs.
e6201a5c-3957-4b0e-b503-797694d77ce7	c1	12% Cheese Papouis Halloumi 250gm	Dairy Products	Pcs.
7f38c5ab-e74e-4671-ab95-be1f0583111b	c1	12% Cheese Payson Breton Pasteurised Brie 125 Gm	Dairy Products	Pcs.
0cd71dda-42e0-4659-ab3b-4c4198246a6c	c1	12%Gran Sapore Balsmic Vinegar Glaze 250ml	Oil	Pcs.
27638131-257d-4bed-9642-4c4ac8705b1b	c1	12% ITALIAN HARD CHEESE CE 1/8TH9veg.Parmasan)5kgs	Dairy Products	kg.
03e8da05-25ae-41cf-bb43-c8a66d323275	c1	12 % Monte Christo Coloured Cheddar Block 2.5kg	Dairy Products	kg.
22374649-aa30-4628-8392-3965f06018e9	c1	12% Paysan Breton Emmental Portion 220 Gm	Dairy Products	Pcs.
c701fbc5-0e63-4f22-9d1e-94fe2279e915	c1	12% Perrier Water Glass Bottle 750ml	Drinks	Pcs.
73c03c5f-1da7-4d3e-ae80-e15e838011b7	c1	12% Philadephia Cream Cheese 226 Gm	Dairy Products	Pcs.
5970af32-2038-403a-a1f5-0caf35bac37e	c1	12% Taverma Greek Feta PDO 200 Gm	Dairy Products	Pcs.
fbb0d30c-2f44-4a33-ae41-37b962c2df3c	c1	12% Wyke Mild White Cheddar 200 Gm	Dairy Products	Pcs.
04f42da2-a229-44dc-9be8-4641588621fb	c1	123 Zaa Candy 330gm.	Food	Pcs.
e6fb7f04-2208-4086-a168-351717048e17	c1	137 Almond Drink Sweetened Wih Stevia 1 Ltr	ALMOND DRINK	Pcs.
5c7f0099-2f11-4994-ad4c-a2e74433f487	c1	137 Almond Drink Unsweetened 1 Ltr	ALMOND DRINK	Pcs.
88f774a6-12cf-461d-94f0-53045a9db68f	c1	137 Almond Milk Original 1 Ltr	Drinks	Pcs.
436178f4-d18d-4291-aed1-2433ddf880e4	c1	137 Almond Milk Orignal 180ml.	Drinks	Pcs.
0bd3c77d-79ff-4ab5-8a86-eb4b1c656296	c1	137 ALMOND MILK UNSWEETENET 1 Ltr	Drinks	Pcs.
206c66a2-64b4-473d-ae98-b215d063cf17	c1	137 Almond Milk Unswentend 180ml	Drinks	Pcs.
1a94f635-9ed7-41b4-88b6-d4b3ce8efcc3	c1	137 Almond Milk with Coffee Latte 180ml.	Drinks	Pcs.
f880025c-b347-4391-99e5-63170f679acc	c1	137 Degree Almond Milk Original 180ml	Drinks	Pcs.
88a0f9b4-fe38-4489-a79a-6a5160967952	c1	137  Degree Almond Milk Original 1ltr.	Drinks	Pcs.
76049109-8597-46a0-9242-9ce8f8e4df36	c1	137 Degree Almond Milk Unsweetened 180 Ml	Drinks	Pcs.
bb003ee3-a4fe-4a52-bc7e-4af79aa38a99	c1	137 Degree Almond Milk Unsweetened 1ltr	Drinks	Pcs.
96243a89-ca5f-467b-aee7-ed39ad5fdde1	c1	137 Degree Almond Milk with Coffee Latte 180ml	Drinks	Pcs.
24b81000-6db8-46a8-8481-16338dc88346	c1	137 Degree Pistachio Milk Double Choclate 180ml	Drinks	Pcs.
f3c2835f-0e49-4f81-85d2-3f8d74f2bf22	c1	137 Degree Pistachio Milk Double Choclate 1ltr	Drinks	Pcs.
b15d512c-2c3f-4769-a78d-e3c26d4fb658	c1	137 Degree Pistachio Milk Original 180ml	Drinks	Pcs.
d93ec080-8933-4caf-bda0-cd85bd105638	c1	137 Degree Pistachio Milk Original 1ltr	Drinks	Pcs.
da638117-95a0-4da1-b18d-c5bd85c37596	c1	137 Degree Walnut Milk Original 1ltr	Drinks	Pcs.
f467f0bb-19fa-472d-8fe7-b5a23dfd7779	c1	137 Oat Drink Unsweetened 1lt	Drinks	Pcs.
c28a03c7-8891-4712-be92-159e501693fe	c1	137 Pistachio Milk Orignal 180ml	Drinks	Pcs.
649b751f-e17e-4f47-a6c6-66d306c33151	c1	137 Pista Chio Milk Orignal 1 Ltr	Drinks	Pcs.
27004919-0804-4a2d-a252-3d37f34e9dfa	c1	137 Pistacho Milk with Double Cholate 180 Ml	Drinks	Pcs.
56ea4fe1-5438-450b-8ad6-8f8c87a711bf	c1	137 Walnut Milk Orignal 180ml.	Drinks	Pcs.
2705761a-a9d3-4e8f-96e3-aeed856b7f74	c1	137 Walnut Milk Orignal 1 Lt	Drinks	Pcs.
2d30e6b3-ca72-4b25-8983-afcaf9738de5	c1	137 WALNUT WITH MATCHA GREEN TEA 180ML	Drinks	Pcs.
63f08dce-465b-468a-a271-abcd187a3e8a	c1	18% Marvel Deo Doctor Strange 200 ML Mrp.249	One 8 Deo	Pcs.
94532206-1898-4c29-8a23-46e431e4e625	c1	18% Marvel Deo Hulk 200 Ml Mrp.249	One 8 Deo	Pcs.
32e3e051-32f7-4f90-9ccd-93158158a14a	c1	18% Marvel Deo Thor 200 Ml Mrp.249	One 8 Deo	Pcs.
f7a27937-4b4f-4c65-ac05-933e69d1544a	c1	18% One8 Blends EDT Blanc 110 Ml Mrp.595	One 8 Deo	Pcs.
f5588d76-17a8-4e3a-b06f-cd26566dba58	c1	18% One8 Blends EDT Bleu 110 Ml Mrp.595	One 8 Deo	Pcs.
d607a103-efba-4d54-95ba-974e5b78d3c6	c1	18% One8 Blends EDT Emerald 110 Ml Mrp.595	One 8 Deo	Pcs.
349c9035-3d9b-4bce-a2b0-819f15a14d39	c1	18% One8 Blends EDT Gold 110 Ml Mrp.595	One 8 Deo	Pcs.
07a34441-4ede-4523-ab61-f828eadab1ac	c1	18% One8 Blends EDT Noir 110 Ml Mrp.595	One 8 Deo	Pcs.
f429f806-264e-4d59-9053-159c9af45d48	c1	18% One8 Blends EDT Rouge 110 Ml Mrp.595	One 8 Deo	Pcs.
520e5698-530b-4c6f-949d-5a914e8b6f43	c1	18% ONE8 EDP POCKET SPARY WITH CAP-ACTIVE	One 8 Deo	Pcs.
730e44d3-5fc0-4b3a-acd2-453e391c55d8	c1	18% One 8 EDP Pocket Spray Intense + Pure Mrp.75	One 8 Deo	Pcs.
825c9f18-9845-4010-ac4f-d86b40264623	c1	18% One8 EDP Pocket Spray Willow + Active Mrp.75	One 8 Deo	Pcs.
3acee0b0-3491-4cf5-b794-2d8b425d49f5	c1	18% ONE8 EDP POCKET SPRAY WITH CAP-AQUA	One 8 Deo	Pcs.
219775e7-7834-47b6-8276-cbf92517670b	c1	18% ONE8 EDP POCKET SPRAY WITH CAP-FRESH	One 8 Deo	Pcs.
d3468938-844f-456c-a2ac-c2582051a272	c1	18% ONE8 EDP POCKET SPRAY WITH CAP-PURE	One 8 Deo	Pcs.
284c8a19-55b6-450b-b218-80fa00be317e	c1	18% ONE8 NO GAS DEO AURA 120ML RS. 295	One 8 Deo	Pcs.
8d1f37ce-e1fd-490d-8748-d192bd4f5272	c1	18% ONE8 NO GAS DEO KING 120ML RS. 295	One 8 Deo	Pcs.
4b67d8d9-2f04-45a1-a92a-713ea0d1bf92	c1	18% ONE8 NO GAS DEO LEGEND 120ML RS. 295	One 8 Deo	Pcs.
d2e34389-67b4-4d6a-b146-13c15cf40328	c1	18%One8 Perfume Body Spray Drive 200 Ml Mrp.349	One 8 Deo	Pcs.
408d8a40-9927-4661-a374-0b5261ea53d7	c1	18% One8 Perfume Body Spray Flick 200 Ml Mrp.349	One 8 Deo	Pcs.
b85095db-99e6-4f3e-9f4f-380e77948dcd	c1	18% One8 Perfume Body Spray Glance 200 Ml Mrp.349	One 8 Deo	Pcs.
f1548147-58be-48ee-a01d-06aaa0019120	c1	18% One8 Perfume Body Spray UpperCut 200 Ml Mrp.349	One 8 Deo	Pcs.
2f84b2af-91a3-4758-af92-ca9dae4a0fae	c1	18% ONE8 POCKET SPRAY WITH CAP-WILLOW	One 8 Deo	Pcs.
b75d7e6a-ac5f-4c22-8e50-468bc57f78d3	c1	200g BREAD TOAST	Food	Pcs.
df96ffa0-7e4b-4320-8525-d785292d5083	c1	2 Brother Flex Seed	Seed	Pcs.
b60bad69-1abb-47a0-ae34-5ef9d39900a6	c1	2 Brother Pumpkin Seeds	Seed	Pcs.
6d184d56-b1d1-45b0-8009-373deae2528d	c1	2 Brothers Black Pitted Olive 476gm	Food	Pcs.
7ad111cd-ee4d-4971-bc9d-2406cb1e2c5e	c1	2 Brothers Green Pitted Olive 476gm	Food	Pcs.
fad3a918-ac17-413c-aefe-287185daf57e	c1	2 Brothers Sunflower Seeds	Seed	Pcs.
2b983174-0e17-49f0-ab67-265d357d846d	c1	40 % (200 Ml) CRAVOVA Classic Mojito Mrp.30	Drinks	Pcs.
9cb3588e-535e-433a-80e6-5ba47b5e4854	c1	40 % (200 Ml) CRAVOVA Green Apple Mojito Mrp.30	Drinks	Pcs.
087ea369-c7c4-47be-ba6d-35d20680d1c0	c1	40 % (200 Ml) CRAVOVA Kiwi Mojito Mrp.30	Drinks	Pcs.
9baa290e-167d-433f-9690-387c6545ada7	c1	40 % (200 Ml) CRAVOVA Orange Mojito Mrp.30	Drinks	Pcs.
d2c1e833-15d3-45c0-b0dc-df67a0ba2b55	c1	40 % (200 Ml) CRAVOVA Peach Mojito Mrp.30	Drinks	Pcs.
71420d62-6ba4-4aba-a6f3-f2ac2be6c93b	c1	40 % (200 Ml)  CRAVOVA  Watermelon Mojito Mrp.30	Drinks	Pcs.
71283868-f157-44ae-bf6d-38cc7baaf002	c1	40 % (300 Ml) CRAVOVA Classic Mojito Mrp.50	Drinks	Pcs.
8f24bda2-90fa-4b3f-bcd5-09b6256f6731	c1	40 % (300 Ml) CRAVOVA Fresh Lemonade Mrp.50	Drinks	Pcs.
734af953-68a7-45a1-9ba0-e44275b85702	c1	40 % (300 Ml) CRAVOVA Green Apple Mojito Mrp.50	Drinks	Pcs.
92724d56-323e-44a6-b2a2-321d0b25938c	c1	40 % (300 Ml) CRAVOVA Kiwi Mojito Mrp.50	Drinks	Pcs.
507136f7-83b6-45fb-b1b1-ec111a8e1c83	c1	40 % (300 Ml) CRAVOVA Orange Mojito Mrp.50	Drinks	Pcs.
16c5ace0-7443-486d-94f2-76df582cbf2f	c1	40 % (300 Ml) CRAVOVA Peach Mojito Mrp.50	Drinks	Pcs.
dd84a9ee-d483-4689-8f11-34616b770cfa	c1	40 % (300 Ml) CRAVOVA Watermelon Mojito Mrp.50	Drinks	Pcs.
4b2c89f5-cfc3-436f-a417-6d45c7ad829a	c1	8 TO 8 (DATES) SAUCE 200GM	Food	Pcs.
463e7f16-04aa-43b8-a723-a8fc472d67c9	c1	9Days Chocolate Chips Oat Cookies 160gm.	Biscuts	Pcs.
6ce5b091-7790-4c55-af9d-585152ccc0ac	c1	9Days Currunt Cookies 160g.	Biscuts	Pcs.
67ff4a2c-84d1-4fb2-9ffa-44b2d3c5513d	c1	9Days Currunt &amp; Oat Cookies 160gm	Biscuts	Pcs.
fda7e60e-0ca5-4f62-be0e-bd8fac9c30da	c1	Abbie&apos;s Capers in Brine 100 Gm (12%)	Food	Pcs.
73108e26-1206-4ffe-9cdd-d751d67ba9db	c1	Abbie&apos;s Coconut Milk 400 Ml	Drinks	Pcs.
b86a6a00-8579-435b-b918-ef9b66443df4	c1	ABBIE&apos;S PICKLE PIRI PIRI IN BRINE 100GM	Food	btl.
dad1d63e-a0f5-4fa4-b691-8226f19decde	c1	Abbie&apos;s Pickle SPN  Piri Piri in Brine 100 Gm	Food	Pcs.
b2392669-75d6-4541-b90f-fa678f95240c	c1	Abbie&apos;s Quinoa Seeds 500 Gm	Food	Pcs.
c4b18629-0ac5-43b3-ad40-7ab7a59ed89c	c1	Abbies&apos;s Arborio Rice 1 Kg	Food	Pcs.
f783a544-9084-40a2-8bc1-4ecf723263f7	c1	Abbies Appel Cider Vinegar 473ml.	Drinks	Pcs.
8695a83d-ea09-4bfe-a83f-ca5059498de5	c1	Abbies Bbq Sauce Original 510gm	Food	Pcs.
690df6bd-9d38-439c-85a4-0e7410e32a49	c1	Abbies Black Pitted Olives	Food	Pcs.
4f728a8c-1a27-47a3-a835-ea57e4963113	c1	Abbies Black Sliced Olives	Food	Pcs.
56d51644-ee29-4c4a-a634-339cae4c7672	c1	Abbies Corn Kernal in Brine (Canned)400 Gm	Food	Pcs.
66cc55d3-9ffd-4045-af93-b6efb108bda3	c1	Abbies Green Pitted Olives	Food	Pcs.
c2b5d9db-d6eb-4535-9a7e-e29213a95dfd	c1	Abbies Green Sliced Olives	Food	Pcs.
2b1fea85-2823-449c-bb4c-5aa52f0e1f93	c1	ABBIES JALAPENO SLICED IN BRINE 3K	Food	Pcs.
18db7a9f-f38e-4576-aeee-f247863940be	c1	Abbies Panko Bread Crumbs 200 Gm	Food	Pcs.
7345562f-fcd3-4fc8-ad5e-afbae5807e64	c1	Abbies Peanu Butter Creamy 1 Kg	Food	Pcs.
32d08968-936c-48ec-baca-c84a216e1580	c1	Abbies Pesto Green (Genoveses)	Food	Pcs.
5054e828-7001-4c41-883c-5e54961ef9a8	c1	Abbies Pickel Red Paprika	Food	Pcs.
432f4e01-3293-41f1-a642-0fb36605c05b	c1	Abbies Pickle Gherkin Big in Brine	Food	Pcs.
7298d292-c3d3-47ed-aaca-59b1d00492a8	c1	Abbies Pure Maple Syrup 250ml	Food	Pcs.
c13deeba-6041-4bf6-bf23-5b9b5479da52	c1	ABBIES YELLOW MUSTERD 255GM.	Food	Pcs.
bd62c665-fd3e-4e53-b54b-411d1a93ce8f	c1	Abc Sweet Soya	Food	Pcs.
9b13bcad-a42d-43ea-acf6-539279e5bd32	c1	Abest Cocktaik 320ml	Abeist Drink	Pcs.
a1e40572-6eed-426f-9808-74d9aee986e6	c1	Abest Lychee 320ml	Abeist Drink	Pcs.
89e452df-a52d-4321-b8b6-7924cfedb452	c1	Abest Mango 320ml	Abeist Drink	Pcs.
675739fb-550c-4929-a5ac-34ed8d930c2a	c1	Abest Peach 320ml	Abeist Drink	Pcs.
6931dba8-f8b6-4b8e-8330-825daad65efa	c1	Abest Pineapple 320ml	Abeist Drink	Pcs.
d4ceffc1-4d82-4813-880b-892476375ff8	c1	Abest Strawberry 320ml	Abeist Drink	Pcs.
125543aa-0b5a-42e8-8404-0dc9b4f262da	c1	ACE GHERKINS IN JAR	Food	Pcs.
379bc5c0-cc2a-453c-a10e-52918c68b885	c1	ACE JALAPENO SLICE N JAR	Food	Pcs.
802611b1-2438-40b7-bf9a-0b422b78391d	c1	ACE MUSHROOM 800GM.REGULAR	Food	Pcs.
b562654c-1bb4-4ff2-963f-443314e21ddd	c1	ACE MUSHROOM 800GM.(TANDOORI)	Food	Pcs.
8a1ca83a-8da2-4487-9a33-979f3d26359f	c1	ACE MUSHROOM SLICE 800GM.	Food	Pcs.
9a4ef119-97be-42b8-bb9c-095b58e01828	c1	Aceto Balsmic Vinegar	Drinks	Pcs.
736df651-e00b-40a1-8242-ee58ce884f75	c1	ACE TOMATO PUREE 825g	Food	Pcs.
f60ae5f9-4e4d-46ef-b143-e2d9df55f9ef	c1	Aceto Red Wine Vinegar 1 Ltr (18%)	Food	Pcs.
4ae47885-d874-43b0-a491-5202ce0da041	c1	Aceto White Wine Vinegar 1 Ltr (18%)	Food	Pcs.
4472bfdf-75b0-4ca8-a0aa-49efb32c07bd	c1	Acorsa Pitted Black Olives (12*230gm)	Food	Pcs.
86ffb26d-bd0a-49c1-a92d-6ddee930ca14	c1	ACORSA PITTED BLACK OLIVES 230GM.	Food	Pcs.
a67bcdf5-65d0-47b9-8009-d0098e0c1839	c1	Acorsa Pitted Green Olives 230gm.	Food	Pcs.
8a20c6da-23a0-438c-b3e7-b706d8850b5a	c1	Acrosa Sliced Black Olive 1.560 Kg	Food	Pcs.
77cc58e3-269b-4dc7-816a-9c141d416ca7	c1	Acrosa Sliced Black Olives 3kg.	Food	Pcs.
980efcd8-f3f0-4ef2-a071-81228c638553	c1	Activate Charcoal 500 Gm	&#4; Primary	Pcs.
77c0439e-ffdb-4071-a665-9e6f9c99089d	c1	Adlt.Daiper Feelfree L-XL	Sanatry Napkin	Pcs.
9c11d434-36b2-4822-b065-f5c01dcf0027	c1	Adlt.Daiper Feel Free M MRP.480	Sanatry Napkin	Pcs.
8b24819b-b108-4d06-bd39-1ffc1980551b	c1	Adlt.Daiper Kare in Pull Ups M-10	Sanatry Napkin	Pcs.
dd338e0e-62eb-42c0-919c-ee39128e0dde	c1	Adlt FF Large -10 Rs.510/-	Sanatry Napkin	Pcs.
99ec4590-d185-4196-b2d6-deb8593fc1a8	c1	Adlt.FF Large Rs.480/-	Sanatry Napkin	Pcs.
ed9b3a19-2eb8-48d9-8d4f-7c26de143d93	c1	ADLT.F.F.MEDIUM 10PCS RS.400/-	Sanatry Napkin	Pcs.
03c9e890-9b11-45dd-a052-e8fc4946abf6	c1	Adlt.FF Medium Rs.430/-	Sanatry Napkin	Pcs.
a7a3b16c-24c4-47f9-a3d1-23f9ff6a7422	c1	ADLT.F.F.ML 10PCS.RS.450/-	Sanatry Napkin	Pcs.
1bac0809-318d-4122-b257-a33bf6822b8c	c1	Adlt.Kare in Pull Up M Free	Sanatry Napkin	Pcs.
0e7d57db-1f3f-407f-bed5-c37b69f74bad	c1	A G Apple Cider	Drinks	btl.
2f825b49-dc40-4e09-9edd-8aebb49ef9cb	c1	Ag Apple Cider Vinegar 473ml	Drinks	Pcs.
cbf8095c-b3e2-4e1a-bbe7-ed79f6765429	c1	Agar Agar Powder 50 Gm (18%)	Food	Pcs.
33a7489e-2598-4d6f-9589-6c7791b98eb3	c1	Agaro Beard Trimmer Mt-7001 Mrp.1245	Electrical Goods	Pcs.
9f3e1359-b786-42bd-86ec-1df70be0eccc	c1	Agaro Mixer Grinder - 750w	Electrical Goods	Pcs.
4db81f1e-4d45-4f6e-bd7f-717204c949ef	c1	Agaro OTG Marvel Series 38 Its (Sample)	Electrical Goods	Pcs.
b6cc2e47-a9de-44d6-9464-b80d7d2d49eb	c1	AGARO REGAL VACUM FLASH 750ML	Confationery	Pcs.
2061c0d4-27d5-4021-a101-b945d226d33d	c1	AG Bbq Sauce 510 Gm (IMP)	Food	Pcs.
bfc9d9d1-7d58-4b65-b27f-35e3ae526d58	c1	AG BBQ SAUCE ORIGINAL 510GM	Food	Pcs.
4e8b8cbd-c8d4-46ff-a0da-b5673af5ad40	c1	Ag Beard Trimmer Mrp.1195	Electrical Goods	Pcs.
615c2af5-4f71-4606-9a1f-96b1d62d6465	c1	AG BP MONITOR -501	Electrical Goods	Pcs.
72238391-66ad-44ac-a201-435b75a8bfd2	c1	AG BP Monitor-501A with Adopter	Electrical Goods	Pcs.
6ac55168-7f0e-45c6-8c19-fe558cc290ea	c1	AG Bread Cumbs Plain 425 Gm	Food	Pcs.
ebd81706-3e9c-41e9-84e6-69aa78fdca8c	c1	Ag Breeze Flat Hairbrush Mrp.199	Cosmatics	Pcs.
434ec072-de30-46fb-9106-0dafd554b71e	c1	Ag Breeze Paddle Hairbrush - Yellow Mrp.249	Cosmatics	Pcs.
34067fb6-e065-466b-ab9f-a0363f4361dc	c1	Ag Breeze Round Hairbrush Mrp.199	Cosmatics	Pcs.
e61137da-1d7d-4b6c-a575-f34ce149b2b2	c1	Ag Classic Cushion Hairbrush Mrp.199	Cosmatics	Pcs.
71a1910c-d507-492c-8f6c-a2fcc7a4525a	c1	Ag Classic Flat Hairbrush Mrp.199	Cosmatics	Pcs.
a9a67929-ad24-4586-8a7b-e1fb3157375b	c1	Ag Classic Paddle Hairbrush Mrp.249	Cosmatics	Pcs.
4736d753-fa75-4a69-b10f-8ce8477c2d5f	c1	Ag Classic Round Hairbrush Mrp.199	Cosmatics	Pcs.
9c325ab0-c611-4a7f-a6db-60fb20614909	c1	AG COMPRESSOR NUBUILIZER	Electrical Goods	Pcs.
a3da93be-2ef2-40d3-a538-5c240b407da0	c1	Ag Delight Paddle Hairbrush Mrp.249	Cosmatics	Pcs.
f3ec3c23-3ecd-4441-99cc-985be375d119	c1	AG Delight Vaccume Flask 1000ml.	Electrical Goods	Pcs.
74739c22-ce94-46fb-b702-b76f421bf274	c1	AG Delight Vaccume Flask-500ml.	Electrical Goods	Pcs.
45e71e6f-5f0d-431b-9974-c42c5dcaa8f4	c1	AG Delight Vaccum Flask 1000 Ml (Mrp.880)	Confationery	Pcs.
cf492937-4863-4871-b5b6-3b3e20b45111	c1	AG Delight Vaccum Flask 500 Ml (Mrp.620)	Confationery	Pcs.
d3d107e0-138f-4433-8c92-2495bc443727	c1	Ag DIGITAL THERMOMETER DT-555	Electrical Goods	Pcs.
f74ebd71-0a57-4f99-99d4-cbbc7fb72932	c1	AG-DS 321-Battery Shaver Rs.845/-	Electrical Goods	Pcs.
7d42d49f-582e-455e-ab17-030df6d55006	c1	AG-DS 581 Quick Shaver 2 Head Rotary Rs.1045/-	Electrical Goods	Pcs.
3aae170e-6645-4112-aa8b-15b0179eb698	c1	AG-DS-761-Electric Shaver Rs.1595/-	Electrical Goods	Pcs.
230438c4-550c-4615-b26a-3b2b9305945b	c1	AG-DS-Quick Shaver Q 2 Head Rotatory Rs.995/-	Electrical Goods	Pcs.
87b3d72c-e110-4f60-8bd3-cc5ca80add7c	c1	Ag Grape Vine Leaves	Food	Pcs.
bca72335-28c7-4ad8-898a-3ba47b6c074b	c1	AG-Hair Clipper HC-1548	Electrical Goods	Pcs.
c947bd0c-ecc4-4e2f-a611-3ca78386ed68	c1	AG-HC-4015-Clipper Complete Care Rs.1095/-	Electrical Goods	Pcs.
a70a0029-c516-409e-b184-ef5314aa332c	c1	AG-HD-5423-Saloon Pro Rs.1295/-	Electrical Goods	Pcs.
9c92aad0-772c-468e-977c-0d98ea22b815	c1	AG-HD-6501-Style Essesntial Rs.595/-	Electrical Goods	Pcs.
88a2e29f-5c2f-4b9a-b71f-9dce8e9a8d3b	c1	AG-HD-7989-Saloon Pro Shine Rs.1495/-	Electrical Goods	Pcs.
4bbe2e79-4c19-49e5-8727-4b0c51171644	c1	AG-HD-9826-Style Diva Rs.695/-	Electrical Goods	Pcs.
966db96e-553f-4ef1-8a5b-3f8620bbdf7d	c1	Ag HD - Style Diva Mrp.745	Cosmatics	Pcs.
23c5468f-1a57-49dc-b7c0-e2c0e6bae948	c1	Ag HD Style Essential Mrp.595 (Purple)	Cosmatics	Pcs.
592ae969-b4ab-4485-b6e1-2badb1361ae2	c1	AG-HS-6511 Instastraight Nano Rs.995/-	Electrical Goods	Pcs.
a4a08010-0231-4ac0-91d4-c16bbdd88d38	c1	AG-HS-7512 Instastraight Slim Rs.1595/-	Electrical Goods	Pcs.
6da0080f-6f64-484c-afae-ccfecfd92b88	c1	AG-HS-8543 Instastraight Titanium Rs.1995/-	Electrical Goods	Pcs.
fa7745a4-def3-4110-8671-82fab5c8cd29	c1	AG-HS-8590 Instraight Premium Rs.1795/-	Electrical Goods	Pcs.
d0b59f73-e373-4e61-b23a-629827b50647	c1	AG-HS-9201 Instratepro Rs.1295/-	Electrical Goods	Pcs.
359bc4f2-a475-4ce7-bd36-b9ed40016aeb	c1	Ag Instastraight Nano Mrp.995	Electrical Goods	Pcs.
46b06d30-aae8-4184-965f-b94142946adf	c1	AG Led Bulb Smart-12watt	Electrical Goods	Pcs.
d6b9384d-2a40-416b-bb0e-37ccf0ebb6e7	c1	AG Led Bulb Smart-7 Watt	Electrical Goods	Pcs.
08cade6e-5a35-4cf5-b92b-8e161b72023c	c1	AG Led Bulb Smart-9watt	Electrical Goods	Pcs.
ae6bea35-f0fd-4616-95ef-6e372e742a24	c1	AG-MG-5414-7in1 Gooming Kit Rs.2495/-	Electrical Goods	Pcs.
32ccf09b-5f7b-4994-a8f0-ab3d4d543226	c1	Ag Microwave Popcorn Butter	Food	Pcs.
e28a8171-eb2b-4d68-bdd1-b21aa2446168	c1	Ag Mother Vinegar 500 Ml	Food	Pcs.
5c735256-a06d-4a80-9f0e-5acbe224ebba	c1	AG MT-5001 Beard Trimmer Mrp..1495/-	Electrical Goods	Pcs.
41e990e3-37df-49be-86fd-15523a42fab8	c1	AG-MT-5014-Beard Trimar Perfact Style Rs.1295/-	Electrical Goods	Pcs.
f2fb11a4-abde-4207-a43e-68a01ddcd114	c1	AG-MT-6014-Beard Trimmer Quick Style Rs.1395/-	Electrical Goods	Pcs.
0f73d3d6-5e12-48cc-a87f-7658bada0d8b	c1	AG Nail Clipper	Cosmatics	Pcs.
23ab3c53-b3bc-465b-b524-286723b25832	c1	AG NAIL CLIPPER SINGLE PACK Mrp.59	Cosmatics	Pcs.
1fd7030d-6d67-4f54-8653-bac6eeedb99f	c1	Agnesi Butterfly	Food	Pcs.
0ed2e93b-59ae-496e-a253-bd1e3838cb31	c1	Agnesi Cous Cous 500 Gm (12%)	Food	Pcs.
a0310c4a-10b5-4b86-90b6-3db1ee4830dc	c1	Agnesi Farfalle Pasta 500 Gm	Food	Pcs.
b59f8d6e-7cf3-4eb2-b25f-5d223ebecf10	c1	Agnesi Farfele 500g.	Food	Pcs.
4ab5d482-8fbf-43b2-b053-711f354cce03	c1	AGNESI FUSSALI	Food	Pcs.
202d2f6b-fcbb-4d20-a70f-18a8a7b5f394	c1	Agnesi Lasagne Pasta 500 Gm	Food	Pcs.
7ed2b521-cab3-43ff-ad1a-50347a0f0a2b	c1	AGNESI LINGUINI PASTA	Food	Pcs.
d291a46b-0a6b-4cdf-937c-672a856bb345	c1	AGNESI MACRONI PASTA	Food	Pcs.
7276b073-c965-4409-89af-f4426d9045ab	c1	Agnesi Pasta Chiferi 050	Food	Pcs.
336c3165-c8d5-4d39-8fd1-bf2dac371b68	c1	Agnesi Pasta Chiferi 500 Gm	Food	Pcs.
a3cff2e3-7688-4e8f-b66e-3fcf057d2ba5	c1	Agnesi Pasta Fussilli 078	Food	Pcs.
a2f7793e-f462-4b3c-b364-00a413185513	c1	Agnesi Pasta Pennee 019	Food	Pcs.
7d1d476d-6c06-4c67-bb59-e90f179ff3f9	c1	Agnesi Spaghetti 500g	Food	Pcs.
7c3e6cab-af3b-4ed9-b7c4-b300f81f91f6	c1	Agnesi Tagliatelle Pasta 500gm	Food	Pcs.
3a9e926c-20aa-4bc5-b1cc-d04ca456f57c	c1	Agnesi Tricolor Pasta 500gm	Food	Pcs.
2492c2ab-8ec1-4227-8b88-6a633f5fc17a	c1	AG Pancake Syrup 355 Ml Ag	Food	Pcs.
750d0925-66ef-4c0a-a1b9-9c82fac40bf1	c1	Ag Pancake Syrup 710 Gm (IMP)	Food	Pcs.
210976d4-7e71-41a5-875c-3e05130cacef	c1	AG Pancake Syrup 710ml. 24oz	Food	Pcs.
c1c1dd94-8e2f-4050-8e2b-ab94797cc559	c1	AG Pasta Mushroom Sauce 397 Gm	Food	Pcs.
cfe31adc-60a2-472c-81b6-9bd7f90ba57c	c1	Ag Pasta Sauce Traditional 397 Gm	Food	Pcs.
79b341d1-5a35-4325-a5fe-b0f05a63082c	c1	Ag Pizza Sauce 397 Gm	Food	Pcs.
29fa50e0-1c4d-484d-a751-3917a073a3e8	c1	AG-PT-1005-All Groom Trimmer Rs.750/-	Electrical Goods	Pcs.
ce40e16a-1267-4392-945d-e7fb8bf7df45	c1	AG-PT-2005-Easy Clean Female Trimmer Rs.550/-	Electrical Goods	Pcs.
cd57c9ac-692c-4a73-8bb8-fa21c685dc60	c1	Ag Royal Flat Hairbrush Mrp.199	Cosmatics	Pcs.
6f473063-8742-4ca8-9fe8-30943022fbe0	c1	Ag Royal Paddle Hairbrush Mrp.249	Cosmatics	Pcs.
ce4900a3-086e-45df-9085-1fbe7c76a791	c1	Ag Royal Round Hairbrush Mrp.199	Cosmatics	Pcs.
1c7baa08-4376-4f84-8bf6-90ee0c56970c	c1	AG  Royal Vaccume Flask 1000ml (Mrp.925)	Electrical Goods	Pcs.
2314ebd1-4387-4000-af3f-2521bd796a2d	c1	AG  Royal Vaccume Flask-500ml.	Electrical Goods	Pcs.
2cb974d8-5173-448c-9ef8-eaf96f969990	c1	Ag Royal Vaccum Flask 500ml Mrp.625	Electrical Goods	Pcs.
28274c7a-a2a5-43ef-a47d-cefd566e9e8a	c1	AG SAUCE (ANGUSTRA)	Drinks	Pcs.
235676be-9f42-470b-8708-489e2c53a6ae	c1	Ag Sauce Angustra Orange Bitter	Drinks	Pcs.
b221a106-1125-4f1a-aa7b-633ba3213999	c1	Ag Style Essential Mrp.595 (Blue)	Cosmatics	Pcs.
256a2515-696e-4b75-83b3-3987752b91ce	c1	Ag Sweet Paprika Seasoning 160 Z (12%)	Food	Pcs.
8f310a8c-4d93-47b9-a954-0e4a03834633	c1	AG SYRUP (ANGUSTURA BITTER)	Food	Pcs.
99683167-2485-42c1-8f59-9cee0069f769	c1	AG U.S Mustard	Food	btl.
c6af2204-9359-4bac-95bf-ddfd42010723	c1	AG U.S. Mustard Clearb340gm.	Food	Pcs.
e76a2887-101a-45f2-b072-69c9f3d4befb	c1	Ag US Mustard (Imp)	Food	Pcs.
f319db45-518f-4465-8ec8-d9b22eed70d5	c1	AG.U.S. Mustard(Squeeze)454gm.	Food	Pcs.
02c3ca60-8eb6-4891-8361-b7f5aec936a3	c1	AG U.S.Musterd (Squeeze) 397gm	Food	Pcs.
7b15eb8a-f100-460b-bc21-d56ae951840f	c1	Ag U.S. Peanut Butter	Food	Pcs.
24815401-817b-4cc2-9cb9-da38d633bc5d	c1	AG-WD-651-Waterproof Shaver Rs.1995/-	Electrical Goods	Pcs.
ef122595-31ab-43a5-8fc4-776bae457f77	c1	Ag Wooden Flat Hairbrush Mrp.199	Cosmatics	Pcs.
7ee62648-cd04-4816-a42b-17bc0a44061f	c1	AG Worcestershire Sauce 296ml (LP)	Food	Pcs.
c0c54482-10be-4661-bde9-18e5b0d11b86	c1	Ag Worcherstire Sauce	Food	Pcs.
8dbd1785-1dab-4e8d-afe6-e08e1d6158c7	c1	AG YELLOW MUSTARD 227G	Food	Pcs.
adb83c8a-eb0d-4a57-b3b9-2aacc16cd3ca	c1	Ag Yellow Mustard 227gm	Food	Pcs.
8a76e5ae-4fc8-4523-9e74-2d50e6e34723	c1	Ag Yellow Mustard 255gm	Food	Pcs.
295e3d2b-4f5c-4351-8e8a-d8422a6c35ce	c1	AG YELLOW MUSTARD SQUEEZE 12%	Food	Pcs.
32d3f775-f88d-456f-99b1-a36bee1b9e0e	c1	Al Barakah Date Syrup 400gm	Food	Pcs.
240f028b-bb9f-4047-8cab-7f679849e083	c1	Al Bayan Tahina 400 Gm	Food	Pcs.
27903b00-a292-4f8d-b1f5-74bbf1ed6c1e	c1	AL BAYAN TAHINA 500GM	Food	Pcs.
47c0eafb-7b44-4db6-afda-84077e99b91d	c1	All Time Hakka Fresh Noodles (Sewai) 900 Gm	Food	Pcs.
6685d59d-52c5-42fa-9228-7ce57dad1269	c1	All Time White VINEGER 600ML.	Food	Pcs.
d88d89d3-2cd5-44f4-829a-5a697c55f59d	c1	Almond Gajak Patti	GURU FOOD	Pcs.
88566e34-15dc-4f47-aa6a-5a64c201c4a2	c1	Almond Gajak Patti 300g	GURU FOOD	Pcs.
252fe9ab-bae7-4a39-9e32-bb681fc38211	c1	Almond Milk Orignal 1 Lt.	Drinks	Pcs.
3df92cac-1f21-48b2-b338-6ecf018863e5	c1	Almond Milk Unsweetend 1 Lt.	Drinks	Pcs.
af7a229e-0fb6-4ead-a233-dd49c6c3439b	c1	Almond Oil	Food	Pcs.
14011707-1a10-49d3-9500-1670568b0bb4	c1	ALNOOR MOUTARDE D IJON MUSTARS 400G	Food	Pcs.
aff9a496-388f-4f1b-8ded-d3337284a196	c1	Aloe Vera Juice 500ml	Drinks	Pcs.
f67c08c9-43fc-4d00-b26f-aa336020d217	c1	Al Sayyadi Tahina 650 Gm (Imp)	Food	Pcs.
6d232db4-db9b-43db-96a6-ddadfcfbe959	c1	Ameera Tahina 400 Gm	Food	Pcs.
6088b76e-0038-43e8-8280-ac198590f3be	c1	American Delight Coconut Water with Pulp 300ml.	BASIL DRINK	Pcs.
76504969-e0ef-4c17-a3b3-f431d9615c4f	c1	AMERICAN GARDEN APPLE CIDER VINEGAR (IMP)	Drinks	Pcs.
5d420aa9-e101-47b1-8097-5c6a56e360fb	c1	AMERICAN NATURAL BBQ SAUCE	Food	Pcs.
c2f8d9a3-1d23-4467-a5d4-45690f71e712	c1	AMERICAN NATURAL MUSTARD SAUCE	Food	Pcs.
ae281d73-cf9d-4a12-8057-2b822f20ca51	c1	AMERICAN NATURAL PANCAKE SYRUP	Drinks	Pcs.
94979c2b-3a88-491b-966d-5e13e57c1441	c1	Amla 50-50 (ECO) 500gm	Food	Pcs.
0eedcc14-c3ad-48d3-b93e-659be11531ca	c1	Amla Anardana 250 Gm	Food	Pcs.
aba12fe5-e03d-42da-8412-2b4fe3bbb194	c1	Amla Annar Dana-100g	Food	Pcs.
a82517ef-2673-4594-8bc7-87810bf9968a	c1	Amla Barfi 200 Gm	Food	Pcs.
986a4603-83e0-4a04-9baa-2fd0fd60e254	c1	Amla Barfi 200gm (LCS)	Food	Pcs.
da99c865-df84-4af8-8722-c4a13829f8a0	c1	Amla Barfi-250g	Food	Pcs.
920ebd03-2145-4f4f-9a2b-b5fcb6af22d8	c1	Amla Barfi-500g	Food	Pcs.
47c107fb-dfcc-42fd-b961-069f05e88c8f	c1	Amla Barfi Classic-500g	Food	Pcs.
7cacece0-3ebd-4aa6-bf08-48869ce3b716	c1	Amla Barfi Plain-500g	Food	Pcs.
08d0a8e0-c086-440f-a076-065456fb94ad	c1	Amla Barfi (S)	Food	Pcs.
acf0fd0e-d5e0-4098-9bd0-ea11de3f4ae1	c1	Amla Barfi (S-4)	Food	Pcs.
f0d33786-f53c-4c09-ba59-d56307d047bb	c1	Amla Candy-100g	Food	Pcs.
6788696e-6c75-4373-a162-d6d48edba167	c1	Amla Candy 180gm	Food	Pcs.
edcea595-8ad5-4416-93f4-6a3f79e389e2	c1	Amla Candy 250gm	Food	Pcs.
c019ce5d-3d56-42c6-9438-2ba25241acf2	c1	Amla Candy 400gm	Indica Amla	Pcs.
8553e584-44f3-40c5-90db-b360965a340e	c1	Amla Candy-500g	Food	Pcs.
414c4196-1bb1-4f0e-a48f-6812d3d05f25	c1	Amla Candy (ECO) 500gm	Food	Pcs.
160935c9-c325-4373-88a8-98beef27a735	c1	Amla Chatney 350gm	Food	Pcs.
f0a8421d-bd82-48c3-a92b-fbd2d85448bc	c1	AMLA CHINI CUM .400GM.	Indica Amla	Pcs.
be4aad22-d46c-4308-a133-3b3cbd60050b	c1	AMLA Chini Cum Seg 180 Gm	Food	Pcs.
2c1266c7-742c-4a05-a862-efdf76d7db94	c1	Amla Churan 100gm	Food	Pcs.
072bc7c6-57ec-41fa-af28-d87a4a8c3eb1	c1	Amla Churan 180gm	Food	Pcs.
574813d7-d857-4b86-9755-9c2f75361e7c	c1	AMLA DRY 400g	Indica Amla	Pcs.
c4e8059e-4723-4e1b-a2e0-c997bab79e16	c1	AMLA DRY 750g	Indica Amla	Pcs.
b55d5f53-c5ea-4f04-9172-0433d1285387	c1	Amla Honey Murabba -1k	Food	Pcs.
f07d3691-5e39-45e7-9758-16d1309d4344	c1	Amla Juice 500ml	Food	Pcs.
430c31d9-cb28-4b5d-831b-7963929b35a9	c1	AMLA JUICE-800ML.	JUICE	Pcs.
727b3b67-8acf-42e2-918e-99b9c8976885	c1	Amla Khatta Meetha-100g	Food	Pcs.
942b571e-2b1b-4c5a-9377-e7ae07102cf9	c1	Amla Khatta Meetha 180gm	Food	Pcs.
278c7629-a73f-4084-901a-97d7da1ec49e	c1	Amla Khatta Meetha 250 Gm	Food	Pcs.
840ebd4e-0609-4d98-a402-792f0edf4bd1	c1	Amla Khatta Meetha 400gm	Indica Amla	Pcs.
515214ac-71eb-4654-be2b-b3e72feac8cb	c1	Amla Khatta Meetha-500g	Food	Pcs.
c6862284-dc17-4334-b687-28d627bca3a7	c1	Amla Khatta Meetha (ECO) 500gm	Food	Pcs.
f023e1d7-69a6-483a-9cb2-61b2b0311ea1	c1	Amla Laddoo 200 Gm	Food	Pcs.
70c2b3b4-70e7-4621-8cd1-899e896b3e25	c1	Amla Laddoo (Single)	Food	Pcs.
b7a4c378-005e-4b36-8bf0-67e5f2eddc8c	c1	Amla Laddu 250gm 5%	Food	Pcs.
aac03b4a-f11a-48d3-b45b-2349b6f18be5	c1	Amla Laddu-500g	Food	Pcs.
491e8c8a-3748-42a8-b910-e8bad5cb07f2	c1	Amla Laddu 500gm	Food	Pcs.
b234cb9b-f3aa-4553-a6e6-b642db1d5ef1	c1	Amla Laddu (S-4)	Food	Pcs.
e6fe2030-e184-49b9-b4d8-ca68a23e6f2e	c1	AMLA LADOO 250G	Food	Pcs.
5bc7a7fb-262c-49d4-a1be-b61229c58049	c1	Amla Lemon Candy 180gm	Food	Pcs.
07778930-ed62-4f27-87a1-54b85b906aa0	c1	Amla Lemon Candy 250 Gm	Food	Pcs.
995620dd-4b28-4ac5-b34e-ace504207c82	c1	AMLA LEMON CANDY (ECO) 500GM	Food	Pcs.
21ed4ba1-52f1-47fd-a9aa-497931d581c1	c1	Amla Mango Bar 200gm Mrp.130	Food	Pcs.
d4635f5f-1a94-48ab-bf82-bd76779cc64d	c1	Amla Mango Bar (S)	Food	Pcs.
ff915e67-dea4-492b-a2d6-a563b8f4edcc	c1	Amla Mixed Fruit Candy (ECO) 500gm	Food	Pcs.
20ce73cf-5aca-4f2e-8c53-2dbd52035f83	c1	Amla Mouth Freshner 180gm	Food	Pcs.
2deccd90-3b3a-4795-a06d-321e90c58a21	c1	Amla Murabba -1k	Food	Pcs.
384a5f9f-8bfe-4885-add9-bebf04353038	c1	AMLA MURABBA-2.5K	Indica Amla	Pcs.
d5f39adc-d262-4cba-af55-122c99e376d0	c1	Amla Murabba 2.5kg	Indica Amla	Pcs.
c501d943-74c5-4468-a614-e168ec369211	c1	Amla Murabba 400gm	Food	Pcs.
7e7103b2-0204-4134-9550-82369e6d317d	c1	Amla Murabba-5kg	Indica Amla	Pcs.
96311578-3b3d-4e65-a7ad-a7cb5da5c6dd	c1	Amla Murabba 900gm	Indica Amla	Pcs.
0c7e7faf-a951-42df-920d-dee31629d733	c1	Amla Murabba Dry (ECO) 500gm	Food	Pcs.
16484062-0958-4225-b3e7-bfd9fcc43e6e	c1	Amla Murabba Dry Seg.-100g	Food	Pcs.
23316cd3-f4fc-4ebc-83ac-e1e66d40a799	c1	Amla Murabba Dry Seg 180gm	Food	Pcs.
6ebe44ac-9272-40d9-9dbb-48a3aa109756	c1	Amla Murabba Dry Seg 400gm	Indica Amla	Pcs.
7ab67b01-a7b2-4880-95ea-f33c53eda0e0	c1	Amla Murabba Dry Seg.-500g	Food	Pcs.
32663db4-85a4-4699-b210-2da3dd5685ab	c1	Amla Murabba Honey 250gm	Food	Pcs.
16a64e6c-3f9d-44f2-af63-44b9fcf8acb6	c1	Amla Murabba (Honey) -400g	Indica Amla	Pcs.
2f37afd2-6f0c-4674-b385-1b19bb7a2977	c1	Amla Murabba Seg 2.5kg	Indica Amla	Pcs.
c4082b3a-89d5-4616-b155-ee4660c5318b	c1	Amla Murabba Seg 900gm	Indica Amla	Pcs.
9d46680f-b04c-4ba4-8c89-1610a2a822df	c1	Amla  Murabba SEGMENT-1KG	Food	Pcs.
034dbbe1-d142-4561-bf84-bd603a1647e6	c1	Amla Murabba Segment 400gm	Indica Amla	Pcs.
f2f1592d-f312-4adc-bc94-19c5e2368c32	c1	Amla Murabba Segments 2.5kg	Food	Pcs.
1893cc5a-3143-4d1b-9426-41150220ce98	c1	Amla Murabba Segments 5kg	Food	Pcs.
e0c2929a-d04b-4da5-9acc-a97b43d08754	c1	Amla Powder 100gm	Food	Pcs.
8811adcd-a985-40cf-911d-f0b0258da449	c1	Amla Powder 180gm	Food	Pcs.
d7719f57-9506-46f2-bdd9-c014cf2cbe4a	c1	Amla Powder 250 Gm	Food	Pcs.
01c97767-3440-4031-b897-0f313417fca4	c1	Amla Supari 100gm	Food	Pcs.
8884482d-d8b9-4a7a-a1a0-d86e65a5c930	c1	Amla Supari 150gm	Food	Pcs.
eef69f22-5971-44c5-9b5d-286beaa5c81e	c1	Amul Frech Fries 6mm	&#4; Primary	PKT
b8024443-0c80-416b-bf66-f660913c3a4f	c1	AMUL FRENCH FRIES 6 MM (2.5 KG)	&#4; Primary	Pcs.
c15b4069-74c4-4532-8890-3aa3aa868c69	c1	AMUL FRENCH FRIES 9MM	Food	Pcs.
4bd54ae1-3776-4926-990e-98bb69256c7e	c1	Anandam Dice Mozerella 200gm	Food	Pcs.
f1f0d7dc-ec9c-4a8c-8210-5e54ab5fa52e	c1	Ananddam Pizza Diced 1kg	Food	Pcs.
06203ae9-b113-4ea8-b409-30813fd1ab80	c1	Andalini Pasta Lasagne 500 Gm	Food	Pcs.
2d448a34-9230-4332-a3c2-ec549fbf5f44	c1	Angostra Yellow Bitter	Food	Pcs.
dd33b292-4280-4825-81da-cacdafafe0d7	c1	ANGOSTURA BITTER	Food	Pcs.
cb0281b3-ceaf-4b04-a7e1-310cd8173dd1	c1	Angostura Bitter Orange	Food	Pcs.
7876222c-3f85-4ce2-a253-a4e3cf9045f1	c1	ANTAT 230G.	Chocolate	Pcs.
7bdf8036-76e5-410e-879c-e92c9e47004c	c1	ANTAT 350G.	Chocolate	Pcs.
8e14d4b7-d15f-40ed-80c1-b483bc34838b	c1	ANTAT 500G.	Chocolate	Pcs.
3129a8a3-1010-4847-8d44-cc6d97f3aa39	c1	ANTICO CASALE POMODORI   SUNDRIED TOMATOES 285G	Food	Pcs.
29972d05-daa1-41bb-87e7-0a2227a0b794	c1	ANTONIO,S MOZ+CHEDDAR CHEESE 1 KG	Food	Pcs.
93e910b3-019e-4615-a071-abb4725a2469	c1	APPLE CIDER A G	Drinks	Pcs.
0c08a0de-5756-4b92-888d-a4faa4c2e9b4	c1	Apple Cider Vinegar 500ml.(Varvello)	Drinks	Pcs.
ce307194-5430-432b-9fcb-81cf727a1c4e	c1	Apple Cider Vineger 500 Ml.	Drinks	Pcs.
cd4f0708-4bf0-46bf-a4b9-2f56b7896a25	c1	Aqua Montana Slim-Exotic 500ml(Pet)	Drinks	Pcs.
3e441055-738b-40f8-97a6-5b3592e1988b	c1	Aqua Montana Slim-Orenge 500ml(Pet)	Drinks	Pcs.
a5b20601-1ecc-4765-aba2-e5059687381d	c1	Aqua Montana Slim Zitro9ne 330ml.(Can)	Drinks	Pcs.
27b4a24c-c450-4d4b-a1bd-25d8a2cceb99	c1	Aqua Montana Slim-Zitrone 500ml(Pet)	Drinks	Pcs.
2d489c9e-63a2-4165-8e24-130a340153b7	c1	Aqua Slim Orenge330ml.(Can)	Drinks	Pcs.
1ce2cfae-1140-411f-a62e-4ebb9276a368	c1	Arancia Origano Dried Herbs 500g	Food	Pcs.
f08ac47e-3b99-430a-8971-b4f917e7c669	c1	Arbella Pasta 500gm	Food	Pcs.
7f7fac64-0f9b-4476-9511-110dd4fc58c4	c1	Arbella Speghetti 500gm&apos;	Food	Pcs.
55c27c13-c69e-4648-b6ac-7b5849987ea1	c1	ARB O RICe	RICE	kg.
52762148-ba77-43dd-86a7-70a82d9cf7bd	c1	Arborio Rice 1kg. (5%)	Food	Pcs.
b26999bc-b755-45e9-95ea-2b033ce8cec4	c1	AREATED WATER 750ML.	Drinks	btl.
5e59fa94-d03e-4dd6-b91b-4a4233156297	c1	Arias Body Spray Blissful	Cosmatics	Pcs.
42757481-93aa-48d6-be4a-2a76231e9012	c1	Arias Body Spray Flirty	Cosmatics	Pcs.
2c22e993-2f99-4fa1-81dc-0899294e101c	c1	Armanti Dijon Mustard 370gm	Food	Pcs.
1fead503-9ff5-4f60-854b-d9849d9ade04	c1	ARO Black Fungus 500 Gm	Food	Pcs.
536754ac-37f6-4d4a-b1da-23743f48de49	c1	ARO GULTINOUS RICE 5KG	RICE	Pcs.
690fa570-2fc9-472b-8330-7f2d1c9904b5	c1	Aroy Sure Seasoning Powder 800 Gm	Food	Pcs.
8ff03957-b7aa-465f-a0c9-d744bd6f6473	c1	Arrighi Farfalle 500g	Food	Pcs.
504de16d-800b-4029-9c11-b422c5e57717	c1	Arrighi Fusilli Tricolour Pasta 500gm	Food	Pcs.
b401568a-fce1-4fc5-abb5-bdf1c64ac87a	c1	ARRIGHI LASAGNE SEMOLINA 500G	Food	Pcs.
8de358f9-6020-4c44-9130-ddc4776c2a32	c1	Arrighi Spaghetti Pasta 500gm	Food	Pcs.
19eb60e2-dfbf-4f12-863a-673db5f65563	c1	Arrighi Tagilatelle 500g	Food	Pcs.
4bb78b6d-bdd3-44f1-9cf6-db2c2eac3448	c1	Artichoke Hearts 500 Gm	Food	Pcs.
a84b5b1b-744c-455a-b13a-759c4b20dcf9	c1	ARTICHOKE HEARTS COHEVI 1/2 KG	Food	Pcs.
bfea5c9f-149f-42b5-ab8a-4dd9095ca9ca	c1	Assassin Engery Drink 330 Ml	Energy Drink	CAN
adb29be7-afed-4726-a5c7-9c9c161fd4d6	c1	Assorted Candy	Food	Pcs.
dbe22776-2cf5-4360-9b4c-da17a513f0f5	c1	ASSORTED CHO MIX	Chocolate	Pcs.
1d3e094d-2eb0-4fa9-9f96-eb11b9af0b4b	c1	ASSORTED DRINK 250 ML (No Sugar Added)	Drinks	Pcs.
adcee369-8989-48d1-abd8-c0fc41f8603f	c1	Assorted Drinks  (18%)	Drinks	Pcs.
b27c92fb-202f-4b92-ba4c-9a2a0a98e5a8	c1	Assorted Drinks 320ml (No Sugar Added)	Drinks	Pcs.
7dc09fe0-1925-4a6b-818a-5c33a21be59d	c1	Assorted Drinks 330 Ml (18%)	Drinks	Pcs.
af902eae-b9e0-4088-99b4-b3ec8230aee4	c1	Assorted Drinks 330ml (No Sugar Added)	Drinks	Pcs.
24deecea-6c75-4152-97b9-c64ebb048ea9	c1	Assorted Soft Drink	Drinks	Pcs.
a3c783eb-d3d8-42d9-9e17-2ce89a361dcf	c1	Austin Peeled Tomato 2.5 Kg Mrp.380	Food	Pcs.
154dca15-55a7-458b-93d7-2ef340438824	c1	AV Manual Breast Pump PP&amp; Storage Cups Rs 2795/-	Electrical Goods	Pcs.
5502c623-a180-4a2d-aaea-1506e728595e	c1	AV MANUAL BRIST PUMP PP&amp; STOREGE CUPS SCF MRP 2095	Electrical Goods	Pcs.
77c6112b-54e9-4711-a4c5-9c14e74aeb45	c1	Baby Wips	Sanatry Napkin	Pcs.
cfbe263a-cf83-40e2-9565-2ebe496120c3	c1	Bachun Seasme Oil	Food	Pcs.
63225b29-9459-4aaf-9eb5-0e4a533edaf4	c1	Badam Drink	Drinks	BOX
630de409-5448-4e10-98a1-dab1fcee6c4c	c1	Bael Bar-500g	Food	Pcs.
6d0b58a7-715e-4f3f-856d-afcb04cb8b78	c1	Bael Barfi-250g	Food	Pcs.
eeabbde6-be14-41ec-8299-840ab2cd3e0b	c1	Bael Barfi (S)	Food	Pcs.
b782433f-da70-4033-8753-454517fde98b	c1	Bael Barfi (S-4)	Food	Pcs.
7af07df3-a003-490d-a570-d9987a55deee	c1	Bael Candy 100g	Food	Pcs.
93bb1120-bcad-4859-b074-16d2aef42dab	c1	Bael Candy 250gm	Food	Pcs.
0c07f45d-68e7-486c-a78a-13d9601c4792	c1	Bael Candy-400g	Indica Amla	Pcs.
6ce2efff-8ea1-4bc0-86da-54c5bb4b2755	c1	Bael Candy (ECO) 500gm	Food	Pcs.
4bfc5058-31a9-45d3-9b81-abfa301b1f8e	c1	Bael Murabba 1kg	Food	Pcs.
d2a86ce9-671b-486a-9c47-5c17b3a2139a	c1	Bael Murabba 400gm	Food	Pcs.
1b1730c8-f813-4e66-9b39-f9d67950906f	c1	Bael Murabba 500gm	Food	Pcs.
f842d95d-0508-44d1-a25a-084b0d4dc11d	c1	Baikers Pride 400g.Butter Cookies	Biscuts	Pcs.
fd8c645f-3eb6-4192-a90d-0560349f3ef3	c1	Baikers Pride 400g.Danish Cookies	Biscuts	Pcs.
cdce20d6-dbe4-4d6e-98fd-37c6748983bc	c1	Baked Bhujiya (Mint) Jar	GURU FOOD	Pcs.
3f8b7c70-63de-4fc8-9608-ccc395d07e69	c1	Baked Bhujiya (Peri-Peri)	GURU FOOD	Pcs.
0d8c52cf-6478-4e5c-a7ed-3d90bc54d08c	c1	Baked Makhana Crisps	GURU FOOD	Pcs.
6a39453f-ba9d-41b5-80c6-614aa094381d	c1	Baked Ragi Crisps Jar	GURU FOOD	Pcs.
f2f8d217-f06e-4aeb-a2a2-d3edd28f711e	c1	Bakenxt All Star Eggless Chocolava Premix 250 Gm	Food	Pcs.
0b664248-2d59-4c29-ac69-7fae21bcb836	c1	Bakenxt All Star Eggless Vanilla Premix 250 Gm	Food	Pcs.
56eec738-9d6f-4b52-b60f-058b910cf437	c1	Bakenxt Eggless All Purpose Vanilla Premix 25 Kg	Food	BAG
e75236cc-af98-47bd-8313-f7472539db6e	c1	Bakenxt Eggless Brownie Premix 250 Gm	Food	Pcs.
aefe8ce4-b6f4-453e-889e-651976dc27bf	c1	Bakenxt Eggless Chocolate Cake Premix 250 Gm	Food	Pcs.
d23fdbb0-d917-4695-b54a-5111b7d26c36	c1	Balsamic Vinegar 500 G	Drinks	Pcs.
e4289ebf-1f84-42c2-9e58-819cbfb3af66	c1	BALSAMIC VINEGAR 500ML ITALIAN GARDEN	Food	btl.
9b5147bf-a83f-4bab-99fd-7b2882e1da36	c1	Bamboo Shoot 0%	Food	Pcs.
906a4d72-f042-4b90-92e8-37dafa185ea0	c1	Bamboo Shoot in Brine 850 Gm	Food	Pcs.
c6536066-41c0-4a91-a574-8d50db4bc8b4	c1	Banana Chips Jar	GURU FOOD	Pcs.
b0cdee0f-5370-485b-874c-59a292c8885b	c1	BARBICAN APPLE FLAVOUR 250ML.CAN	Drinks	Pcs.
bba6648b-c5cf-43af-accd-bb4efc7099d3	c1	BARBICAN APPLE FLAVOUR 330ML.	Drinks	btl.
9d454663-e745-4eb5-81b3-24081509014f	c1	BARBICAN LEMON FLAVOUR 330ML.	Drinks	btl.
ca27dc40-19dd-410a-9ae9-d85799c01a00	c1	BARBICAN MALT FLAVOUR330ML.	Drinks	btl.
ecc88885-1602-415e-a26d-fc36774ca349	c1	BARBICAN PEACH FLAVOUR 330ML.	Drinks	btl.
4f65bb0c-162f-49b0-a5d5-fc35b11217f8	c1	BARBICAN PINAPPLE FLAVOUR 330ML.	Drinks	btl.
6b54ab8a-0ddd-4e63-bf08-cfac073f140a	c1	BARBICAN POMEGRANATE FLAVOUR 330ML.	Drinks	btl.
80d2789a-e7c9-44c7-a366-4f8a80af4f12	c1	BARBICAN STRAWBERRY FLAVOUR 250ML. CAN	Drinks	Pcs.
b801675e-e60a-4edf-b5bc-1be0c00d3713	c1	BARBOCAN MALT FLAVOUR 250ML. CAN	Drinks	Pcs.
53cfc2e7-3563-49f6-86ca-6ac3bee52656	c1	Barilla Fettuccine Collezione Pasta 500g	Pasta	Pcs.
6f7baca5-13c4-418f-bdc8-36a0c7a4f9ac	c1	Barilla Lasagne Pasta 500g	Pasta	Pcs.
5f93b6df-ca4c-4e84-af0f-1765935f5421	c1	Barilla Pasta Angel Hair 500gm	Food	Pcs.
896af6d7-7b3e-4d10-bc28-46e72dd6010c	c1	Barilla Pasta Fusili 500g	Food	Pcs.
37f1c0a7-de89-4575-835b-23c0a957b1d5	c1	Barilla Pasta Rigatoni Strip 500gm	Pasta	Pcs.
d7cd9e64-b733-4b34-b20a-30ceeaa91898	c1	Bar Kaccha Mango 12 Gm	Chocolate	Pcs.
54eba1bd-361a-4462-9fc1-35a297b71815	c1	Bar Orange 12 Gm	Chocolate	Pcs.
9a675b53-306c-4373-a41a-d720b8bad634	c1	Bar Pineapple 12 Gm	Chocolate	Pcs.
9e310f44-7aed-4364-9902-fe508b78aee2	c1	Barquillo 20pcs Trat Mix Sample	Barquillo Chocolate	Pcs.
6b460f70-3905-4b57-b6b5-579acf040007	c1	Barquillo Assorted (Box) 108g	Barquillo Chocolate	Pcs.
c69bb326-faba-4145-9c6f-050bf1755a68	c1	Barquillo Assorted (Box) 180g	Barquillo Chocolate	Pcs.
1efe442c-1850-4408-9b28-c02a3144bf83	c1	Barquillo Assorted (Tin) 200g	Barquillo Chocolate	Pcs.
099aef0c-97a9-4573-9414-658f255b2ee8	c1	Barquillo Assorted (Tray) 54g	Barquillo Chocolate	Pcs.
c8fbd7ba-8f31-400f-9c70-4bee631e0838	c1	Barquillo  Cocoamelts Milk Dates 1kg	Barquillo Chocolate	Pcs.
89370eac-1c77-4f36-93ed-779bfcdc77ff	c1	Barquillo Cocoamelts White Chocolate Date 1kg	Barquillo Chocolate	Pcs.
2b61c52d-4380-4412-b041-9ef238e98651	c1	Barquillo Hazelnut (Pouch) 100g	Barquillo Chocolate	Pcs.
87f30a5a-9d3a-4888-8b92-dc0432d457de	c1	Barquillo Hazelnut (Tin) 200g	Barquillo Chocolate	Pcs.
1bca08f2-8fb1-4688-8335-654d1448e996	c1	Barquillo Hezelnut (Pouch) 200g	Barquillo Chocolate	Pcs.
8bd5a926-2a9f-4ae3-83fc-180f71974da1	c1	Barquillo Pistachio (Pouch) 100g	Barquillo Chocolate	Pcs.
0778d07c-0530-4186-a576-991279eabddb	c1	Barquillo Pistachio (Pouch) 200g	Barquillo Chocolate	Pcs.
fea1d264-9e3d-484b-9263-adedb970fc59	c1	Barquillo Pistachio (Tin) 200g	Barquillo Chocolate	Pcs.
e586b702-cb0c-4c20-a2fc-72413f7f4296	c1	Barquillo Red Velvet Cheescake (Pouch) 100g	Barquillo Chocolate	Pcs.
07a21ff9-a1ae-4820-b8bc-b14f8e5252f5	c1	Barquillo Redvelvet Cheescake (Pouch) 200g	Barquillo Chocolate	Pcs.
903981c7-3253-4416-9068-5e4b3507c73d	c1	Barquillo Redvelvet Cheescake (Tin) 200g	Barquillo Chocolate	Pcs.
156bbc9c-20fb-46c1-bf96-d499572916a8	c1	Barquillo Roasted Almond (Pouch)100g	Barquillo Chocolate	Pcs.
8c1df152-8c90-4b80-8449-d0747c711c67	c1	Barquillo Roasted Almond (Pouch) 200g	Barquillo Chocolate	Pcs.
3f503a09-8fec-40b7-9e5a-0a3a1db1fe94	c1	Barquillo Roasted Almond (Tin) 200g	Barquillo Chocolate	Pcs.
1889871e-57f9-462b-8a55-4439609d2a6b	c1	Barrilla Fussili 500gm	Food	Pcs.
ac794ec9-5690-43fa-b50a-4b9f5e92791d	c1	Barrilla Penne Rigegate 500gm.	Food	Pcs.
416f7c5a-34f9-4c83-808f-e8ab5d8ef09b	c1	Bar Strawberry 12 Gm	Chocolate	Pcs.
c6975a70-153c-4dc8-bfe2-871e455afea2	c1	Basil Drink Apple 290ml American Delight	Drinks	Pcs.
4396ab77-b2bd-444a-a7c4-3c2d118495ee	c1	Basil Drink Apple 300ml	Drinks	Pcs.
ececf9fa-90d6-44c9-a5ab-eafad6b3d26c	c1	Basil Drink Apple 300ml American Delight	SHS GLOBAL	Pcs.
2a00429c-a151-4c1a-8914-19a0e586c1f3	c1	Basil Drink Black Grape 290ml American Delight	Drinks	Pcs.
aea2cdee-cdda-4e49-a647-a198747e0e13	c1	Basil Drink Blueberry 300ml/american Delight Mrp.99	BASIL DRINK	Pcs.
3f4c53d6-5595-44ec-9197-7c3ded962487	c1	Basil Drink Coctail 300 Ml American Delight Mrp99	BASIL DRINK	Pcs.
30e303ed-28cd-42f9-bc51-d96b1860ab47	c1	Basil Drink Honey 300ml.	Drinks	btl.
d088367b-c4ab-4bb2-9e16-56b800dd0f78	c1	Basil Drink Kiwi 290 Ml	Drinks	Pcs.
a1323a78-506e-4bf1-9daf-fe459f83d009	c1	Basil Drink Kiwi 300ml American Delight	BASIL DRINK	Pcs.
ad387d62-3451-438c-97f2-dff467a9627f	c1	Basil Drink Lemon Mint 300ml. American Delight	Drinks	Pcs.
28bac94a-6dcb-4a1a-b160-22d5945e42e8	c1	Basil Drink Lychee 300 Ml AmericanDelight Mrp.99	BASIL DRINK	Pcs.
e1c0ab0a-6179-4558-83b7-6e5fcc294ed5	c1	Basil Drink Mango American Delight 300	BASIL DRINK	Pcs.
d82cc99b-b569-4f6c-9d5d-271929506093	c1	Basil Drink Mangosteen 300 Ml	Drinks	Pcs.
22ac58e8-1707-4ab7-8336-2b7e661bf4ea	c1	Basil Drink Melon 300mlk.American Delight	BASIL DRINK	Pcs.
3fabdaa1-ef92-4d9e-abaa-21350c9adb89	c1	Basil Drink Orange 300ml American Delight Mrp.99	BASIL DRINK	Pcs.
27809db2-3f8a-41b7-87a2-0a4d97ec893e	c1	Basil Drink Passion Fruit 300ml American Mrp.99	BASIL DRINK	Pcs.
e060bc5d-ccc2-4020-9a28-839ceba9e2af	c1	Basil Drink Peach 300 Ml	Drinks	Pcs.
73decf70-27b1-4c4c-a331-6a428315813d	c1	Basil Drink Pineapple 300 Ml American Mrp.99	BASIL DRINK	Pcs.
ff1b94ef-3cc1-4209-a2a8-1cb05fda32b3	c1	Basil Drink Pomgranate 300ml. American Mrp.95	BASIL DRINK	Pcs.
4608f4c7-1d47-4bda-9d23-8814166392f7	c1	Basil Drink Red Grape 300 Ml American Delight	BASIL DRINK	Pcs.
f1b00562-b3c1-4c2a-a94d-469acf242c55	c1	Basil Drink  Strawberry 300ml. American Delight	BASIL DRINK	Pcs.
a7323398-7e4d-4705-ab5d-f66605a34025	c1	Basil Drink Watermelon 300 Ml American Mrp.99/-	BASIL DRINK	Pcs.
65064fa4-b044-4b63-b1fd-04769f6359f3	c1	Basil Drink White Grape 290ml American Delight	Drinks	Pcs.
c9f8df35-3388-4a3f-bff8-97a978782442	c1	Basil Drink White Grape 300ml American Delight	BASIL DRINK	Pcs.
443a9f6c-9220-47df-9685-4704c9775b70	c1	BASIL PESTO 180GM (ACE)	Food	Pcs.
be5a1389-09a2-43f1-8670-60583f3534c4	c1	BASIL SEED DRINK TANDO 290ML	Drinks	Pcs.
a497eee2-39a8-451e-b047-cfbee1a19554	c1	BASIRAN SMOKED GOUDA CHILLI CHEESE 200 GM	Food	Pcs.
cba8bccf-fe2d-4588-9b55-c48dfb8be56a	c1	Basso Olive Oil E.V.500 Ml (5%)	Food	Pcs.
3b59676d-0c24-4247-81d4-42f155c282f7	c1	Basso Olive Oil Pom.5ltr.	Oil	Pcs.
893c7b3b-597e-48dc-b543-f1b89fe98a21	c1	Basso Pomace 1 Ltr	Oil	Pcs.
14de7284-0dfd-4b66-8b9b-8733851dd372	c1	Bean Thread Noodles 500gm	Food	Pcs.
b4270095-7be5-4858-af05-57ceab69e5e2	c1	BEETEOOT MUNCHIES JAR	Food	jar
bdf61c15-5022-4b67-ba8b-3c6213330e77	c1	BEETROOT CHEETOS JAR	GURU FOOD	Pcs.
a34cc996-9a92-467f-bd0a-3b6592ec18b0	c1	BEETROOT CHEETOS (MAXICAN CHILLI) JAR	Food	Pcs.
eeb19582-6481-4e3f-961e-e7dca9169306	c1	BEETROOT CHEETOS (PERI PERI) JAR	Food	Pcs.
5ae632b3-eef7-4588-bffb-9be29c4b954a	c1	BEETROOT CHIPS JAR	GURU FOOD	jar
f13f87bc-1b06-41f4-ac35-61341b06a1e5	c1	BEETROOT LACHHA JAR	Food	jar
f5190725-c7fd-411e-9857-f455c2b89395	c1	BEETROOT LOOP JAR	GURU FOOD	Pcs.
3ff0a170-2097-48b8-9b4c-805261fec86b	c1	BEETROOT MIXTURE JAR	GURU FOOD	jar
946c234e-9163-4c50-a4d8-2ee90cf77250	c1	BEETROOT STICK JAR	Namkeen	Pcs.
3c6b599c-9aa6-4b44-939e-85a219e7fc5c	c1	Beetroot Tadka	Namkeen	Pcs.
edf26ac2-5740-4c07-882e-3e39b53d8cc6	c1	BELGIAM CHOCOLATE FRAPPE MIX	Food	Pcs.
f850bf4b-d8a1-4dda-9dbf-f95278176ff9	c1	Belgium Waffle Premix 0414	Food	kg.
7ff06739-7537-41e9-9a77-174bf7044a28	c1	Bergen Brownie Cookies 126gm	Biscuts	Pcs.
c54a1d69-98de-4d12-a4ec-8b938aa88eea	c1	Bergen Brownie with Hazelnut Cookies 126gm	Biscuts	Pcs.
52039936-7b8c-498d-8f3c-43d8b026820e	c1	Bergen Choco Chip with Smile Cookies 135gm	Biscuts	Pcs.
e9bd4493-4575-443f-84e5-25c6340a5a0c	c1	Bergen Choco Striped Peanut Cookies 150gm	Biscuts	Pcs.
2cab1a2d-b3cd-4dc1-a5a4-f1fe7b14b8bc	c1	Bergen No Added Sugar Choco Chip Cookies 135gm	Biscuts	Pcs.
93b16ac9-fa41-43e8-8f5d-b186e1900d45	c1	Berio Olive Oil 200g.	Oil	Pcs.
e275d43b-c628-4dd2-814f-7871ae22ddcc	c1	Berio Oliv Oil 100ml.	Oil	Pcs.
6f692fbb-c68a-42eb-b9de-163dff6be4b1	c1	Berio Oliv Oil 1ltr.+500ml.	Oil	Pcs.
ede1e494-75ef-4c36-b27d-b03f0c4e7900	c1	Berio Oliv Oil 1ltr E.V.	Oil	Pcs.
13e0a6d5-4cdb-4707-abe0-d36ba4d0676a	c1	Berio Oliv Oil 1ltr.Pure	Oil	Pcs.
da6750d0-0e0e-41e8-a931-e76ae6e9c09e	c1	Berio Oliv Oil 500ml.	Oil	Pcs.
649e4f17-ad5e-4766-b55a-56f518d7ca16	c1	Berio Oliv Oil 500ml.+200ml.	Oil	Pcs.
d4c8a5a4-a98b-4b37-959a-ffce35789960	c1	Bernique Checkers 500g.Mini	Chocolate	Pcs.
9e48526f-5a4b-4525-9424-f13ba07fd582	c1	Bernique Chlt.105g.	Chocolate	Pcs.
913932da-2000-4e2c-ba90-1b2ed3674d4d	c1	Bernique Chlt.200g.Tin	Chocolate	Pcs.
caabec06-2cce-4fb2-b764-1c58e8c86a01	c1	Bernique Sugarfree 100g.	Chocolate	Pcs.
2f219e5a-9122-4a05-9a8f-347742ba8435	c1	Betty Crocker Pancake Mix 1 Kg	Food	Pcs.
f7587160-3365-4df7-85c5-efb7724ea0fd	c1	Betty Crocker Pancake Mix 500 Gm	Food	Pcs.
830614fa-88b4-4cdc-b1f5-ac91db2839bd	c1	Bhlsn Hit Cocoa 150g.	Biscuts	Pcs.
e251c03d-7594-4860-b575-f2b0dc24f38b	c1	Bhlsn Hit Vanila 150g	Biscuts	Pcs.
a5e35c87-e58c-4fd5-9b39-00f2b8b58310	c1	Bhlsn Lebriz Butter 200g.	Biscuts	Pcs.
35bf6be1-df9e-4088-9f36-a02b0a451a66	c1	Big Babool Chewing Gum	Food	Pcs.
45680b10-5fd0-4d86-b491-af4969a52938	c1	Biryani Brown Rice Chips	GURU FOOD	Pcs.
9c89678c-0323-40cc-a33e-c02081badc35	c1	Bisct.Mcvts Fruit Short Cake200g.	Biscuts	Pcs.
686e2b6e-b77e-4934-8019-272387e3ea7b	c1	Biscuit	Food	Pcs.
fa2dcbd2-41f7-4a32-b295-7a35fdf8a4e4	c1	Biscuit Case	Food	case
ed67d5cd-02b9-4427-880e-68428527af55	c1	Biscuit Chips Ahoy	Food	Pcs.
50e99a65-7a83-4368-bac3-97a7d6523b5f	c1	Biscuit Chocolate Cream 133 Gm	Food	Pcs.
9c2d5d7c-2fd5-4754-af7c-d8899eae011f	c1	Biscuit Hob Nob 300g.Rs.141/-	Biscuts	Pcs.
7c613df5-3386-4995-a195-71716f39a2c1	c1	BISCUIT LADY FINGER/BONOMI 330GM/400GM	Biscuts	Pcs.
8b41c1e7-6642-4907-9048-a8298d969a5f	c1	Biscuits HobNob 300g.Rs.128/-	Biscuts	Pcs.
e56304bd-41d9-4a46-ab34-b563cdeaa302	c1	Biscuits Mcvts.250g.Rs.105/-	Biscuts	Pcs.
98898893-9f9d-4635-b16f-bbc05a0a6c55	c1	Biscuits Mcvts Bourbon Crm.200g.	Biscuts	Pcs.
e2defbcb-a861-4aea-95c0-dea2826f8b5a	c1	Biscuits Mcvts Dig.Choc Mk 200g.	Biscuts	Pcs.
2c73f501-5142-41f3-ba94-2e6fdb0364d5	c1	Biscuits McVts Digestive 250g.	Biscuts	Pcs.
6b573e4c-517f-4eaa-9f6c-2c8a6ba54e47	c1	Biscuits Mcvts Digestive 250g. Rs.95/-	Biscuts	Pcs.
4541d9ca-985a-4009-adc7-486af2b63e62	c1	Maggie Veg Cube 480gm	Food	Pcs.
2a07f9e1-5e1b-47b0-b75d-9b8cfb59b14e	c1	Biscuits McVts Digestive  400g	Biscuts	Pcs.
19495fd7-f893-4230-b024-fb6dbf003ba0	c1	Biscuits Mcvts Digestive 400g.Rs.145/-	Biscuts	Pcs.
ea917563-69a1-4149-af6c-b273f46c74cc	c1	Biscuits Mcvts Dig.Org.500g.Rs.176/=	Biscuts	Pcs.
b5b30e26-305e-41cd-aa91-6cf91366b683	c1	Biscuits Mcvts Gingernut 250g.	Biscuts	Pcs.
70dc3940-ae74-478f-a164-039ec4edb28d	c1	Biscuits McVts L.Digestive 250g.	Biscuts	Pcs.
b7cabcac-4779-4b50-bc24-01ac363d1537	c1	BISCUITS OREO CHIPS AHOY 266G.RS.150/-	Biscuts	Pcs.
51896010-b46b-4228-b231-b0be2f9b1215	c1	Biscuits Ritz Sand Chees Craker 118g.	Biscuts	Pcs.
8130ef10-013c-4bd9-898d-a5b38d9f766d	c1	Biscuit Strawberry Cream 133 Gm	Food	Pcs.
489110b6-4820-4abd-b75b-884f542f91d3	c1	BISCUITS WBX 215G.RS.140/-	Biscuts	Pcs.
ed1d2897-a364-4c44-90cf-56b736ae959a	c1	BISCUITS WBX 645G.RS.260/-	Biscuts	Pcs.
268a5400-0f93-4152-b4b4-9c46397f421e	c1	Biscuit Vanilla 133 Gm	Food	Pcs.
0a004e0e-2466-4cc2-8641-f4a6e6acaf9c	c1	Biscut Hobnob 300.	Biscuts	Pcs.
1093c1fa-ace9-4453-99a2-5da185bd36a1	c1	Biscut.Mcvts.Digestive Lt.400g	Biscuts	Pcs.
d2987e1f-aa54-4cb2-999c-81c4f92af974	c1	Biscut Mc Vts Dig.Lt.250g.	Biscuts	Pcs.
a28cea14-16f4-4fa8-bb20-9051c3cd1f9e	c1	Biscut Mc Vts Dig.Org.400g.	Biscuts	Pcs.
aba7ca2a-7c2b-471e-a863-1b27571b13e6	c1	Biscut Mc Vts Gingr Snap	Biscuts	Pcs.
aa4b58af-dfd6-40c7-a54a-b25223559fab	c1	Biscut Oreo Waffer Stick	Biscuts	Pcs.
74e92973-b06c-4081-831f-fa89f42873cf	c1	Biscuts Dig.115g.	Biscuts	Pcs.
bc040c7c-ae17-488f-bb2f-156f2668cf97	c1	Biscuts.Oreo Chips Ahoy142g.	Biscuts	Pcs.
4f76e2ec-a029-4453-afe6-f8a92fb752ce	c1	Biscuts Oreo Chlt.Crm.137g	Biscuts	Pcs.
3c1696d9-5801-41f5-aff0-fb7cbbac3abe	c1	Biscuts Oreo D D 137g	Biscuts	Pcs.
0660fd41-b8d7-4afb-a20b-817c639e43d8	c1	Biscuts Oreo Ds 152g	Biscuts	Pcs.
d23f1fe6-9b8d-45ab-855d-057e852731ac	c1	Biscuts Oreo Vanilla 137g	Biscuts	Pcs.
3b10bc05-e695-42b4-9750-d93dddd5c22d	c1	Biscuts Oreo Vanilla 274g.	Biscuts	Pcs.
7a558aca-4965-4fe8-b335-c275d4a287f3	c1	Biscuts Tim Tam Choco Choc 120g	Biscuts	Pcs.
59fed2e8-1578-4e91-acfa-9ff727b50624	c1	Biscuts Tim Tam Choco Choc 60g.	Biscuts	Pcs.
832bb169-5588-4f6f-8405-7340cf572721	c1	Biscuts Tim Tam Choco Van.60g	Biscuts	Pcs.
a871c027-8a30-48d2-a586-11e06f74998f	c1	Black Beans Preserved 500gm. (Salted)	Food	Pcs.
c69c678b-1852-481e-9cd1-9fc96f25d783	c1	BLACK BEAN WHOLE /LA COSTEN 560G	Food	Pcs.
f0da8ab8-2801-41c1-a77f-b264c2d22129	c1	Black Been Preserved 500g	Food	Pcs.
caabd4c7-40b4-4685-a488-ae5e5950f4d7	c1	Black Fungus 1 Kg (12%)Nostimo	Food	Pcs.
c2eb551d-07d7-4271-99e0-d51ec24fa5c9	c1	Black Fungus (Dry Veg) 500 Gm	Food	Pcs.
81266d84-a232-4910-a034-2ce17fec2864	c1	Black Papper Sauce 250ml.	Food	Pcs.
08cf2bce-ea21-4332-9c9e-0e0ef53def73	c1	Black Pepper Natuesmith (Sachet)	Food	Pcs.
f39d5c85-edaa-43b7-abd8-6a147aec4776	c1	Bluberry Patti	GURU FOOD	Pcs.
9aa3803c-291e-4ba4-ae5a-eddf78a00546	c1	Blue Berry Chips Jar	GURU FOOD	Pcs.
6a2180f4-4f84-49de-a0c6-c9886063a855	c1	Blueberry Filling 2.7kg	Food	kg.
d67d6011-c5c4-409a-8795-ae26bf361ff0	c1	BLUE BERRY PATTI 300g	Food	Pcs.
0155e82d-9f7f-4e7a-ad1f-f0df51974f24	c1	Blue Cheese 100g	Dairy Products	Pcs.
983679d1-614c-4c81-b4e7-ce3fd91ce9f9	c1	Blue Orange Lime 500ml.	Drinks	Pcs.
b5af53ff-7617-408b-a401-5428cf77b59a	c1	Blue Restoration Drink 500ml.	Drinks	Pcs.
6dc6e205-4ade-42e8-ac57-274ad9f86634	c1	Blue Restoration Drink Apple Flv.500ml	Drinks	Pcs.
1e12c068-d192-46a9-b2a9-cf0f38fb29a5	c1	Blue Restoration Drink Guvava Flv.500ml.	Drinks	Pcs.
f36f0388-fe20-4305-b0e5-c23f1fb0d759	c1	Blue Restoration Drink Peach Flv.500ml.	Drinks	Pcs.
0f2f33d4-04b2-4b2d-bea6-12c81789f87e	c1	Blue Star Deep Freezer 500ltr	Electrical Goods	Pcs.
219da7f5-f2a6-4e63-9b5a-a89b6349f4e8	c1	Blue Tokai Attikan Estate	Blue Tokai	Pcs.
c54443ae-4f6a-4525-89b7-ad0fd814a4bd	c1	Blue Tokai Attikan Estate 250 Gm Mrp.490	Blue Tokai	Pcs.
858dafe6-6408-4043-9f98-0ff6769f6dc5	c1	Blue Tokai / Attikan Estate/ 75 Gm Mrp.190	Blue Tokai	Pcs.
985b5231-d9ae-492a-b503-69f6616a464b	c1	Blue Tokai Cold Brew 250ml (1*6)Can Cherry Cascara	Blue Tokai	Pcs.
e1eada19-ee82-433c-b9a7-449f220d22fa	c1	Blue Tokai Cold Brew 250ml (1*6)Can Passionfruit	Blue Tokai	Pcs.
72023ea0-3f3e-416e-b535-163b138a8a77	c1	Blue Tokai Cold Brew 250ml (1*6)Can Ratnagiri	Blue Tokai	Pcs.
2640e9d9-e959-452c-9ad5-0394eb428769	c1	Blue Tokai Cold Brew 250ml Can Bold	Blue Tokai	Pcs.
87fad1b1-8c95-4cd5-91ff-da324d026a3d	c1	Blue Tokai Cold Brew 250ml Can Coconut	Blue Tokai	Pcs.
0df27753-1b06-4b0e-bd69-b7da3f35e30b	c1	Blue Tokai Cold Brew 250ml Can Light	Blue Tokai	Pcs.
aefbadae-4eb4-4b31-8b00-d3896b9e3d12	c1	Blue Tokai Cold Brew Bag/Bold Blend Mrp.500	Blue Tokai	Pcs.
8ad15696-a4cd-44d6-a7ad-0eb6192d3f35	c1	Blue Tokai/ Cold Brew Bag/kalledeverapura Mrp.500	Blue Tokai	Pcs.
f60feb03-492b-4b49-a43a-1a2ce631b651	c1	Blue Tokai /Cold Brew Bag Light Blend Mrp.500	Blue Tokai	Pcs.
b570240a-45bd-4d49-9996-140a12d76dc3	c1	Blue Tokai Cold Brew Box Mrp.500 (Blue)	Blue Tokai	Pcs.
d636230f-a245-44ee-aa0f-6138f61fd8d5	c1	Blue Tokai Cold Brew Box Mrp.500 (Yellow)	Blue Tokai	Pcs.
9a62321c-f2ac-424c-90ff-d55318649eca	c1	Blue Tokai Easy Pour/Attikan Estate/Small Mrp.250	Blue Tokai	Pcs.
4ee1815d-1bf0-47b1-a73a-d4f65987a99d	c1	Blue Tokai Easy Pour Attikan Estat/Medium/Dark Roas	Blue Tokai	Pcs.
9fbfd9dd-73d9-4662-8d1d-c95784abeb1e	c1	Blue Tokai Easy Pour/Mixed/Light to Dark Roasts	Blue Tokai	Pcs.
e1472d79-5796-4df0-9125-5c4ee63df71c	c1	Blue Tokai Easy Pour/Mixed/Small Mrp.250	Blue Tokai	Pcs.
700e09a4-ddc9-4093-823a-3f1310f16d41	c1	Blue Tokai/Easy Pour/NAchammai Estate/small Mrp.250	Blue Tokai	Pcs.
96f62530-6809-4146-bbe8-c97dc508aac8	c1	Blue Tokai Easy Pour / Vienna	Blue Tokai	Pcs.
0bfd1a83-48dd-4af4-98d4-97976264bc6c	c1	Blue Tokai Easy Pour/Vienna/Small Mrp.250	Blue Tokai	Pcs.
c1e99b5a-4c61-4d15-a7f9-ca24639f9c2b	c1	Blue Tokai / French Roast / 75 Gm Mrp.190	Blue Tokai	Pcs.
94c53b1c-4031-4413-b722-9fdf4455bbee	c1	Blue Tokai/silver Oak Blend 250 Gm Mrp.470	Blue Tokai	Pcs.
a66da952-75a0-4bd7-bba8-8f0e5e31942d	c1	Blue Tokai / Silver Oak Blend 75 Gm Mrp.190	Blue Tokai	Pcs.
4c2c1cf1-e196-48df-ac6a-d619222b9eda	c1	Blue Tokai Silver Oak Cafe Blend 1kg	Blue Tokai	Pcs.
a9aab44f-00c1-41f1-94b7-a520b611d2a7	c1	Blue Tokai Vienna Roast	Blue Tokai	Pcs.
1fe2b9d0-6b2f-452b-ad95-415dae5ad7d7	c1	Blue Tokai Vienna Roast 250 Gm Mrp.470	Blue Tokai	Pcs.
9afae3a1-30e2-41ad-96aa-b43133c85df3	c1	Blue Tokai / Vienna Roast / 75 Gm Mrp.190	Blue Tokai	Pcs.
7794940e-8a47-4635-aa34-174f52f97ee4	c1	Bocconccini (Cremetalia)- 500 Gm	Food	Pcs.
05b5725b-0922-47f4-a9a8-f39d5a58d492	c1	Bocconccini (Cremitalia) 500 Gm	Food	kg.
8c1bf79e-9d4e-485b-8a69-c60d8cbb594e	c1	Bolsts Hot Curry Powder 500g	Food	Pcs.
2ce3299b-e0fd-4b7d-b6e5-b2fd1edea350	c1	Bonito Flavoured Soup D 1kg	Food	Pcs.
5dde5605-b873-42f3-b40d-cc2affe96def	c1	Bounty Milk Shake 350ml.	Drinks	Pcs.
d73f22f7-7b8f-497d-a0ae-2d4ce7d1118e	c1	Bragg Apple Cider 473 Ml	Drinks	Pcs.
b2adef46-1b90-4822-9cc8-258a6905ec5e	c1	BRAND YUVA JAGGARY 600 GM.	JAGGARY	Pcs.
00763ad1-b178-4679-94c5-378f73d32ad6	c1	BRAND YUVA PEANUT &amp; COCONUT JAGGARY 600GM.	JAGGARY	Pcs.
8e7e4d18-ed02-42b9-9683-502d7b795cfe	c1	BRAND YUVA SONTH JAGGARY 600GM.	JAGGARY	Pcs.
e2a94488-1159-415e-a4f9-8d1e38dc4048	c1	Bread Crumb 10kg	Food	Pcs.
7ed20e1c-3322-4843-a023-9d01d77d2bdb	c1	Bread Crumb 1kg	Food	Pcs.
422d501c-7120-4860-a54c-34f7013d55be	c1	Bread Crumb 200gm	Food	Pcs.
37596e7a-ddbd-4853-8c8d-ed94529a4810	c1	BREAD CRUMB PANKO ORG.	Food	kg.
39f1c7ec-f40a-4d7b-957b-d04479801e7d	c1	Brekkie Almond Shake	Drinks	Pcs.
4d259079-6ecb-4452-9130-6a77ac318a24	c1	Brekkie Chocolate Shake	Drinks	Pcs.
d2441ebe-fb96-4716-9ab9-7b5254e87f3f	c1	Brekkie Coffee Shake	Drinks	Pcs.
1a8a59cc-15be-404c-a518-065116a2faae	c1	Brekkie Turmeric Shake	Drinks	Pcs.
2a697cf4-057e-43c7-9fee-0693fae72c89	c1	Briyani Brown Rice Chips	Namkeen	Pcs.
3f20af57-bedf-4319-b594-1260acf7654d	c1	BRM Almond Flour Blanched (18%)	Food	Pcs.
f040318a-c0c1-4997-988a-06f082140afb	c1	BRM Gf 1to1 Baking Flour 623 Gm Gluten Free (18%)	Food	Pcs.
c655de39-15cb-4fc2-8d35-556cf28196bd	c1	Broccoil Laccha Jar	GURU FOOD	Pcs.
c337564e-78a0-467c-8f8d-74ecc92cd4dd	c1	BROCCOLI CHIPS JAR	Food	Pcs.
103911b7-e085-4cd7-9dfd-c92daf078630	c1	Broccoli Stick Jar	GURU FOOD	Pcs.
0c702dd0-7cd8-4411-a81c-afa3cc30d44b	c1	Brown Sugar Sachet	Food	Pcs.
ae7d81a5-3c7c-4d5f-86ed-d031b146ee23	c1	Brunella Lasagne	Food	Pcs.
dbe50e11-c67a-4e16-9546-78cd25fef59d	c1	BRUNELLA PASTA FARFALLE 500GM	Food	PKT
1c64c239-3d2c-4364-b0e5-b1451a9ddaf4	c1	BRUNELLA PASTA LASAGNE 500GM	Food	PKT
271a7cf9-99cc-4997-a47e-2682923a7cc2	c1	Brwon Basmati Rice1kg.	Grains	Pcs.
e37c3e2d-551f-45b2-a220-8c4e771c329c	c1	Buffalo Ghee Tin 15kg	Ghee	Pcs.
f484fe8b-a05c-4b09-afa3-7ea31dec57e1	c1	Buffalo Mozzarella (CREMEITALIA)	Dairy Products	Pcs.
55fc115e-df9b-4343-93b4-08701cba13e6	c1	BUFFALO MOZZARELLA(CREMEITIALIA 500G.	Dairy Products	Pcs.
ec90b67b-e4aa-4c4c-87df-830efda59bc9	c1	Bulldog Worcester Sauce 500ml	Food	Pcs.
4e929904-3ba9-40b4-9d7b-4b6b41644c5c	c1	Burrata (Cremeitalia)	Food	kg.
e415605b-0ea1-432e-93a9-0b5cda60b1e3	c1	Button Mushroom 800gm (12%)	Food	Pcs.
1b51fadb-75aa-41ae-9724-373fe08e3e16	c1	Button Mushroom 800gms	Food	Pcs.
396a07a7-a1a3-41ab-bb04-688cc770b5fe	c1	Button Mushroom in Brine 400gm. (0%)	Food	Pcs.
00ed1077-076a-47aa-b901-49d7e982145f	c1	Button Mushroom -Pr ( Tandoori ) 800gm  0%	Food	Pcs.
b41ac906-64ba-476b-9eb7-d4da5542c168	c1	Cadbury Chcolate Drink 250 GM	Chocolate	Pcs.
64336122-ebe2-4b78-bc4a-59e50647359c	c1	Cadbury Cocoa Powder	Food	Pcs.
b1a94be8-288f-4cac-a63f-83764e29c323	c1	Cake Rusk	GURU FOOD	Pcs.
dd43b418-76cd-4e5a-a0be-783c5675b9c8	c1	CALIBAR GOFIT BERRY ALMOND MRP.60(12X1)	Food	BOX
a646a504-874d-4e13-84f5-e77cc8eb99d5	c1	CALIBAR GOFIT CRISPY COFFEE MRP.70(12X1)	Food	BOX
d5ed42be-734c-42e3-86d6-e0d9f510f425	c1	CALIBAR GOFIT ORANGE PEEL MRP.70(12X1)	Food	BOX
7061f8e4-9e96-4937-bd27-9fe536808cd0	c1	CALIBAR PROTEIN ALMOND CHOCO MRP.120(12X1)	Food	BOX
5a3bcd41-701c-431e-8fa5-858c39b1d261	c1	CALIBAR PROTEIN CRISPY BANANA MRP.125(12X1)	Food	BOX
ba919276-5204-4cca-8919-e2fe45db1c22	c1	CALIBAR PROTEIN LEMON PEEL MRP.125(12X1)	Food	BOX
614a1f5c-763e-44e9-be27-aaade0ac0279	c1	Camaey 125g.X3	Cosmatics	Pcs.
8880bdd1-fcac-4a7f-bc65-6c71dba11206	c1	Camay 125g.	Cosmatics	Pcs.
7b68530d-e9f6-445d-9de9-df0f9a809af9	c1	Camay Free	Cosmatics	Pcs.
6383988d-7823-41cc-9be8-9dceb1a90b6d	c1	Camay Soap 125g.Chick	Cosmatics	Pcs.
dd93f950-5dfe-49dd-a847-5eb4f16a7d19	c1	Camay Soap 125g.Classic	Cosmatics	Pcs.
987bfc88-f683-4062-9618-8180d1cd51b3	c1	Camay Soap 125g Natural	Cosmatics	Pcs.
39f883c4-7e58-4a8e-83dc-d2a364917d5b	c1	CAMEL JUICE DRINK CAN 330 ML	CAMEL	Pcs.
ae76eeba-a241-4ad9-8da7-277cd0cbce64	c1	CAMEY 125GM. RS.40/-	Cosmatics	Pcs.
ecd486f5-d7a2-4a1d-9554-213f34117b4f	c1	CAMEY 125GM. RS.45/-	Cosmatics	Pcs.
f2c8b556-eec9-4801-811f-3bfab36e07f6	c1	Camey 125g.X3 Rs.93/-	Cosmatics	Pcs.
3694c988-4757-4b00-bc3a-b4844d46449f	c1	Campagana Rigate 500g.	Food	Pcs.
901ada22-3387-4f75-a6c0-9a668de4435c	c1	Campagna Chifferi 500g	Food	Pcs.
4ca7b9fd-6a6d-40e8-8deb-6343a2850ce3	c1	Campagna Farfalle 500g	Food	Pcs.
b406cda0-17d5-4038-beaf-987136a1035f	c1	Campagna Fussilli 500g.	Food	Pcs.
dc06c5b7-1cbd-4c25-8afc-4e5209725d82	c1	Campagna Lasange 500g	Food	Pcs.
40b46f4b-9ddb-46f9-9618-bd9aef85a45b	c1	Campagna Spaghetti 500g	Food	Pcs.
a29c55e0-8c86-4945-a6ba-37447cc983a7	c1	Candy Bag (Berries) 125 Gm	Food	Pcs.
651b90a0-911d-4470-a419-4bd298ca304a	c1	Candy Tin - Berries 180 Gm	Food	Pcs.
d4380347-2ddd-45ee-917d-cddb5e83dbc9	c1	Candy Tin - Fruit 180 Gm	Food	Pcs.
f394b556-aa17-46d8-be7d-8e5875e68ddd	c1	Candy Tin - Fruity Mint 180 Gm	Food	Pcs.
6ad344b3-8adb-4d6f-b94e-b60c16adee23	c1	CAN FR Tortilla Floor 8 500gm	Food	Pcs.
dc3d52b1-b787-4188-aa0f-46d269097656	c1	CANNED BAMBOO SHOOT 552 G (12%)	Food	Pcs.
2c3fb9dd-a355-4667-80b4-2d49c60bace5	c1	Canned Straw Mushrooms 400g	Food	Pcs.
6d0f89d4-fcdb-4ba9-b9ad-047703b19e2e	c1	Canned Vege. Mock Duck 283 Gm	Food	Pcs.
d7c3469e-215e-430d-b5d9-46e819c493c9	c1	CANNED VEGETARIN MOKE DUCK 280GM	Food	Pcs.
fb34e438-c527-463e-b684-bc76194c1c76	c1	Can Sauce Chipotle 2800gm	Food	Pcs.
5b539e20-7878-49c8-875c-69a335b0273b	c1	Can Taco Shells 150gm	Food	Pcs.
04955d24-406b-42e2-bc4b-70b642b1983e	c1	Canz - Coconut Milk 400 Ml	Drinks	Pcs.
0633490a-f7ff-4c6b-a1cc-cf1fe9b317cf	c1	CANZ Peach in Syrup 820 Gm,	Food	Pcs.
0ad84164-10b6-4743-b029-ba65e0305eb8	c1	CANZ Water Chesnut in Brine 567 Gm	Food	Pcs.
c86a3621-1633-46ba-a7f0-5680e3389038	c1	Capers	Food	Pcs.
264d4610-d130-4b22-8791-456924da99e7	c1	Capers (12%)	Food	Pcs.
66374e95-fce5-43f0-a83c-2b123714ea76	c1	Capotes Capers in Vinegar3.5 Cyl	Food	Pcs.
924f4a27-0a8a-4b08-bd0c-0e2d5832bba5	c1	CAR CHARGER PD &amp; QC3.0 38W	Electrical Goods	Pcs.
6bba8f22-8270-4ce0-8515-23e67055b9ad	c1	CARNAROLI RICE 1KG	Food	Pcs.
7c9c93d8-c0ce-4e85-b674-4fd07b4698e3	c1	Carnation Tin	Food	Pcs.
d70c3c49-6edf-4ac4-95ef-99e49bf7178c	c1	Carnation Tin 405 Ml	Food	Pcs.
c5109f99-903d-4d83-929d-080bd2e3af75	c1	Carribean Rum 700ml	Drinks	Pcs.
9663b62c-2666-40f3-9a83-6589a97e3c08	c1	Casillo Semolina Pasta Flour 1kg	Food	Pcs.
797dffb1-6be1-4f7b-b418-f3c3daf25153	c1	Cavendish&amp; Harvey Mixed Fruit Drops 200g	Food	Pcs.
a8d7bfe5-c62b-4baa-9047-0a52ff7a37f6	c1	CCB Premium Mozerella Diced	Dairy Products	kg.
a1ae66c0-e0cf-4770-a01d-7749d9eac519	c1	Cf Mozzarella Pizza Blend 1 Kg	Food	Pcs.
da9665d6-4652-46e3-b93b-577cd685b9ea	c1	CF Mozzarella Pizza Blend Cheese 2 Kg	Dairy Products	Pcs.
3e8db8ea-fd10-4786-8b43-9dd430be564d	c1	CF Processed Cheese Soft 1 Kg	Dairy Products	Pcs.
8030e611-92de-45b8-8827-ea31cb0901f4	c1	Chaoko Coconut Cream	Food	Pcs.
c96a5d29-81d0-4433-8750-036e6593eb95	c1	Chaoko Coconut Milk 400 Ml Imp (12%)	Food	Pcs.
b5081a18-8d82-4119-a023-56c7ec4c5264	c1	Chaoko Coconut Milk Powder 1kg	Food	Pcs.
4aaee921-26a8-4639-8a8d-b2a3a5e36198	c1	Cheddar Cheese ft	Dairy Products	Pcs.
b0c906af-2010-4ac2-8cfb-0e56af2253f1	c1	Cheddar Cheese Slice 150gm	Dairy Products	Pcs.
f1ba873e-5071-4785-9c8c-e12de2991a40	c1	Cheddar Extra Mature 200gm	Food	Pcs.
e628b9ce-4312-4852-ae5e-110e4d4c7a0a	c1	CHEDDAR MILD RED (WESTMINISTER)-BLK	Dairy Products	kg.
53cabb63-eedc-4041-8e92-038157545769	c1	Cheddar Mild White (Westminister	Food	kg.
b6911daf-6eb7-4430-b7f4-1c99d8657bc1	c1	Cheddar Mild White (Westminster)-Blk	Food	Pcs.
33a07a82-2823-431b-be8f-0a0a0babcc42	c1	Cheddar White (Cremeitalia) 1 Kg	Food	kg.
359ac667-9653-43a9-86ab-8b279a45cc75	c1	Cheddar White (Cremetalia) 1 Kg	Food	Pcs.
984d91bd-73fe-421b-a464-032242e03b74	c1	Cheddar Yellow (Cremeitalia) 1kg	Food	Pcs.
f8230c38-46bb-444d-8edc-57f1350b2178	c1	Chees Arla White Feta 500 Gm	Dairy Products	Pcs.
b3f11afb-d866-41e9-bf32-c44683555e5e	c1	Chees Bocconcini 500g.	Dairy Products	Pcs.
88225880-b50d-4237-a5dc-f89706e7c7d2	c1	Chees Burrata (Cremeitalia) 125gm	Dairy Products	Pcs.
86bbc22f-6bfd-41ba-8431-27394639701d	c1	Chees Burrata (MYMA) 250G.	Dairy Products	Pcs.
6e7f1692-b304-4250-b133-c19994bc07dc	c1	CHEES COMBI WHITE-500G.	Dairy Products	Pcs.
03be8ab2-e40d-4ed6-ab0e-c01287f3e549	c1	CHEES DANISH BLUE 100G.	Dairy Products	Pcs.
2f30648d-f935-4f6b-a045-c98467739752	c1	Chees Danish White-500g.	Dairy Products	Pcs.
3a19136a-eee8-4933-9047-155e0db1c124	c1	Cheese Achor Cream Cheese 1 Kg	Dairy Products	Pcs.
d4ff2d05-6c2b-4eea-a5ea-e13824fdf21a	c1	Cheese Basiron Smoked Gouda Cheese 200gm	Dairy Products	Pcs.
e4d17757-3dd8-47e8-ab75-94eca796bdac	c1	Cheese Blue Heaven Danablu 100 Gm	Dairy Products	Pcs.
9ec8e4f9-6160-4334-848a-c4424de82f78	c1	Cheese Breton Goat Cheese Plain 100 Gm	Dairy Products	Pcs.
029a6f35-aab8-4b15-b476-247219708e2b	c1	Cheese Burrata Cheese (12%)	Dairy Products	Pcs.
a26cefb1-39f8-4857-92c5-9722fab0faa8	c1	Cheese Burrata ( Cremeitalia) 500gm	Dairy Products	Pcs.
f760b7e2-f69a-4082-8341-4ea36269319f	c1	Cheese Cherry Bocconcini 500 Gm	Dairy Products	Pcs.
5912ca85-fa02-4a11-8a90-7c6cf9cad787	c1	Cheese Coloured Cheddar Cheese Portion 200 Gm	Dairy Products	Pcs.
ea85e055-a74d-46ae-9b92-e7e69a1b378d	c1	Cheese Daily Dairy Gouda Portions 220gm	Dairy Products	Pcs.
c8fe6ba8-42e0-4636-b5de-0bfcc9bb25cb	c1	Cheese Daily Dairy Gouda Portions 220gms	Food	Pcs.
b5a41c64-0533-4b4e-a478-ccda1757fdb7	c1	Cheese Daily Dairy Smoked Cheese Natural Portions	Dairy Products	Pcs.
00407078-7663-4b3e-9576-38468573349e	c1	Cheese Daily Gouda Portions 220 Gm	Dairy Products	Pcs.
79d48d27-6173-4f11-b5b5-2e5df7751168	c1	Cheese Danish Blue 50% FIDM Portions 100gm	Dairy Products	Pcs.
51ba61eb-911f-4bc1-8a47-638d901b5cec	c1	Cheese Danish Blue Danablu 50% FDM 100 Gms	Dairy Products	Pcs.
ea83dd68-f5f8-4d7c-876c-161b809feb70	c1	Cheese Delicatesse Feta 500 Gm	Dairy Products	Pcs.
f8d4cc98-733b-4e4d-8e65-b64f0d919573	c1	Cheese Entremont French Emmenthal Portion 135 Gm	Dairy Products	Pcs.
09b12fb9-2582-4185-8c56-1a915a79860a	c1	Cheese Eurial Goat Cheese 1 Kg	Dairy Products	kg.
e040fb75-31f6-4df5-a2dd-802f4721106c	c1	Cheese Ferrari Veg. Italian Hard Cheese 5 Kg	Dairy Products	kg.
eeb4da47-90f3-431d-b544-af3a2c9dad81	c1	Cheese Filler Cheese 400gm	Dairy Products	Pcs.
19488040-8a8f-4e16-8e0b-63ac385cfffe	c1	Cheese Fillo Pastry Sheets 400 Gm	Dairy Products	Pcs.
3afcc096-e7b8-417b-b241-8907e0762e92	c1	CHEES E FINGER	GURU FOOD	Pcs.
bbbe8b5e-01d9-467c-ba03-a7acc54da0cd	c1	Cheese Formaggio 200 Gm	Dairy Products	kg.
7db1e0cc-b831-45b1-b385-29b35270ea8e	c1	Cheese Frico Gauda Wedges 295 Gm	Dairy Products	Pcs.
94e450cc-bbc7-4685-b011-cd702b38f76a	c1	Cheese Granarolo Frozen Burrata 250 Gm	Dairy Products	Pcs.
b5690624-357d-4f49-8e0f-997de490dbf0	c1	Cheese Granarolo Hard Cheese (4.5 Kg)	Dairy Products	kg.
3b9c3f63-0018-49cd-854e-414e5d3f0d19	c1	Cheese &amp; Herbs Nachos 200gr	Namkeen	Pcs.
fc181d3a-9583-40a2-9d86-0943bf924280	c1	Cheese Impero Bocconcini 275 Gm	Dairy Products	Pcs.
3e62da09-523c-46e7-a2c7-0ce5fc4a2f15	c1	Cheese Impero Grana Hard Permesan Cheese 250gm	Dairy Products	Pcs.
8cae6f15-7f3d-42f9-95f8-fee75d0b07ac	c1	Cheese Impero GRATED Parmesson 100gms	Dairy Products	Pcs.
77d658fa-8544-418c-8ed2-84e82bb043a0	c1	Cheese Impero Mascarpone 400 Gm	Dairy Products	Pcs.
56602590-963d-4307-8cad-993956ed44bc	c1	Cheese Impero Mascropone 200gm.	Dairy Products	Pcs.
11472d49-0df5-4fbb-9b98-b7e434f6f161	c1	Cheese Impero Mozzarella Cheddar Chesse Diced 1 Kg	Dairy Products	Pcs.
6051445c-1e28-4828-91a6-1613b61212c0	c1	Cheese Impero Mozzarella Cheese 200gm	Dairy Products	Pcs.
bd7fc32e-0e96-46fb-9e95-c918fa3331a2	c1	Cheese Impero Pizza Cheese 200gm	Dairy Products	Pcs.
89388ba3-f614-4b46-8477-372e82ff1158	c1	Cheese Impero Ricotta 200 Gm	Dairy Products	Pcs.
e647dc69-55e6-4495-944c-70d6a012c614	c1	Cheese Impero White Chedar 200gm.	Dairy Products	Pcs.
4ca48c93-5bd7-4138-a180-dda3947691fe	c1	Cheese JH Mild Cheddar Cheese Portion 200g MRP.449	Dairy Products	Pcs.
8fcd92cc-9641-4e60-a5e7-10e1b5869d4a	c1	Cheese La Vache Feta Cheese 500gm	Dairy Products	Pcs.
f59e1461-a09f-41a0-b18d-d6fa877bd67b	c1	Cheese Mature Coloured Cheddar Cheese 200 Gm	Dairy Products	Pcs.
ec90376c-6ba9-4179-a54a-88cf21cd7d90	c1	Cheese Mature White Cheddar Portions 200gm	Dairy Products	Pcs.
0f3ec428-c532-471f-9a9f-db1236013b92	c1	Cheese Monte Christo Coloured Cheddar Block 2.5 Kg	Dairy Products	kg.
b2dae7d4-c7f8-44df-87d4-a0a7fea1a51e	c1	Cheese Parmigiano Rainbow 4.5 Kg Approx	Dairy Products	kg.
92355ef4-f1e4-4243-b4ed-7407d7ccf339	c1	Cheese Payson Breton Pasteurised Camembert 125 Gm	Dairy Products	Pcs.
aabf9f20-b3e9-4961-8945-0468721c4b82	c1	Cheese Perla Granbersaio1/8th (Veg. Parmesan) 5 Kg	Food	kg.
1b81bbb8-f20b-4f54-8384-9d7829dc8ceb	c1	Cheese Permesan Cheese Block	Dairy Products	kg.
b0d4f5db-4c85-48e1-ada4-dd8a08839f41	c1	Cheese Philadelphia Original	Dairy Products	Pcs.
96c11a9d-6dd9-4718-9e2d-f033013198a7	c1	Cheese Process Cheese Casted Loaf Drop 4.54kg	Dairy Products	Pcs.
539922ea-172b-403e-a3d5-8a35ecd3127f	c1	Cheese Processed Cheese Block 1kg	Dairy Products	Pcs.
3d77b45d-7c5e-44f0-b829-54c6146ffd02	c1	Cheese Processed Cheese Slice 765gm (Yellow)	Dairy Products	Pcs.
1b49fea0-1fa1-4db0-9319-f911f11cb977	c1	Cheese Ricotta 500 Gm	Dairy Products	Pcs.
7a252a33-0613-4afd-a7c1-63e59ed107a0	c1	Cheese Wyke Extra Matured Cheddar 200 Gm	Dairy Products	Pcs.
b9180aa5-23d3-497c-bb72-2e8e3f6d7d1a	c1	Cheese Wyke Mature Cheddar 200 Gm	Dairy Products	Pcs.
754aa7be-0f1a-4d1a-a596-43906bc9eb86	c1	Cheese Wyke Mild Colour Cheddar 200 Gm	Dairy Products	Pcs.
227aab79-4d68-4b29-9745-a311a9fdbe09	c1	Cheese Wyke Mild White Cheddar 200gm	Dairy Products	Pcs.
a52620f4-9ce9-4661-bb27-6ffa70798d2a	c1	Cheese Wyke Red Leicester 200gm	Dairy Products	Pcs.
8a10c9e9-cbf8-46b7-8aa0-0371dc0b293a	c1	Chees Hard Chees(Vegetarin)Blk	Dairy Products	kg.
632e20b7-74df-4126-8bdb-d04abda7f4a1	c1	CHEES Mascarpone (LA CREMLLA)-500GM	Dairy Products	Pcs.
12ec296f-c44c-4f65-a643-5c9b98ec59e7	c1	Chees Mascrpone(LA CREMELLA) 500GM	Dairy Products	Pcs.
b0080726-6b56-437e-83c2-fe50bbbb82e5	c1	CHEES MILD RED CHEDDAR(WESTMINISTER)-BLK	Dairy Products	kg.
dcbbded6-0f10-46fb-8157-96ec2bbb5c2f	c1	Chees Red Cheddar	Dairy Products	kg.
9e5c6416-713b-49f3-823a-519b2278c2d3	c1	Chees Ricotta (MYMA)-500G.	Dairy Products	Pcs.
90067f5e-6681-4fe9-a714-5656656ce094	c1	Chees Thermocol Box-80ltr	Dairy Products	Pcs.
436fb178-8ef0-445e-99e4-514c3475b514	c1	Chefys Chili Flakes 0.70 Gm	Food	Pcs.
6afefc36-4450-4e58-a5bf-b07f91540340	c1	Chefys Chilli Flakes (150)	&#4; Primary	PKT
f2d5ae37-54a5-4656-8aa6-58fb85e34734	c1	Chefys Oregano Sachet (150)	&#4; Primary	PKT
69cf7c81-9572-4977-a3cd-adbd80bac2be	c1	Chenab Casillo Italian Soft Wheat Flour Pizza 1 Kg	&#4; Primary	Pcs.
379a6737-a9f7-4fec-968b-26d2f303eb9e	c1	Chenab Meishi Yakitori Saauce 230gm	&#4; Primary	Pcs.
c0222854-f712-4eb6-8e1b-3f3fd37d87da	c1	Chenab Sweet &amp; Dried Cranberries - 1kg	&#4; Primary	Pcs.
cb4a9575-16d4-4dfc-8898-f42232e432d2	c1	Chenab Sweet &amp; Dried Whole Bluberries -1kg	&#4; Primary	Pcs.
e4fb6679-a165-4c97-bc27-057ebd245f11	c1	CHFDD300DGSW	Electrical Goods	Pcs.
cb29cd18-f0fb-4ad8-b57a-d7b4e296f393	c1	Chilli Flakes 40gm.	Food	Pcs.
91da286b-47f4-4f2b-8a9d-0f06ef3ed555	c1	Chilliflaks	Food	Pcs.
761e2310-3818-4f5e-b945-1e37581790c2	c1	CHILLI OIL	Oil	Pcs.
2667be94-65a3-4423-a9a5-1bcb3b6f1d17	c1	Chilli Sauce 3.3 Kg	Food	Pcs.
20271342-3e8a-4d7d-af36-9df7249e2924	c1	Chilli Sauce 600gm	Food	Pcs.
312a572f-275a-45f7-81f4-d69fddbec0ff	c1	Chilly Flakes 25 Kg	Food	Pcs.
db7875f1-2af8-4c64-b408-6d65df3a33df	c1	Chilly Flakes Nature Smith (Pouch) 10 Gm	Food	Pcs.
94faa4fd-f080-4ac4-a4c7-f72202a7b2a4	c1	Chilly Paste 900 Gm	Food	Pcs.
59c81bd7-b316-48a3-adf4-10063df3d3d3	c1	Chilly Sauce 570gm	Food	Pcs.
c81c3acb-3f8c-45aa-a204-a04f75bf3957	c1	Ching&apos;s Dark Soy 750gm	Food	Pcs.
7a1e5cc7-e6df-418a-b427-e5d83677a2b0	c1	Ching&apos;s Green Chilli Sauce 680gm	Food	Pcs.
c82f9e58-a389-40ca-936d-68efb525b760	c1	Ching&apos;s Instant Hot &amp; Sour Soop	Food	Pcs.
d9d93cc3-0a60-4252-88ea-f989c5f72ac3	c1	Ching&apos;s Instant Mix Veg Soup	Food	Pcs.
74cc12cd-62dc-4d95-8cbe-9301ea75e123	c1	Ching&apos;s Instant Sweet Corn Soup	Food	Pcs.
73c5485b-6583-4dea-82dd-6db8268dd8ed	c1	Ching&apos;s Instant Tomato Soup	Food	Pcs.
5da35c0a-579b-4c19-a5c8-bc98e5aeedf8	c1	Ching&apos;s Isntant Manchow Soup	Food	Pcs.
d6a59f0e-b75e-425b-989a-7b2d76dec5b4	c1	Ching&apos;s Red Chilli Sauce 680gm	Food	Pcs.
819a0e62-dc7a-4de4-8271-58ad3ffc1a46	c1	Ching&apos;s Schezwan Chutney 1000gm	Food	Pcs.
2a475697-3af5-46b3-869b-23afd1aeea2d	c1	CHINKIANG VINEGAR (550ML) (18%)	Drinks	Pcs.
a076d74c-b7b2-4784-8897-62d04a1fbec3	c1	Chip Chock 250gm.	Biscuts	Pcs.
5571bf26-dcb3-48f8-b884-2055a74d61f6	c1	Chipotle Peppers in Adobo Sauce 199g	Food	Pcs.
94ccf5a6-ed3f-4310-b473-ddf918b66fab	c1	Chipotle Peppers in Adobo Sauce 212g	Food	Pcs.
77d46d3b-e2fa-4f7d-a4fb-2dc15699877a	c1	Chips Cookies 84 Gm	Food	Pcs.
a3dd0294-820f-4040-8547-439660f08a55	c1	Chlt.Animal 12.5g Rs.10/-	Chocolate	Pcs.
74e58ed4-a7fb-481a-871c-efc6f3867f53	c1	Chlt.Animal 37.5g.	Chocolate	Pcs.
fd7a4232-2809-46cb-9f1c-d1b38169bb99	c1	Chlt.Animal 75g. Free	Chocolate	Pcs.
9cefb099-d12f-4022-9149-d134a1b27546	c1	Chlt.Butterscotch Bites 125gm.	Chocolate	Pcs.
6f2f6ab0-72f7-4642-bc1e-e77ab651d5a7	c1	Chlt.Cacoo120g.1+1	Chocolate	Pcs.
2d5aa839-59b3-457a-ae0c-776e28435f77	c1	Chlt.Chcomobella 375g	Chocolate	Pcs.
7f2c4294-8a8e-47ea-8be7-c04965462343	c1	Chlt.Chocoanimal 37g	Biscuts	Pcs.
81ace84e-4fb5-4076-a5c9-10c56f80f98d	c1	Chlt.Chocolate Nut 150g.	Chocolate	Pcs.
13ccf48c-0d01-4a45-b571-7607d130f22c	c1	Chlt.Chocolate Nut 150gm.	Chocolate	Pcs.
1b9ad534-f7fb-4c9d-903b-df8deabdade6	c1	Chlt.Chocolecious175g.	Chocolate	Pcs.
f8a5f9f4-9873-4292-a488-c73bd581f855	c1	Chlt.Chocomagic 375g.	Chocolate	Pcs.
da723d6d-d03f-4795-b4ea-5a261180c64e	c1	Chlt.Chocomix 225g.	Chocolate	Pcs.
6bde35da-c44f-4922-96aa-294b4154cc90	c1	Chlt.Chocomixcokies 225g.	Chocolate	Pcs.
e7c6114e-99b9-4daf-b1f4-81a0c856cd1a	c1	Chlt.Claire 140gm.	Chocolate	Pcs.
38828b5f-6916-4c1d-86a4-8f4a92d1f857	c1	Chlt.Club 100g.	Biscuts	Pcs.
683215c6-dfaa-4487-a49b-34c7ed747a09	c1	Chlt.Club 250g.	Chocolate	Pcs.
97b40de4-47a9-4586-89f2-8ceb3cba98d2	c1	Chlt.Club 500g.1+1	Chocolate	Pcs.
7b4e58e6-94d1-4535-b0a5-b115ea999d26	c1	Chlt.Corinival 175g.	Chocolate	Pcs.
b29e1721-218a-4e00-b293-e1c34c220287	c1	Chlt.Delecios125g.	Chocolate	Pcs.
6c4be22a-5d1d-459e-a698-5a06d8bddd53	c1	Chlt.Dinosour 12.5g.Rs.10/-	Chocolate	Pcs.
48adf1ec-4eec-4566-8327-0eb33c1e8e81	c1	Chlt.Dolphin 12.5g Rs.10/-	Chocolate	Pcs.
d6ac56e8-3642-42b3-ba8f-dca56213ee87	c1	Chlt.Evita 175g.	Chocolate	Pcs.
ff5c992b-28cf-4bdd-9d25-c6c9bfd472a4	c1	Chlt.Gloritte 100g	Chocolate	Pcs.
5378b384-61b0-4ee3-a29e-8c8a9dc3ea9d	c1	Chlt.J.Book 87gm.	Chocolate	Pcs.
1c49d643-22ef-484d-be00-6f9c716c6c55	c1	Chlt.Jungal Book 1+1 Rs.140/-	Chocolate	Pcs.
1d593c97-6645-4cdd-bf17-a3b0c3c61279	c1	Chlt.Jungle Book 174g.1+1	Chocolate	Pcs.
c3820678-dd90-4aa2-a09a-d1f339dfb33a	c1	Chlt.Jungle Book 190g.	Chocolate	Pcs.
4ec3a232-f20e-4a01-a01e-a4436febef29	c1	Chlt.Jungle Buddies 250g.	Chocolate	Pcs.
f2088a37-9443-498a-96f6-61a5ef0b2fe5	c1	Chlt.Karacko 1+1	Chocolate	Pcs.
ead3a196-9767-44d1-bb4c-67541fcb7266	c1	Chlt.Kravour Bamboo 180g	Chocolate	Pcs.
d3d259b3-4ec0-4210-b966-e77b6c1beac8	c1	Chlt.Kravour Hand Bag 180g.	Chocolate	Pcs.
09abf626-ef08-46be-97e8-44bfa74cd6ae	c1	Chlt.Kravour Trunk 90g.	Chocolate	Pcs.
c1219f50-75b1-4e2f-bf18-42bc04164149	c1	Chlt.Loverly 170g.	Chocolate	Pcs.
ee9d001e-05b1-43d2-96bb-79fe2562c194	c1	Chlt.Magic 150g.	Chocolate	Pcs.
5dc5cc61-347e-4b7c-9f53-937d35970249	c1	Chlt.Milkvally 175g.	Chocolate	Pcs.
d8f59abb-e181-4e7f-b52c-c50735efbe25	c1	Chlt.Preety Good 1+1 Rs.175/-	Chocolate	Pcs.
abf44955-f5c7-41e4-9aca-bcba70a5a50d	c1	Chlt.Preety Good 85g. Free	Chocolate	Pcs.
3a654507-5cb5-455c-bf38-01277c2c007b	c1	Chlt.Prettygood 1+1	Chocolate	Pcs.
2eedc60e-f1cc-45e7-b5c5-269d6cf1dd64	c1	Chlt.Pretty Good 85g.	Chocolate	Pcs.
9ed88b77-e7c7-48d4-8a8f-16fa47b15067	c1	Chlt.Prety Good Rs.95/-	Chocolate	Pcs.
a2555e1f-647b-4b56-bad5-af3414b6f8d5	c1	Chlt.Really Nice200g.1+1	Chocolate	Pcs.
8066326c-60d1-404f-8529-073feba848dd	c1	Chlt.Really Nice Rs.110/-	Chocolate	Pcs.
74e0f1a5-6d0d-49ff-8a41-793260e816d6	c1	Chlt Realy Nice 1+1 Rs.195/-	Chocolate	Pcs.
1ec27fa8-e846-453e-8313-1beb481c4d4c	c1	Chlt.Realy Nice Free	Chocolate	Pcs.
5795058a-89d1-46ee-b78e-dd5b422b8b8b	c1	Chlt.Saprano 100g.Free	Chocolate	Pcs.
442cf6e9-ef86-41a7-bbce-172f3fd687b6	c1	Chlt Secrets 160g	Biscuts	Pcs.
4169dd4b-fe09-4bf9-a229-b1364549f9da	c1	Chlt.Sheer Magic	Chocolate	Pcs.
f12f0c1b-8909-44bb-8b7d-20e96d179948	c1	Chlt.Sheer Magic 200g.1+1	Chocolate	Pcs.
aea9581f-3dd8-46ff-a0a2-1516f7ccf552	c1	Chlt.This N That	Chocolate	Pcs.
c2089e4e-e973-4fd0-8c21-47027c61ffea	c1	Chlt.Twin Pack Almond Chlt.160g	Chocolate	Pcs.
30b1d671-aa38-4e70-8256-5bb398f144ae	c1	Chlt.Twins Pack 120gm.	Chocolate	Pcs.
f003ceca-9085-432e-a575-2018b86a032b	c1	Chocho Fingers 40g	SHS GLOBAL	Pcs.
992aa7b3-df7d-4b25-ab35-8cb7df8356d0	c1	Chocho Mo 100g	SHS GLOBAL	Pcs.
accdc8fc-08ab-4d8e-8519-84764b3b0feb	c1	Cho Cho Wafer Snack 30g	Food	Pcs.
24727298-73f1-4876-8b2b-ae16ecacbb7a	c1	Cho Cho Wafer Stick 260 Gm	Chocolate	Pcs.
6368831d-1dac-49f2-a4b3-026faf191891	c1	Choclate	Food	Pcs.
a5a2dd5c-0912-4639-b13c-e1447ab5354c	c1	Choclate Paste	Food	Pcs.
4745816f-6ab3-46b9-b2cc-20138f0e9766	c1	Choco Coin Strip 56 Gm	Food	Pcs.
0e5ac5df-27ef-403c-8643-bf0e8b4de4a0	c1	Chocodates 200gm	Food	Pcs.
c1c20499-3807-4981-a0b6-5e23fd9d00d8	c1	Chocolate Cake 200g	GURU FOOD	Pcs.
bfa1ab68-9adc-47b2-b872-ddd4bdde11b1	c1	Chocolate Gift Tray	Chocolate	Pcs.
b56be419-7b7f-4ad7-a350-c429ce8a3482	c1	CHOCOLATE PASTE 750gm.	Chocolate	Pcs.
8d379057-6289-463c-b022-a39c314324ae	c1	Choco Lava Cake Veg	Food	Pcs.
1db17e00-3067-40ee-9015-b4eb357723df	c1	Chocoseizzo Truffels White Fillings 400gm	Chocolate	Pcs.
96a27354-9683-4e32-b915-7b1847bb3b43	c1	Chocoswiss Carnival 175 Gm	Chocolate	Pcs.
b65b1c66-6ba3-46d9-a630-30d87f6099bd	c1	Chocoswiss Chocolicious 175 Gm	Chocolate	Pcs.
3e916c1d-0ccc-404e-8299-bc13ebc2b816	c1	Chocoswiss Club 100 Gm	Chocolate	Pcs.
ed50ee04-f187-4bd0-865f-80e2893bc3cd	c1	CHOCOSWISS ELEGANCE 150GM	Chocolate	Pcs.
477a5acd-e3e8-4e08-8f39-fa24959855f9	c1	Chocoswiss Evita 175 Gm	Chocolate	Pcs.
026f1d63-de9f-4071-b31a-6725d26f4182	c1	CHOCOSWISS FABULOUS 100	Chocolate	Pcs.
c7bf8976-8a95-4b8e-9c4a-3403e7340ad6	c1	CHOCOSWISS JOY 120 GM	Chocolate	Pcs.
2ebef205-5d09-4e6f-8826-c21267d58fd0	c1	Chocoswiss jungle buddies 150 gm	Chocolate	Pcs.
df726af4-4a7d-4446-ba7a-2395c04ec1b2	c1	Chocoswiss Loverly 170 Gm	Chocolate	Pcs.
93bd3cf4-ccaa-4660-83f7-89384d44be81	c1	Chocoswiss magic 150 gm	Chocolate	Pcs.
68c16056-d825-458b-9c6a-ef64d19ed24d	c1	Chocoswiss Milky  60 Gm	Chocolate	Pcs.
2fa716e0-b429-4905-a1e3-73ed232bcd03	c1	Chocoswiss Milky Fruit &amp; Nut 60 Gm	Chocolate	Pcs.
f704c7db-1e8f-4cc5-8fbb-2f287cd2df73	c1	Chocoswiss Really Nice 100 Gm	Chocolate	Pcs.
bcef4cb7-a684-44b0-bad2-584663e39cd0	c1	Chocoswizzo Frut and Nuts Bar 35g	Chocolate	Pcs.
1e57c076-f60d-4e0d-92d6-a2669caeb7e5	c1	chocoswizzo gloritte 100gm	Chocolate	Pcs.
5b9f22ef-c301-4490-9d44-83981c2829e4	c1	Chocoswizzo Mocha Bar 35g	Chocolate	Pcs.
30bac2d9-5f33-4cc3-9dbd-3fbed8a7b6d2	c1	Chocoswizzo Orange Bar 35g	Chocolate	Pcs.
35ddf0ce-f958-4ade-b960-97f6b4b3a8c9	c1	Chocoswizzo Roasted Almond Bar 35g	Chocolate	Pcs.
5707b8e8-64fd-4b91-b2fe-5cc38bb0cd1a	c1	Chocoswizzo Truffels  600gm	Chocolate	Pcs.
58c4a875-8260-47e8-9bcb-64d9769dcda8	c1	Chocoswizzo Truffels Assorted 300gm	Chocolate	Pcs.
49672435-c156-4590-8b41-3b469eb2714e	c1	Chocoswizzo Truffels Assorted 400gm	Chocolate	Pcs.
63073f1e-3f4d-4cad-bb61-f117f313b0ff	c1	Chocoswizzo Truffels Dark 400gm	Chocolate	Pcs.
20293b18-e62f-46f2-bed4-2810d3bda860	c1	Chocoswizzo Truffels Milky 400gm	Chocolate	Pcs.
00121a57-5955-4e21-b085-8d7a03818c00	c1	Chocoswizzo Truffels Rice Crispies 400gm	Chocolate	Pcs.
ba2baccf-d120-496a-9cb6-7587b598a568	c1	Chocozay Truffle 225 Gm Pouch Loose (18%)	Food	Pcs.
e67744a6-61ca-4fa1-821c-84c7d09d8ab1	c1	CHOPPED HAM (PORK MEAT) 340gm	Food	Pcs.
1ce0ab18-bc97-49ff-a847-5dc9392df3e8	c1	Chow Chow 500gm	&#4; Primary	Pcs.
e4eb1776-2b40-4a1c-b18e-b480d39fde23	c1	C&amp;H Sour Wild Berry Drops 175g	Chocolate	Pcs.
863a5440-d0af-4a76-a9f7-f1c790c4cafd	c1	CHUA HAH SENG CHILLI PASTE TIN BLUE COLOR 900G	Food	Pcs.
8d945a27-8fbb-48c7-9f5f-ba87e8ee36f8	c1	Chunky Chocho 60g	SHS GLOBAL	Pcs.
59b6b006-04a6-4e25-97bf-eb53e774c67e	c1	Ciao Peeled Tomato 2550 Gm	Food	Pcs.
ff01a3cb-2afb-48f4-9b02-131007a6630a	c1	CIAO POMODORI PEELED TOMATOES 2.5 KG	Food	Pcs.
fd22087d-2631-46d0-b560-f342002f30a4	c1	City Fresh Coconut Juice 300ml	Drinks	Pcs.
3c704ecc-020f-4b7e-b863-b56823e4f0d6	c1	Clausthier Lemon Beer	Drinks	Pcs.
de53d9a5-40f8-43b0-a1f7-c95e2bcc3d8b	c1	CLAUSTHLER CLLASIC CAN 330ML	Drinks	Pcs.
b4469319-f28e-4a7e-8cbd-cd0b5c129a6b	c1	Coca Cola 1.25 Ltr Pet	Drinks	Pcs.
bbb36fb7-a378-49b2-a194-43035ec08312	c1	Coca Cola Assorted Soft Drink 150ml	Drinks	Pcs.
822f65fc-c00e-4bd4-af5a-9adfbca13fc5	c1	Coca Cola Can Diet 150 Ml	Drinks	Pcs.
0dd33d5c-22ef-41d5-bb36-16785d96d492	c1	Coca Cola Fanta Orange 330 Ml	Drinks	Pcs.
8765cdd9-a03b-4f48-b5a7-bfdb43a05d68	c1	Coca Cola Original 330 Ml Can	Drinks	Pcs.
66ede55f-29d6-40fa-a07a-14e7a1ae296f	c1	COCA COLA ZERO SUGAR 320ML	Drinks	Pcs.
7decfab3-96e1-4fe8-9311-b213b7702a52	c1	COCKTAIL MILLET MIXTURE	GURU FOOD	jar
97f41a32-de56-4bde-a6ea-d4ec7061614d	c1	Coco Cado Assorted Pudding 2pcs	Drinks	Pcs.
cab6b581-3522-420a-94e7-c0770232670a	c1	Coco Cado Assorted Pudding 4pcs	Drinks	Pcs.
ba3a1105-0a0e-42ba-b723-bca038c3463c	c1	Coco Cado Assorted Pudding 6 Pcs	Drinks	Pcs.
a2923d09-675e-4b1c-9884-3d5e07d87c60	c1	Coco Cado Jelly Nata 2 Pcs	Food	Pcs.
e8f8fbeb-6319-4bf2-8baf-0d117876d01b	c1	Coco Cado Jelly Nata 6 Pcs Mrp.180	Food	Pcs.
7f9b1d4a-6607-4476-9be6-875d797c3604	c1	Coconut Milk Chaoko	Drinks	Pcs.
a773fc26-a8e2-4d96-a95e-f7567e0b8c13	c1	Coconut Milk Chaoko 400ml Tin	Drinks	Pcs.
78686f84-676c-41b2-9fda-5573eda023e4	c1	Coconut Milk LITE 400ml.	Drinks	Pcs.
b4b7bc22-1acd-48e3-8e65-effa5070dc50	c1	Coffe 200ge (5%)	Food	jar
74bc323d-ad6c-4849-9121-4ea88ca72639	c1	Coffee Beans Lavaza 500gm&apos;	TEA	Pcs.
347b186d-92a6-4f2a-815d-04b4114004a8	c1	Coffee Choco Mix	Chocolate	BOX
db6a6f44-1554-49b9-be17-5d6ea425a9f1	c1	Coffee in Box	TEA	case
ea775379-8ee2-452f-9a7e-4288a3dcd6cc	c1	Colavita Pasta Fettucine	Food	Pcs.
3f70ac51-2369-4194-9dab-387d4f4cf6fc	c1	Cold Coffee Regular	Plane B Coffee	Pcs.
81a97ddf-0132-4d1f-ac0e-8efd8b3d7c9c	c1	Cold Coffee Strong	Plane B Coffee	Pcs.
c966ec0c-edb1-4e39-b849-7b982922eba5	c1	Cold Coffe Silver	Plane B Coffee	Pcs.
ec983388-ffef-4ca6-881d-e924d1f25dcd	c1	COLD DRINK MIX FLAVOUR RS.40/-	Drinks	Pcs.
c5414a75-042a-4f1c-a547-84dda9e6ff83	c1	COLD DRINKS WITH MIX FLAVOURS 1.25 LTR	Drinks	Pcs.
2141ee22-9eb9-4281-b2fb-6bae2d618803	c1	COLD DRINKS WITH MIX FLAVOURS 750 ML	Drinks	Pcs.
5bfe0f95-75ab-4766-a365-23f7f8d5c358	c1	COLD DRINK WITH MIX FLAVOR 1.25 L	Drinks	Pcs.
94cc18f3-90ce-4dd2-9f12-cf7e9bec7f08	c1	COLD DRONKS 1.25 LTR	Drinks	Pcs.
bb831600-ddfc-4e64-99ad-b4ead9275571	c1	Colman Mustard	Food	Pcs.
0a78f359-ca9f-4fd9-b4c3-4b51af46696d	c1	Comfort Fabric Conditioner 2 Ltr	Cosmatics	Pcs.
de66deef-b756-4941-8947-3e068639c4a5	c1	COMPUTE	Electrical Goods	Pcs.
08ca6843-ccea-439e-9ddf-ba3757fa88ee	c1	COMPUTOR KEYBOARD	Electrical Goods	Pcs.
556f993c-21d8-47bc-9535-5858a2d9c8f6	c1	COOKING SAKE 1.8L	Food	Pcs.
36608653-e9ee-4a02-ac9b-b9356eee418a	c1	Cooking Sauce	Food	Pcs.
720f31d1-fb08-4777-b6dd-408adf9692d9	c1	Cooking Sauce (H P)	Food	Pcs.
4989a955-0e83-461c-bfb1-8c3b2373286e	c1	Cooking Sauce (Plum)	Food	Pcs.
b4958eb0-9335-46f2-919b-3e74ac0784df	c1	COOKING VINAGER	Oil	Pcs.
53f3a0d5-0aa4-40e0-8c58-dc9bf90351f0	c1	Cooking Vinegar	Food	Pcs.
f0e24fdb-c09c-46c2-8181-c37db629af23	c1	Cooking Vinegar China Wine Hua Tua 640 Ml (18%)	Food	Pcs.
ec21101a-7255-4ed0-9c62-970857d565d5	c1	Cooking Vinegar  Wine Hua Tua (5%)	Food	Pcs.
51dd7c7f-8422-417a-98d0-852be55dba68	c1	Cooking White Vineger	Drinks	Pcs.
d90eb27b-1d8e-45f1-b4ce-00e26886b41e	c1	COOL MINT( LOTTE)	Food	Pcs.
90e6370c-198a-4ba6-b2b3-32dfebaad59c	c1	Corn Dots Jar	GURU FOOD	Pcs.
27df2ff6-2190-4486-ac33-e9ef86b8bf85	c1	CORNITOS 200GM CHIPS JALAPENO NACHOS	Food	kg.
59b68c41-42f3-4b92-9190-b89bc729dc02	c1	Cornitos Barbeque 60 Gm	Food	Pcs.
cf7b838a-f449-4846-800f-84ba81cbc30a	c1	Cornitos Cheese N Herbs 150 Gm	Food	Pcs.
5e214106-2a41-48ae-9da7-1110a2c5ffc7	c1	Cornitos Cheese N Herbs 60 Gm	Food	Pcs.
e53d730b-4c51-4377-a123-557093501fb8	c1	Cornitos Cheesy DIP Jalapeno Jar 100g.	Food	Pcs.
2f1616d2-348b-46d5-be6d-f9eedc97a904	c1	Cornitos Nachos Barbeque Mrp.35	Food	Pcs.
39b97537-4168-4090-9d92-9b6edc216ad0	c1	Cornitos Peri Peri 150 Gm	Food	Pcs.
06159e91-4a2c-4c8f-8cbf-01a1e173eb6c	c1	Cornitos Peri Peri 60 Gm	Food	Pcs.
806b53a8-9e00-4e78-995f-047154e3474d	c1	Cornitos Peri Peri Nachos Mrp.90	Food	Pcs.
5a07b82c-aec0-485b-ac5f-0f86e20a3dc0	c1	Cornitos Sizzling Jalapeno 60 Gm	Food	Pcs.
4133f9b3-e35c-4fd0-b579-a1e8471ae351	c1	Cornitos SIZZLIN JALAPENO NACHOS 200 Gm Mrp.120	Namkeen	Pcs.
88a02d82-1115-4838-a4e1-ace5ce883ba4	c1	Cornitos Sweet Chilly Nachos Mrp.35	Food	Pcs.
babe0b1a-c28d-4691-9273-b8ef94999796	c1	Cornitos Sweet Chilly Nachos Mrp.90	Food	Pcs.
05e840f4-e196-4471-a12b-825bf277494e	c1	Cornitos Tach Shells 4 inch	Food	Pcs.
72edb463-c5a1-45b3-b9f4-efdf0f8e372e	c1	Cornitos Tikka Masala 60 Gm	Food	Pcs.
75f2eb88-48b9-47d0-a81f-ef108c1ea7f6	c1	Cornitos Tomato Mexicana 150 Gm	Food	Pcs.
d83a1d21-c248-469a-8416-d23287e6bcb1	c1	Corn Kernel (Uneeeked)425gm	Food	Pcs.
eb414239-12f9-432b-9946-e09e49b3da8e	c1	Corn Snack 68gm.	Food	Pcs.
e37a0da1-c86d-4417-acf1-fd7ecd7c77c3	c1	Corn StarchYoka Brand	Food	Pcs.
8bf8fe26-b416-4b99-affc-d97618007833	c1	CORN WAFERS JAR	GURU FOOD	Pcs.
ab8095a7-61ad-4d54-b3ae-24103cbb7806	c1	Cous Cous	Food	Pcs.
3ebb7fae-45a9-42a6-b8c0-8d05c47786cd	c1	Cranberry Juice (Imp)	Food	Pcs.
e605f708-c961-4a64-9ab3-60a3469209e5	c1	CRANBERRY PATTI 300g	Food	Pcs.
f7c6bf07-9107-48c0-b5de-63cc10fb4c36	c1	Cravova 12% Classic Cold Coffee 200 Ml	Food	Pcs.
15c2e0de-932d-4d17-b5c2-bed21fd0a32f	c1	Cravova 12% Frappe Cold Coffee 200 Ml	Food	Pcs.
fbe50be7-ed9b-4abb-92bb-1435ecd54d7c	c1	Cravova 12% Hazelnut Cold Coffee 200 Ml	Food	Pcs.
8d57d66e-c4a1-420b-8f2b-9aaf43dfbf09	c1	Cravova 12% Mocha Cold Coffee 200 Ml	Food	Pcs.
749409db-9b6b-4710-9518-df4cda2fb23e	c1	Cravova Classic Mojito 300 Ml	Drinks	Pcs.
35b4fb78-2b33-4212-8cad-67209d339d49	c1	Cravova Coffee Bottle Stand	Food	Pcs.
37e45aab-3148-4c31-b820-54dbfbadd4bc	c1	Cravova Fresh Lemonade 300 Ml	Drinks	Pcs.
eac18677-f216-41e5-be90-b85a22ee1b4f	c1	Cravova Green Apple Mojito 300 Ml 12%	Drinks	Pcs.
30c1911d-ec66-4bac-8d44-892d670c0576	c1	Cravova Kiwi Mojito 300 Ml	Drinks	Pcs.
8f291019-2996-42c2-b525-cc6889b7ebba	c1	Cravova Orange Mojito 300 Ml	Drinks	Pcs.
a5644003-366d-48a3-bd15-7f29477c51ce	c1	Cravova P 3 Ply Table Top 12 P	Food	Pcs.
2e117864-d72d-45f0-98f8-e5a5d142be95	c1	Cravova P Cheese Pizza Peanut 40 Gm	Food	Pcs.
f834c81d-07de-4e8b-8bc9-742bae387287	c1	Cravova Peach Mojito 300 Ml	Drinks	Pcs.
b184ccfd-5ea6-47d4-a529-207a09ea8c5d	c1	Cravova P Pani Puri Peanuts 40 Gm	Food	Pcs.
c0864cf8-02dd-44c6-bcc6-9e444b999563	c1	Cravova P Peri Peri Peanuts 40 Gm	Food	Pcs.
9b9e1704-58b5-4e48-aa86-da84596dc12f	c1	Cravova P Sizzling Tandoori Peanuts 40 Gm	Food	Pcs.
7644a5e1-831b-4f0e-9e92-e4bafa2f0cab	c1	Cravova P Smoky Barbeque Peanuts 40 Gm	Food	Pcs.
44d2249c-09b7-4940-b0f8-c73b2d6713e4	c1	Cravova P Smoky Mozzarella Peanuts 40 Gm	Food	Pcs.
fc90a477-f9cc-43df-9daa-725c3bf3f13e	c1	Cravova Watermelon Mojito 300 Ml	Equal	Pcs.
19adea43-4148-49f2-aedb-a44f877f625a	c1	Cravova Wire Hangers	Food	Pcs.
20a44834-aa00-440c-82bb-71092a99961f	c1	Cravova Wooden Bottle Stand	Food	Pcs.
5e5e8e9e-5044-41d1-a6fb-5a141b9c3453	c1	Cream Corn Kernel 425gm	Food	Pcs.
e23ca296-41a2-42ee-9ad8-4c26348b23ad	c1	Cream with ABM (Balsmic Glaze) (6*0.25)	Food	Pcs.
0783c9f4-e25d-43ff-a952-acfb501581c5	c1	Creme Muffing Veg Vanilla	Food	Pcs.
1d716bef-55b8-4234-824e-71eaa5edd33a	c1	Cremica Strawberry Crush 1025kg 1L	Drinks	Pcs.
d0b3cf59-7321-43e4-a350-bf499b487ded	c1	Crispy Waffle Mix	Food	Pcs.
e600a198-8313-4b05-aece-058743296244	c1	Crm21Allday Cream 150ml.Rs.189/-	Cosmatics	Pcs.
e309aa7a-24a1-4a73-a5cb-574969a6e11a	c1	CRM21All Day Cream 50ml. Rs.95	Cosmatics	Pcs.
4a798544-7e02-47b1-a5af-9ed9c011f5ee	c1	CRM21 Body Milk Dry Skin 250ml.Rs.249/-	Cosmatics	Pcs.
09379c99-5623-42cd-a664-b2a2a0894ee2	c1	CRM21 Moisturizing Cream 150ml.Rs.199/-	Cosmatics	Pcs.
60dc47e7-2987-4a35-9c8f-bb29ca3b384c	c1	CRM21 Moisturizing Cream 50ml. Rs.99/-	Cosmatics	Pcs.
5df3db7b-1247-4a94-83aa-d5c55b5720ee	c1	Crush	Food	Pcs.
f0edd369-e9ab-4e5f-9f65-8d3f460effb5	c1	CRYSTAL FETA 200 GM	&#4; Primary	Pcs.
be751ddd-1cd4-44ff-a96f-f229cda2fcd3	c1	Cumin Squash	GURU FOOD	Pcs.
d39f56e5-a53d-44d2-a3c5-1e8bfbf2e847	c1	Curry Paste Green 1kg.	Food	Pcs.
85236ed1-17c5-4be6-a9a3-c2bddc6cb31f	c1	Curry  Paste Red 1kg,	Food	Pcs.
f86e963c-6e39-4d22-946c-bee49d29ac2b	c1	Cuzifest Brand Rice Cooking Seasoning 750ml	Food	Pcs.
208c5f08-79c8-4061-acae-b7f869883dd8	c1	Cuzifest Gourmet Cooking Shao Hsing Seasoning 640ml	Food	Pcs.
5ef4bace-7282-4dc7-a4cf-d4e81e465752	c1	CUZIFEST PEEL TOMATO  2.5KG	Food	Pcs.
fccd3067-d121-404e-9174-80b407f25bd4	c1	CUZIFEST THAI HOM MALI JASMIN RICE	Food	Pcs.
ad2b499b-ac5b-4bc8-a2c2-93ea0f361d8e	c1	Dabour Honey 1kg	Food	Pcs.
28309d44-fe14-41b2-adc1-5e351c971885	c1	Daftarry&quot; Blasto Premium Pinapple  Wafer Stick 775g	Chocolate	Pcs.
c1534904-eec7-4efd-81a4-79ba9554bf3c	c1	Daftary&quot;blasto Premium Chocolate Wafer 775g	Biscuts	Pcs.
77f32a42-b996-4786-8fae-0a2634b34d70	c1	Daftary&quot;blasto Premium Cigarku Choco  Wafer Roll	Chocolate	Pcs.
3086dc11-585f-4d85-876c-9510c625af6e	c1	Daftary&quot;blasto Primum Cigarku Wafer Roll 375g	Chocolate	Pcs.
4918a9e7-3037-4753-a5ed-4cd260041dd3	c1	Daftary&quot;jelly Beans Surprise 30pcs Jar	Confationery	jar
fb24e999-eb88-47b0-b572-5078733a8587	c1	Daftary&quot; Kiddos Toyo 30pcs Jar	Confationery	jar
f82d1f27-acf6-420b-8f3f-1150a80685bb	c1	Daftary&quot;kids Party 30pcs Jar	Confationery	jar
40f849f4-c03a-442e-b58a-d7b0aafc3ca2	c1	Daftary&quot; Stone Candy Surprise 30pcs Jar	Confationery	jar
7576d9b9-964b-4a74-93f0-40622c801a3d	c1	Daftery&quot; Blasto Premium Chocolate Wafer Sticks 350g	Biscuts	Pcs.
8e480a57-ac72-44ce-9aed-91bcc22db02d	c1	Daily Dairy Edam Portions 210	Food	Pcs.
80eab677-f8a5-4ae2-b8ab-b81e9b7ec70e	c1	Dark Soya Souce 795g Smiki Suprior	Drinks	Pcs.
7e750a21-e352-4ea3-88b3-c89350a88670	c1	Dates Patti 300g	GURU FOOD	Pcs.
2f2f955c-5bd8-4975-bf56-e06191d86639	c1	Dates Syrup	Food	Pcs.
85cd620e-6dae-4010-8933-28c8d3392d90	c1	Date Syrup	Drinks	Pcs.
99d068aa-83d3-4c32-9820-a19ec5f54c60	c1	Davidoff Assorted Coffee Powder	TEA	Pcs.
f683a0b8-2157-4b73-8a0a-9ec184b4d82b	c1	Davidoff Cafe Crema 90 Gm	Food	Pcs.
8673f366-96d8-4fed-b05e-3c580579ca25	c1	Davidoff Cafe Espresso 100gm	TEA	Pcs.
697eca41-f2f6-4c71-99f3-afcdfd5c7475	c1	Davidoff Cafe Fine Aroma 100gm	TEA	Pcs.
1efff44b-76c9-4dd0-b3f7-faf456a70abb	c1	Davidoff Caff Rich Aroma 100g	TEA	Pcs.
899e529a-878b-4026-bb6c-15a8e6505665	c1	DAVIDOFF COFFEE	TEA	Pcs.
4e3c49a5-7680-4d36-ae77-4108436a40e4	c1	Dc Fajita Dinner Kit Wt Hi Nsik488gms	Food	Pcs.
bbece66c-33c6-4bec-9bf7-348cad9e15a3	c1	DC Nacho Burhanpuri 60g.	Namkeen	Pcs.
af1af11f-fa6c-4a8f-ae7b-0e5ab6afb485	c1	Dc Natcos Achari 60g.Rs.35/-	Namkeen	Pcs.
bd732158-8a4c-4631-a02f-c0e8b7c4e6bf	c1	Dc Salasa Nachos Clsc.Salted 150gms.	Namkeen	Pcs.
c0f59465-3bfe-4f03-9865-74927a1cd236	c1	Dc Salsa Dip 300gms	Food	Pcs.
51c68fea-1089-453c-95ac-748e124620a1	c1	Dc Salsa Tortilla Combi Chips 40gx3+Salsa Dip 75g	Food	Pcs.
13ed241a-9999-4ed8-b7b3-a918cba52d66	c1	Dctacco Souce Mild 283 Gms	Food	Pcs.
3042a503-1601-45a7-8a1b-35b02491d36c	c1	Dc Taco Dinner Kit 300gms.	Food	Pcs.
26a7b5de-fe10-42a6-a78a-2c4c5f5083be	c1	Dc Tortilla Chips Cheese 150gms.	Namkeen	Pcs.
82d811ee-009e-4af1-abe4-9aa298329993	c1	Dc Tortilla Chips Cheese 45gms	Namkeen	Pcs.
bcf7d426-eb8b-44ae-8135-a2e743a9cc2a	c1	Dc Tortilla Chips Chilli 150gms.	Namkeen	Pcs.
5fd93b8c-1908-4b0b-802a-12e09446b82b	c1	Dc Tortilla Chips Chilli 40gms.	Namkeen	Pcs.
eb2022dd-6bc0-4c70-ab2c-4a91a8085bde	c1	Dc Tortilla Chips Green Chilli 150gms	Namkeen	Pcs.
7a8451ec-a7f7-435b-bf3e-0b5750249f76	c1	Dc Tortilla Chips Green Chilli 45gms	Namkeen	Pcs.
7579360b-be5d-46a7-b201-fca73a9cae4c	c1	Dc Tortilla Chips Jalapeno 150gms.	Namkeen	Pcs.
19b3c377-7812-400a-ba2a-df004a6be8a9	c1	Dc Tortilla Chips Jalapeno 40gms.	Namkeen	Pcs.
23ee2cd1-aee8-43f2-b662-fcae8643946d	c1	Dc Tortilla Chips Sweet Salsa 150gms.	Namkeen	Pcs.
0bb937dc-57ee-4943-a0b3-21bb66652420	c1	Dc Tortilla Chips Sweet Salsa 45gms.	Namkeen	Pcs.
817eabdd-c06f-4b03-bc7c-c09c7df5e483	c1	Decaff Coffee Sachet (18%)	Food	Pcs.
4ae987f2-c83d-41bd-97b3-28df7a70dbc6	c1	Deeolight Moong Papad-200g	Papad	Pcs.
05ae1559-d126-4d18-b377-c9556b4816c6	c1	Deeplite Elaichi Soan Papdi -250g	Sohan Papadi	Pcs.
6867a8b4-5041-4fec-8488-33a43a8ba5ce	c1	Deeplite Elaichi Soan Papdi -500g	Sohan Papadi	Pcs.
bf597800-151d-4d53-b91f-6019ed21c169	c1	Deeplite Khakhra Cheezy Cheese-200g	Khakhara	Pcs.
5b17f9dd-d292-4144-846e-0bd34640ecad	c1	Deeplite Khakhra Cholafali -200g	Khakhara	Pcs.
d150fb79-03f8-4d02-b7fc-d2ba8dbd7d9d	c1	Deeplite Khakhra Classic Pani Puri -200g	Khakhara	Pcs.
32a63209-b2ba-416b-8be9-52e4920aa73b	c1	Deeplite Khakhra Jeera- 200g	Khakhara	Pcs.
8d9ff886-7c19-4de3-a035-6405a12c80ef	c1	Deeplite Khakhra Masala Munch -200g	Khakhara	Pcs.
180a82bd-a91e-485d-8395-d55e46ce9089	c1	Deeplite Khakhra Plain-200g	Khakhara	Pcs.
71fd763d-f38f-405a-ad1f-69e1a9f867ed	c1	Deeplite Khakhra Rich Methi -200g	Khakhara	Pcs.
b9cdd7e4-e85c-4739-bc90-01ca7ff44836	c1	Deeplite Khakhra Sahi Aachar-200g	Khakhara	Pcs.
51f4f9c8-ef44-4a31-89ee-4d08fb7bdd53	c1	Deeplite Lamp Oil Bottle-450ml	Lamp Oil	Pcs.
a0bb4ca8-6987-4b9d-87df-fea267f7a0f8	c1	Deeplite Lamp Oil Bottle-900ml	Lamp Oil	Pcs.
0e750c73-1c82-4365-9069-c1f064207520	c1	Deeplite Moong Papad 200g	Papad	Pcs.
cba20c6e-abc7-47dd-88c9-c39d1544b995	c1	Deeplite Udad Papad 200g	Papad	Pcs.
0b7a38e1-20eb-42c1-b08c-2538c1594d01	c1	Deeplite Udad Papad 30g	Papad	Pcs.
68a36de4-3b2d-43da-a8f7-31c7fe5da83e	c1	Deeplite Udad Papad 60g	Papad	Pcs.
416f59d5-b292-4891-b174-a9ee2c6b3b51	c1	Deka Wafer Roll Choco Banana 125gm	Food	Pcs.
c66020c3-e097-4157-a70b-1e5bbafc022f	c1	Deka Wafer Roll Choco Choco 125gm	Food	Pcs.
270bad3d-99ed-45e5-b986-7aebd60ebb59	c1	Deka Wafer Roll Choco Choco 360 Gm	Chocolate	Pcs.
f4643d63-3edf-4890-9012-de8527df3ac0	c1	Deka Wafer Roll Choco Choco 45gm	Food	Pcs.
e438d1ca-ac34-4d0c-b5fc-3d8c10304b13	c1	Deka Wafer Roll Chocon Nut 360 Gm	Chocolate	Pcs.
9b7cf7eb-d7bc-4a47-9d0e-b0822641067c	c1	Deka Wafer Roll Choco Nut 45gm	Food	Pcs.
da19df4f-06b8-409e-9f9d-ab3df90f0789	c1	Deka Water Roll Jumbo Dark Chocolate 16 Gm	Food	Pcs.
39788f85-efc8-46d8-a5f7-23026ebc458c	c1	Deka Water Roll Jumbo White Coffee 16 Gm	Food	Pcs.
7187fe1d-fa8e-4f83-b710-7abda8308063	c1	Delmonte Eggless Mayonease 1kg	Food	kg.
be609c36-aab2-4dff-ac2d-5e82566cff13	c1	DELMONTE FOOD CRAFT PIZZA PASTA SAUCE 1KG	Food	Pcs.
9159e177-3047-4b6e-900f-2c5bc75e081a	c1	Delmonte Fruit Cocktail 850 Gm (12%)	Food	Pcs.
c1473f89-0a01-42b7-bb91-cf153b32a891	c1	DEL MONTE PINEAPPLE SLICE 850GM	Food	Pcs.
b382b026-ab84-4554-84c7-0b419d4f7e40	c1	Delmonte Tk Sachet 8gm	Food	Pcs.
a03403d5-11f2-49c9-9463-1b0c5d579165	c1	Delmonte Tomato Ketchup Sachet	Food	Pcs.
bcd1bdc2-ab80-4e70-9962-7db35b7a3a8b	c1	Denali Choco Chips	Food	kg.
798b9f79-cdf6-446a-9e43-e0a5defd2d0e	c1	De Nigris Red Wine Vinegar 500 Ml	Food	Pcs.
ca374550-6af8-4557-aedf-a8ce6bcf46aa	c1	De Nigris White Wine Vinegar 500 Ml	Food	Pcs.
37d18028-7a71-4eb7-926a-aefbe23dd620	c1	DEO SFL Aspire 150ml.Rs.155/-	Cosmatics	Pcs.
b5fc9bbc-8c90-4275-a6cf-86cf2cc81c8d	c1	Deo SFL Desire 150ml.Rs.155/-	Cosmatics	Pcs.
61a02c44-a6c8-4997-b074-be489d582db4	c1	Deo SFL Inspire 150ml. Rs.155/-	Cosmatics	Pcs.
1fc52752-ee36-46f1-aa69-8fb4a35bcafb	c1	Desi Ghee Jaggery Jar	GURU FOOD	Pcs.
1a570779-c54d-427f-8faf-c1cf32c66228	c1	DICED MOZZARELL + CHEDDAR(DAIRY CRAFT 1K	Dairy Products	Pcs.
b91f8e07-64e8-42ee-9a73-51be2626ef2b	c1	DIET FOOD BREAD TOAST (CARDAMOM) 200GM.	GURU FOOD	Pcs.
c4000b68-ba91-4e4a-9d59-14cba56f7cd7	c1	DIET FOOD CHOCO BITES 150GM.	Biscuts	Pcs.
6ecd0731-701c-463d-aef7-ba667053c130	c1	Diet Food Corn Chips 150gms	Food	Pcs.
49f239fd-b1ea-4266-b8b3-25bad119042b	c1	Diet Food Healthy Snacks RAGI (Lacha) 200g	Food	jar
bea6e528-746d-4f0b-ab25-adc0e800e5ec	c1	Diet Food Millet Corn Sticks Masala Munch 65g	Food	Pcs.
2ce3a938-8428-4ac3-8c0d-de08d67ec657	c1	Diet Food Millet Corn Stick Tangy Tomato 65g	Food	Pcs.
42728262-0ebe-40eb-be76-0f4e76baf643	c1	DIET FOOD ORANGE BITES	Biscuts	Pcs.
c92dd5c9-0eb6-4ab4-a1d2-b2c616dd01e8	c1	DIET FOOD PINAPPLE BITES 150GM.	Biscuts	Pcs.
c1e7c1a0-99f8-4377-b101-a596125728ff	c1	Diet Food Piri Piri 150gms	Food	Pcs.
5fc8c4c9-baea-4cc7-afda-b46ae1d65aa3	c1	DIET FOOD ROASTED MILLET MIXTURE JAR 80G.	GURU FOOD	Pcs.
0db6424c-1d2e-4f12-829b-f8c117b83997	c1	DIET FOODS BREAD TOAST MULTI GRAIN 200GM.	Food	Pcs.
e9474856-3721-4020-95d8-32bca40812c5	c1	DIET FOODS BREAD TOAST S.FREE 200G.	Food	Pcs.
4ccedf75-b9f1-474f-8564-e3b134d3fe7b	c1	DIET FOODS COCKTAIL MILLET 100GM.	Namkeen	Pcs.
90d847f8-35d0-47ab-8577-a975b814e04b	c1	DIET FOODS FINGER MILLET MIXTURE (RAGI MIX)100GM	GURU FOOD	Pcs.
6099604d-3c26-4d62-8095-cbb3ec384c77	c1	DIET FOODS MILLET CORN STICKS 65GM	Namkeen	Pcs.
fd3569fe-a589-4732-8d5b-38910d1a8a34	c1	DIET FOOD SNACK	GURU FOOD	Pcs.
ca0aae8b-6154-4569-9e72-ce3a1545e923	c1	Diet Food Soya Chips 150gms	Food	Pcs.
858df86d-d638-4f4b-9e63-5e3b4b471caa	c1	Diet Food Soya Chips 65g	Food	Pcs.
79e075d0-7fbb-40de-ae82-5f9febe2281e	c1	Diet Food Soya Katori	Food	Pcs.
5e47e370-c2ef-4773-9c4d-4aca0b3f92e9	c1	Diet Food Soya Katori 110gm	Food	Pcs.
f86e8702-99ec-4059-8f37-5c6b83dbf27f	c1	Diet Food Soya Katori 50gms	Food	Pcs.
0e0d0651-7648-46a7-947d-2427e0f2a437	c1	DIET FOOD SOYA KATORI 65g	Food	Pcs.
a47b476f-8174-48ef-9f38-dbb6e45159b0	c1	Diet Food Soya Katori 85g	Food	Pcs.
44853468-9f0f-4a5a-a8ca-7cae55bbc9e4	c1	Diet Food Soya Katori (Mint Pudina )120gms	Food	Pcs.
ddd33d63-206b-40e7-a9f9-96ec6812da24	c1	Diet Food Soya Manchurian	Food	Pcs.
aa779ae1-c57e-40ac-ae8f-b22c7b378f53	c1	Diet Food Soya Stick 80gms	Food	Pcs.
5f1e4774-b3f3-40e7-84ab-a92342c2c119	c1	Diet Food Soya Sticks 150gms	Food	Pcs.
1584bc9c-de17-4c85-a73a-5ddbf7323552	c1	Diet Foods Paper Rice Chivda	Food	jar
01cfc5f3-b8c7-4349-8570-7e9b4c51fd8e	c1	DIET FOODS SOYA KATORI SALT &amp; PEPPER 110G.	Namkeen	Pcs.
bdf606a5-fec5-496a-b53d-af95b2509329	c1	DIET FOOD STRAWBERRY BITES 150GM	Biscuts	Pcs.
65f1c90d-9877-41e4-b12e-ecca1ed55276	c1	DIET FOOD WATER MELON NIBBELS 150M	Biscuts	Pcs.
bcacf633-7b94-4b9f-b018-f565882cf1c9	c1	DIJON MUSTARD COVINOR BRAND 370G	Food	Pcs.
bac3c749-2b6f-4187-bb2f-bcb622350bb9	c1	Dijon Mustard Granaducas 400gm	Food	Pcs.
fc6c5ee6-8659-4d7c-80c9-07f0b9481cfa	c1	DIJON MUSTARD OPTIMA BRAND 370G	Food	Pcs.
15c4c30e-277b-465e-b09a-94f2361f76c9	c1	Dipping Souce	Food	Pcs.
3f8c3cb0-d7be-4345-974a-212f6ff2e4a4	c1	Disano Aloe Vera Juice 500ml.	Drinks	btl.
30163456-2f68-458c-b69f-4f46ace45262	c1	Disano Aloe Vera Juice 500ml (Promo 1+1)	Drinks	Pcs.
f41f72c6-74c8-43e0-8f84-b1ef5c652c5c	c1	Disano American Chia Seeds 250 Gm	Food	Pcs.
62161502-9f50-4e36-9377-58b846725312	c1	Disano Amla Juice 500ml.	Drinks	btl.
d863e7f1-4467-467e-b3ed-cdb13df93a3b	c1	Disano Amla Juice 500ml.(Promo 1+1)	Drinks	Pcs.
99e599a7-34f7-4a14-9042-5df91a257c5c	c1	Disano Apple Cider Filltered 500ml.	Drinks	btl.
f319b2c1-7a0e-4b30-b587-b5c2128965a2	c1	Disano Apple Cider Vinegar Filtered 500ml.(Promo1+1	Universal  STOCK	Pcs.
7863934d-1794-4949-8db3-c465bff5d722	c1	Disano Apple Cider Vinegar with Mother 500ml  Promo	Food	Pcs.
ec4622d4-f6e9-419e-a32a-132ff4e75cc8	c1	Disano Apple Cider with Mother Vineger 500ml Promo	Drinks	Pcs.
025b1f5d-80c3-462e-89ec-b5104174f71c	c1	Disano California Almond Mildly Salted 250 Gm	Food	Pcs.
cb9e649d-27a7-419f-b6f7-348eb351a246	c1	Disano Californian Almonds 250 Gm	Food	Pcs.
2fd680de-6b5a-496d-a230-7ecef397fb36	c1	Disano Californian Dried Whole Cranb 200 Gm	Food	Pcs.
6eeed1fc-fac7-4218-8429-6923b00e498d	c1	Disano California Pistachio 200 Gm	Food	Pcs.
b0b3b709-5892-44a1-b260-be62dfb39992	c1	Disano Canola Oil (1ltr)	Oil	Pcs.
646d0331-a99d-4a06-90b2-e92261de98b5	c1	Disano Canola Oil 5 Ltr	Oil	Pcs.
3541a77b-ee5c-48ca-97fb-be4af37111ee	c1	Disano Cashew Nuts 200 Gm&apos;	Food	Pcs.
2d9aa6a2-d6c3-4834-aa62-015c56df573d	c1	Disano Choco Hazelnut Spread 13% 175 Gm	Chocolate	Pcs.
a2e7172d-263e-4ea8-8482-e5a479f2a743	c1	Disano Choco Hazelnut Spread 13% 300gm	Chocolate	Pcs.
55690b60-4247-4f8d-b871-264b005d909e	c1	Disano Choco Hazelnut Spread 45% 175 Gm	Chocolate	Pcs.
d45dc70a-88de-4c0e-acc8-80825bd75f67	c1	Disano Choco Spread 175 Gm	Chocolate	Pcs.
41fecf26-d784-4c73-bcfc-3cc1a45694b6	c1	Disano Choco Spread 300 Gm	Chocolate	Pcs.
711462ca-ad36-4bbc-ae3c-23056ca36d98	c1	Disano Coconut Milk 200 Ml	Drinks	Pcs.
72dc570d-2e48-4d83-8dc7-acfe4bca2c90	c1	Disano Cold Press Virgin Coconut Oil 1ltr	Oil	Pcs.
69f51da3-259b-4a93-92b5-273a85332089	c1	Disano Cold Press Virgin Coconut Oil 250 Ml	Universal  STOCK	Pcs.
7e9222ea-5a48-448a-af4b-39d09874b22f	c1	Disano Cold Press Virgin Coconut Oil 500ml	Universal  STOCK	Pcs.
d452f877-ed76-43ba-be96-3c16c2b63644	c1	Disano Cold Press Virgin Coconut Oil Glass 500 Ml	Oil	Pcs.
66db1949-2359-4192-a115-b52a3a889158	c1	Disano Desiccated Coconut Powder 500gm	Food	Pcs.
e4853e51-45a8-42fe-8a92-7f1246c25ec2	c1	DISANO ELBOW (PROMO)500G	Food	Pcs.
b6082cdd-d706-4d7f-9621-34a1358b9f7c	c1	DISANO EXTRA LIGHT FLV OILVE OIL 1 LTR 1425/-	Oil	Pcs.
653b9a3c-57f2-4bd2-bc7c-03c40078515f	c1	Disano Extra Light Flv Olive Oil 1ltr.	Oil	Pcs.
97841768-9f9d-4fea-8546-d6f380077a0b	c1	Disano Extra Light Flv Olive Oil 500ml *12 , 795/-	Universal  STOCK	Pcs.
b874ecad-9ec7-4257-ba12-b1c443a34228	c1	DISANO EXTRA LIGHT FLV OLIVE OIL 5 LTR	Universal  STOCK	Pcs.
09e6390d-e351-4379-a23e-4518af759061	c1	Disano Extra Light Fly Olive Oil (1ltr)	Oil	Pcs.
be15085b-5d39-4c87-ac25-43ae63d00fae	c1	Disano Extra Light Fly Olive Oil 1ltr (Pack of 2)	Oil	Pcs.
02ccda2b-1030-489a-9fb2-90395722fc2d	c1	Disano Extra Light Fly Olive Oil 500ml.	Universal  STOCK	Pcs.
4e68c6af-2f54-4cdd-a90f-419d6620b937	c1	Disano Extra Light Fly Olive Oil 500ml. 1+1	Universal  STOCK	Pcs.
ef1fabff-7034-4af2-9e79-33f92f36fbcd	c1	Disano Extra Vergin 500ml.Rs.550/-	Oil	Pcs.
78b2c756-9702-4cc4-8bca-4f68a08ba9a2	c1	Disano Extra Vergin Olive Oil.1 Ltr.	Oil	Pcs.
04855908-22b8-430f-98fa-4ff76d560c6a	c1	Disano Extra Vergin Olive Oil-500ml. Rs.465/-	Oil	Pcs.
f80784e7-e48e-497f-b68a-cf58de712843	c1	Disano Extra Vergin Olive Oil 500ml.Rs.495/-	Oil	Pcs.
21119b00-94b9-4669-a6dd-4896e2562067	c1	Disano Extra Vergin Olive Oil-500ml. Rs.675/-	Oil	Pcs.
2bb7c464-0a7a-4e34-8bff-5f4c45fe3d49	c1	Disano Extra Vergin Olive Oil 5 Ltr.	Oil	Pcs.
bb76b0ca-e2d5-4a1b-9b31-5bfcc0817edf	c1	Disano Extra Vergin Oliv Oil 5Ltr.Tin MRP.5995	Oil	Pcs.
8bf4e0fe-d576-43da-9144-a42fd5251fa5	c1	Disano Extra Virgin Oilve -1ltr 1+1	Universal  STOCK	Pcs.
87729a13-2d34-416a-b393-ce1d2269ce05	c1	Disano Extra Virgin Oilve Oil 500 Ml Mrp.845	Food	Pcs.
5ff7d6d1-fa8a-4a31-ab42-72746ec840f9	c1	DISANO EXTRA VIRGIN OLIVE OIL -1ltr	Universal  STOCK	Pcs.
b8c94066-3bd9-47a3-b5e3-f808c45ab0fa	c1	DISANO EXTRA VIRGIN OLIVE OIL 1 LTR 1425/-	Universal  STOCK	Pcs.
d6cd62ee-4659-47f5-a363-5d3bce72d0ed	c1	Disano Extra Virgin Olive Oil 1 Ltr Mrp.1695	Universal  STOCK	Pcs.
ab190a70-7edd-45ee-b052-2016e0892a3e	c1	Disano Extra Virgin Olive Oil 1ltr (Pack of 2)	Oil	Pcs.
d053d7eb-3558-455d-8b58-2582f3c1101d	c1	Disano Extra Virgin Olive Oil 250ml	Oil	Pcs.
3b8f8bc2-f472-4bbd-a059-1847f42c9cf2	c1	Disano Extra Virgin Olive Oil 500g	Universal  STOCK	Pcs.
f91c2797-f160-4f48-9ab8-04d13175fd29	c1	Disano Extra Virgin Olive Oil 500ml 1+1	Universal  STOCK	Pcs.
395d170f-7fe9-45d9-a9be-0e9204cc6073	c1	Disano Extra Virgin Olive Oil 500 Ml*12 , 795/-	Oil	Pcs.
868f6e6e-6571-4a0d-ba3c-a76736ee3991	c1	Disano Extra Virgin Olive Oil 500ml (Pack of 2)	Oil	Pcs.
5c347776-9529-41e7-81c3-1f0ab358b7f2	c1	DISANO  EXTRA VIRGIN OLIVE OIL 5 LTR.	Universal  STOCK	Pcs.
c6dbd26f-2b09-4c3f-ba78-f0df2e852955	c1	Disano Fusilli 500g.	Food	Pcs.
b6ff5ac5-d835-4f69-ad87-54110e83c021	c1	Disano Fussilli (Promo)	Food	Pcs.
aa56ab4a-ec34-45e6-b2bc-9037e54dea6c	c1	Disano Honey 500gm*12 (50%Off) ,275	Food	Pcs.
cb76ca46-d61c-4c42-9191-7d6f5c7dc0c1	c1	Disano Karela Jamun Plus 500ml.	Drinks	btl.
b7011c24-06d5-44fb-a65d-ec997b197f4c	c1	Disano Karela Jamun Plus 500ml.(Promo 1+1)	Drinks	Pcs.
b98600a1-06b7-40e5-9af1-e43b713961b0	c1	Disano Naturally Brewed White Vinegar 500 Ml	Food	Pcs.
d03910ae-d70c-4707-a3ee-2e8a9d7b85f3	c1	Disano Oats 1kg + 400 Gm (New)	Food	Pcs.
dc6d56fa-9384-4d55-9492-95f55e23024c	c1	Disano Oats 1kg(BOGO 1+1).....	Food	Pcs.
8e0f7acc-74e1-4e96-ba52-87b0d6ef762b	c1	Disano Oats 1kg BOGOO 1+1	OATS	Pcs.
40179ccd-63b6-4095-a048-07948a98e5ea	c1	Disano Oats 500gm	Food	Pcs.
1a65186d-9895-49ee-a276-b4577f883875	c1	Disano Olive Oil Extra Vergin 500ml.Rs.675/-	Oil	Pcs.
12d03916-7009-4f64-8f9c-f71d296896cf	c1	Disano Olive Oil Extra Virgin 1 Ltr Mrp.1595	Oil	Pcs.
3f11d2ba-fc29-4f08-bafa-a2d53f68f4cf	c1	Disano Olive Oil Pomace 1 Ltr Mrp.995	Oil	Pcs.
4023b555-bb94-4990-8475-93786bee4034	c1	DISANO OLIVE OIL POMACE 1ltr (PACK OF 2)	Oil	Pcs.
19169bdd-7351-43ea-a92c-54b8536c014e	c1	Disano Olive Oil Pomace 500ml Mrp.495/-	Oil	Pcs.
9cbadb0e-e215-4806-89ec-762f71db8633	c1	DISANO OLIVE OIL POMACE 500ml(PACK OF 2)	Oil	Pcs.
f6463043-eee3-42f7-b61d-7b7358422d4d	c1	Disano Olive Oil Pomace 5ltr.	Oil	Pcs.
8b4178f1-c834-4f1c-827f-4958b32b9200	c1	DISANO OLIVE OIL POMACE 5LTR.TIN	Oil	Pcs.
36227c0d-4447-4d5a-8921-e7ab91f8c243	c1	Disano Olive Oil Pomace Oil 5ltr (PET) MRP.3995	Oil	Pcs.
6e5ed953-f4a8-4754-b145-e3c6d47078a3	c1	Disano Olive Oil Pomace Pet 5ltr Mrp.3995	Universal  STOCK	Pcs.
44fdd6ca-4ba6-4187-98c4-2f08db2b7cd6	c1	Disano Olive Oil Pure 1 Ltr Mrp.1250	Oil	Pcs.
d87fbb88-d3b4-40bf-9025-fc44da60022b	c1	Disano Olive Oil Pure 500ml. Mrp.675	Oil	Pcs.
53732410-f0e8-4c1b-8050-589fb1eefa84	c1	Disano Olive Pomace 1+1  1LTR-1395/-	Universal  STOCK	Pcs.
14c9160a-88d8-4ef3-ae7f-3d49025ce537	c1	Disano Olive Pomace 1Ltr-1395	Universal  STOCK	Pcs.
47be30df-c88d-4c7c-bad1-9e3ac67288a6	c1	Disano Olive Pomace Oil 1 Ltr  995/-	Universal  STOCK	Pcs.
349e3abd-cbf5-40a6-8b4c-e4874418a2b7	c1	Disano Olive Pomace Oil 1ltr Mrp 795	Universal  STOCK	Pcs.
562524f8-d8a5-4638-9ab9-04e0b7ed5454	c1	Disano Olive Pomace Oil-1ltr. Rs.575/-	Oil	Pcs.
5df34a06-db6c-48dc-96a0-1b86c3e4a8fc	c1	Disano Olive Pomace Oil-500ml. 495/-	Universal  STOCK	Pcs.
2485a077-ce04-4c7f-aa74-18b0d3fb02a9	c1	Disano Olive Pomace Oil -500ml. Rs.299/-	Oil	Pcs.
9160df8c-34f0-4dcc-a9d5-e1a0749e3295	c1	Disano Olive Pomace Oil 5 Ltr.Rs.2700/-	Oil	Pcs.
84d23a33-2c6c-4a30-a259-109f81baec54	c1	Disano Olives Pitted Black	Food	Pcs.
6ff0197a-8269-42ab-8174-b6a516116b8e	c1	Disano Olives Pitted Green	Universal  STOCK	Pcs.
ff825f75-9d49-4b0f-a948-602146f39323	c1	DISANO OLIVES SLICED BLACK 230G	Universal  STOCK	Pcs.
c4418613-11b7-4d2d-962b-8a5025591655	c1	Disano Olives Sliced Green 230g	Universal  STOCK	Pcs.
32bde998-2972-478d-bee1-50f2e7026386	c1	DISANO OLIVES SLICE GREEN 230G	Food	Pcs.
b30eea0a-7e80-4f00-bc0a-1496d12885f1	c1	DISANO Olives Stuffed Green 285G	Food	Pcs.
1115ab20-235d-4fcd-978f-daa13572744d	c1	Disano Panne Ragate 500g.	Food	Pcs.
59690241-c180-4df4-b6d4-4b8f4204d9ac	c1	Disano Pastalicious Elbows 500 Gm	Pasta	Pcs.
d40f6b4f-316d-40b0-9a2d-1a99343611c4	c1	Disano Pastalicious Farfalle 500g	Pasta	Pcs.
41fa133c-e612-4754-aa28-f17d4785ae09	c1	Disano Pastalicious Fusilli 500 Gm	Pasta	Pcs.
0cc22760-8323-4753-ab53-f369d01ca243	c1	Disano Pastalicious Mini Fusilli 350gm	Food	Pcs.
5a69807f-27c9-42f8-a596-9b181b89b8cb	c1	Disano Pastalicious Mini Penne 350gm	Food	Pcs.
8bb848ed-2cae-4614-991a-befaab813644	c1	Disano Pastalicious Penne 1 Kg	Food	Pcs.
bf0b9ea6-66a3-46b9-adf2-fe6ae2100c55	c1	Disano Pastalicious Penne 500 Gm	Pasta	Pcs.
48a39973-b196-46f1-9807-c8da3cc4025e	c1	Disano Pasta Sauce 300 Gm	Food	Pcs.
7589397f-1e33-498f-be75-d142f8ed30be	c1	Disano Peanut Butter Creamy 1kg Mrp.285	Food	Pcs.
c640cc5a-9fb5-4b1f-9649-ca1c4ed43732	c1	Disano Peanut Butter Creamy 350g	Food	Pcs.
520f4bde-af0e-475e-a2fd-480f225422a4	c1	DISANO PEANUT BUTTER CREAMY 924 GM	Food	Pcs.
6c787e51-395d-4095-ad8f-dd2d0e780d65	c1	Disano Peanut Butter Crunchy 1kg Mrp.425	Food	Pcs.
b3241d66-b522-40d3-ba4a-af9cc7d6ca0f	c1	Disano Peanut Butter Crunchy 350g	Food	Pcs.
e51cc287-4e41-4a57-ad6c-448339fc9f20	c1	DISANO PEANUT BUTTER CRUNCHY 924 GM	Food	Pcs.
d50cef0d-37db-4d7e-bf38-e4883c6c7b41	c1	Disano Penne Ragate (Promo)	Food	Pcs.
b8a3de08-3b5a-459e-907e-8dca9c6295dc	c1	DISANO POMACE OIL 1LTR.RS.675/-	Oil	Pcs.
68047f31-b1fe-486e-9344-a0f84e476c24	c1	Disano Pomace Olive 1+1 500ml	Universal  STOCK	Pcs.
a3a8dd38-5b56-486c-af9a-a28a1e4ad794	c1	DISANO POMACE Olive Oil.625/-	Oil	Pcs.
552f8a0d-5248-46e6-a8a6-fecf4e12cb21	c1	Disano Premium Raisins 250 Gm	Food	Pcs.
5fb30b63-ed26-47bf-bb07-c395e3b7070a	c1	Disano Pumpkin Seeds 250 Gm	Food	Pcs.
6758463f-49c6-4766-a8b4-91304f8639aa	c1	Disano Pure Honey 1kg (50% Off) Mrp.495	Food	Pcs.
3b18a2d6-8620-4bab-888f-5be90a5e84ef	c1	Disano Pure Honey 500 Gm	Food	Pcs.
d2adca7b-40f1-4704-a247-cf6e119c05b4	c1	Disano Pure Olive Oil 100ml Mrp.115	Oil	Pcs.
a0016a5f-e556-413c-b1cb-1f7467e88f73	c1	Disano Pure Olive Oil 1 Ltr. Mrp.1195	Oil	Pcs.
ca93678f-e9ed-4d1d-a1b0-0c7c1ecfb05b	c1	Disano Pure Olive Oil 1 Ltr.(Pack of 2)	Oil	Pcs.
e54a8d20-038e-4115-b914-12c60f21991e	c1	Disano Pure Olive Oil 1ltr.Rs.1065/-	Oil	Pcs.
eed6ba14-92f0-4925-8115-15e6441e1606	c1	Disano Pure Olive Oil 250ml. MRP.255	Oil	Pcs.
7c908cb9-9d4e-4e11-975e-d65c53ebce3f	c1	Disano Pure Olive Oil 500 Ml 1+1	Universal  STOCK	Pcs.
66ed18d5-791d-466c-8786-7b58a0d79234	c1	Disano Pure Olive Oil 5 Ltr. Tin	Oil	Pcs.
1dfb740a-73a4-4c7b-8cfb-cbcc5dab8675	c1	Disano Pure Oliv Oil-500ml.	Oil	Pcs.
4f715ab8-58bc-4aa1-beef-9541dbfebf6f	c1	Disano Pure Oliv Oil-500ml. Mrp. 795/-	Oil	Pcs.
baadc490-d9ac-4d19-b934-3dd16d752f0f	c1	Disano Roasted Vermicelli 425gm	Food	Pcs.
d870254f-f5ab-47df-8bae-b4e02e5c442f	c1	Disano Roasted Vermicelli 80gm	Food	Pcs.
951d86f7-40c5-4820-a49e-772a9fd40380	c1	Disano Spaghetti (Promo)	Food	Pcs.
c4ed1e37-5f83-4d3e-a8a3-5f352f95d5f0	c1	Disano Speghetti 500g.	Pasta	Pcs.
8f7547a2-e1ff-48cf-9f4f-95aa978f3287	c1	Disano Turkish Apricots 200 Gm	Food	Pcs.
93149b13-ce84-45f4-91fb-2257c9ebe836	c1	Disano Unsweetened Peanut Buter100% Natural Crunchy	Food	Pcs.
76e56361-a31d-4b68-9b09-82dc1ca56b11	c1	Disano Unsweetened Peanut Butter100% Natural Creamy	Food	Pcs.
84bdad10-c4af-49af-9bd6-3f5b24962632	c1	Disano Unswetend Peanut Butter 100% Natural Creamy	Food	Pcs.
5cb6865b-4553-42e9-9e1e-4237b867c4ba	c1	Disano Vermicelli 425gm	Food	Pcs.
1abab7fc-6856-4968-a492-61a443d50622	c1	Disano Vermicelli 85gm	Food	Pcs.
090ea040-0e73-4513-ad60-7eab68c83c46	c1	D Jelly 300 Gm (BBQ Jelly)	Food	Pcs.
54be50fb-13d8-462d-90ab-0ed2940da736	c1	D-LECTA Cream Cheese 1kg	Dairy Products	kg.
f8783346-39b8-4e7d-9ffa-2c6be19c3e7a	c1	Dolphin Jelly Nata De Coco Mix 125 GX6 CUP	Food	Pcs.
be1da572-7b8e-4d75-9a4a-87ca49400618	c1	Dolphin Jelly Nate De Coco Lychee 180gm.	Drinks	Pcs.
e8d3913d-0f78-45ba-b5fa-7606da6eef8b	c1	Dolphin Jelly Nate De Coco Mango 180gm	Drinks	Pcs.
e78131ae-c391-4668-aafc-32f8271aad7b	c1	Dolphin Jelly Nate De Coco Peach 180gm	Drinks	Pcs.
87f137da-72ad-4d35-9247-b37f3587d93d	c1	Dolphin Juice Nata De Coca Lychee 270ml.	Drinks	Pcs.
5234daa1-7d2f-4200-9dfe-df36d02909db	c1	Dolphin Juice Nata De Coco Mango 270ml.	Drinks	Pcs.
86cc0169-45ae-492e-8254-42f78cf45b0e	c1	Dolphin Juice Natade Coco Strawberry 270ml.	Drinks	Pcs.
bc6d3ac4-6101-4f13-aa9e-2611745516dc	c1	Dolphin Pudding 85g.	Drinks	Pcs.
58c6299c-3554-4add-9d27-611bdd447013	c1	Doritos Nachos	Food	Pcs.
fb6d13b9-6632-4a68-92b8-65820563db3f	c1	DORITOS SALSA DIP	Food	Pcs.
59245656-d08b-42c4-947d-d6abac535e0b	c1	Double Dragon Seasme Oil 630 Ml	Oil	Pcs.
e0ef5de0-be08-4922-9e5d-c488cd4ad250	c1	Double Pagoda Cooking W (Ht) Seasoning 640 Ml	Food	Pcs.
1c9d3718-de78-46fd-8bb1-23ea2a1ba823	c1	Double Tiger Bean Thread Noodles 500gm	Food	Pcs.
222f8738-6ae3-4057-b857-564a1891b7ed	c1	Double Tiger Glass Noodels 500g.	Food	Pcs.
ea4ab5c2-9be6-41b9-b5ba-50f0bbdc5c5f	c1	Double Tiger Glass Noodles 5%	Food	Pcs.
7c3b254c-0d1e-4250-99a4-741e76ae495e	c1	D* Premium Ham (Pork Meat) 454 Gm	Food	Pcs.
b1bdf72a-fbad-48e7-a29b-70ef9c5436a7	c1	Draft Honey 875 Gms	Food	Pcs.
919ddf85-fe60-4106-a3d2-39e1fa300fae	c1	Dragon Fruit Flav 300 MI Mrp.Rs.55/-	Drinks	btl.
722833b5-2e3d-4323-8a15-c4e9d9a6e3d4	c1	Dr.Daiz Digital Weighing Machine	Pathlogical Goods	Pcs.
35e016f3-7d6e-4104-9a4f-a6925cfdf58f	c1	Dr.Daiz Hot Water Bottle	Pathlogical Goods	Pcs.
bd348b9b-4256-4314-b5fd-6c3fcac75a47	c1	Dr.Daiz Thermameter	Pathlogical Goods	Pcs.
4430f769-1d06-41c1-afa2-6a96290c46ae	c1	Dr.Daiz Weighing Machine Manual	Pathlogical Goods	Pcs.
7f97be85-e651-4b50-bf90-ae1ed8629b4d	c1	Dried Black Fungs	Food	Pcs.
ca2ba6d7-67fd-433e-9ffa-a342221718ab	c1	Dried Black Fungus	Food	Pcs.
00e6516b-ba3e-47aa-b27d-c44af08a16e2	c1	Dried Fungus Noori Sheet 28 Gm (5%)	Food	Pcs.
3477e398-a140-4a46-8463-f565852dcc0a	c1	DRIED MUSHROOM (SHITAKE)	Food	kg.
e8d48875-6d10-41d6-83cf-4410191cc269	c1	Dry Ice	Drinks	Pcs.
ff8b1ec1-118f-4116-a866-c6035eec0def	c1	Dry YEAST 500 Gm (Imp)	Food	Pcs.
d8633834-be05-4f6c-8718-e139400c620b	c1	DU CB AA 2+2BL CUCKOO INR 145	Electrical Goods	Pcs.
75c99755-f60d-407c-874a-40b92e3edd84	c1	DU CB AA 2BL 76VENxINR	Electrical Goods	Pcs.
43d2046c-1965-457a-a66d-cd212deabe46	c1	DU CB AA4BL MRP 145	Electrical Goods	Pcs.
0df6793b-8b32-499b-a30d-45ab9a453ec4	c1	DU CB AA 6BL VENx190 INR 5+1	Electrical Goods	Pcs.
95694517-6e76-4ae1-bd2d-9e94dd3c9220	c1	DU CB AA 6BL VENx228 INR	Electrical Goods	Pcs.
b0cfd3d0-14fb-439a-9d35-8f3fcf70876e	c1	DU CB AAA 2+2 BL CUCKOO INR 145	Electrical Goods	Pcs.
1b57b7e7-eb0c-4b79-b141-cbb3363fa02d	c1	DU CB AAA 2BL 76 VENxINR	Electrical Goods	Pcs.
004b4145-2e7f-483e-a20e-7ed779e90404	c1	DU CB AAA 6BL VENx 190INR 5+1	Electrical Goods	Pcs.
7fdc66ca-27a8-4d60-be2f-9e39a432b726	c1	DU CB AAA 6BL VENx228/-	Electrical Goods	Pcs.
70d357be-5890-4650-b2bd-7b84fd48de53	c1	DU CB AAA HBDC BL (STRIP) MRP.200	Electrical Goods	Pcs.
2fe1f4bf-fe1c-4824-8f55-304f2a3d7d55	c1	DU CB AA HBDC BL(STRIP) MRP.200	Electrical Goods	Pcs.
c1bd687c-8161-4b93-9685-56bcd8debc3c	c1	DU CB AL 9V 2BCD RS.440/-	Electrical Goods	Pcs.
977d1681-06f1-48c2-abad-331da30bc643	c1	DU CB AL 9V BCD RS.250/-	Electrical Goods	Pcs.
86f84c3a-27a1-4132-b6de-e9fbc0dec03e	c1	DU CB AL AA2BCD RS.76/-	Electrical Goods	Pcs.
7c4aaebe-9151-405e-8b33-f4b336b6ac66	c1	DU CB AL AA 4BCD 130 INR	Electrical Goods	Pcs.
46c255af-0246-4e58-8cbd-94dbb1764626	c1	DU CB AL AA 6BCD RS.210/-	Electrical Goods	Pcs.
653655ce-ef3a-48e0-b770-a48ce8dbf8ff	c1	DU CB AL AAA 2BCD RS.70/-	Electrical Goods	Pcs.
e677629f-91dc-40ec-9a0f-f68f9309ea09	c1	DU CB AL AAA 6BCD RS.210/-	Electrical Goods	Pcs.
517a2e5c-9529-4e70-a63a-409ece00970f	c1	DU CB AL D 2BCD RS.370/-	Electrical Goods	Pcs.
6837f01b-c967-443c-bb53-f1a0e53fb117	c1	DU CB Lithium Coin Cell 1*200*5 CR2	Electrical Goods	Pcs.
b3caafaa-37bc-4865-b212-674e3604fc80	c1	Du Chhota Power Mrp.17	Electrical Goods	Pcs.
6db624b6-56d1-4604-87da-7a7cbac504d5	c1	Du Chota Power AAA Mrp.300/-	BATTERY	Pcs.
e1d511e4-0463-4550-af77-330afa60b2dc	c1	Du Chota Power AA  Mrp.300/-	BATTERY	Pcs.
affe60e6-69f8-446f-a416-1140bf1ad98c	c1	DU COIN LI 2032 2BL	Electrical Goods	Pcs.
8eade494-64d4-4f7c-a3b7-40e22f8f272a	c1	Du Cp Coin 2032	Electrical Goods	Pcs.
7f0bb612-ee7d-45ac-9f5f-02fed245bffe	c1	DU DL 2025 Coin Lion Battery Pack of 1 INR 90/-	Electrical Goods	Pcs.
49a203e0-4998-43f7-b1dc-6a1ed4dcc1e5	c1	DU DL 2032 Coin Lion Battery Pack of 1 INR 90/-	Electrical Goods	Pcs.
1ac84414-c1e7-4bea-9fdf-87362cfcaaf8	c1	Due Vittorie Balsmic Vinegar 500 Ml	Food	Pcs.
d6dfed4f-193c-4b87-9fc8-07426341e3a2	c1	DU HSDC Lithium Coin 2032 Mrp.40	Electrical Goods	Pcs.
452f7ae6-3b66-4c61-80b0-0470a24ffb94	c1	DU L1 HSDC 2032 PACK OF 5 MRP 250	BATTERY	Pcs.
442d7d60-d323-4364-857c-e14e6f75ca9e	c1	DU LED TORCH LIGHT 3AA	Electrical Goods	Pcs.
5e73d5a4-a445-4b96-94e2-e6b33cae74dd	c1	DU LION 10050 MAH - POWERBANK MRP.3999/-	Electrical Goods	Pcs.
40888586-bcab-430f-b188-438eb390e4c3	c1	DU LION 3350MAH- POWERBANK MRP.1999	Electrical Goods	Pcs.
78225f36-5756-4481-b917-75a14f6444e3	c1	DURACELL AAA CHOTTA POWER MRP.162	Electrical Goods	Pcs.
f3408562-b104-45e1-87d1-deb331a2350a	c1	Duracell Chotta Power AAA9+1	Electrical Goods	Pcs.
9474f41a-2487-407a-adea-6a035df5b96a	c1	DURACELL CP AAA RS.18/-	Electrical Goods	Pcs.
0c63785b-288e-4c5c-8c62-d8965d4beba0	c1	DURACELL CP AA RS.18/-	Electrical Goods	Pcs.
a0fb26ad-02b2-4844-b1fb-65234c004c5b	c1	Duracell -CR-2016	Electrical Goods	Pcs.
a49227f1-3d88-436c-9d1c-ed47864d6f61	c1	Duracell -CR-2025	Electrical Goods	Pcs.
2aa0b151-5305-43e9-be56-2768deee43d5	c1	Duracell MR Check Out Unit	Electrical Goods	Pcs.
472d81de-5e40-47f7-bacc-109b11c5d3d4	c1	Duracell Parasite 4 Peg	Electrical Goods	Pcs.
a6919394-c4b3-47e2-ac2d-1acca53e06a3	c1	DURACELL POWER BANK 20000 MAH	Electrical Goods	Pcs.
fe20d6d4-0334-4b2c-9cb5-127a21d74c75	c1	Duracell Tyep-C to Tpye-C Cable Mrp-399	Universal  STOCK	Pcs.
0befe0bd-b1a9-4f53-9491-0a62fb1cdf76	c1	Duracell USB-A to Type-C Cable Mrp-239	Universal  STOCK	Pcs.
3f618f28-8e55-4daf-a3a5-08c9a9f61851	c1	DURA CHARGER CEF14 1250/-	Drycell	Pcs.
7cd27e6d-0b63-4e8a-a11c-87ccdcf2f0d1	c1	DURA REC AAA4 4BL 750mah 650/-	Drycell	Pcs.
4109eaa8-5684-4731-865d-82e81445f4f0	c1	DU REC AA 1300 2 BL RS.325/-	Drycell	Pcs.
a036c7be-b084-4c81-9f7a-dfee77dd246d	c1	Du Rec AA 1300 4BL RS.599/-	Electrical Goods	Pcs.
25386977-dc70-4f30-a4f2-1430d7f83e2b	c1	DU REC AA 2500 2BL RS.650/-	Electrical Goods	Pcs.
be047f04-6349-4f42-b76d-b0b9e26da02f	c1	DU REC AA4 2500 4BL RS.1200/-	BATTERY	Pcs.
f83ac018-3ca9-4634-8c70-fa06347049d1	c1	DU REC AAA750 2BL Mrp.Rs.275/-	Drycell	Pcs.
8899df6f-f0d8-431b-a956-307d7fa6289e	c1	DU REC AAA750 4 BL RS.499/-	Electrical Goods	Pcs.
1dc0b3a8-117e-40dc-a2a2-353b9ab544e6	c1	DU REC AAA900 2BL RS.549/-	Electrical Goods	Pcs.
aa34644b-70e8-4e61-a318-e90df61ecc30	c1	DU REC AAA 900 4 BL RS.999/-	Electrical Goods	Pcs.
1427abb8-5ca3-4fa0-b358-b41730b08f8d	c1	DU REC CHRGR CEF14+2AA &amp; AAAMRP1499	Electrical Goods	Pcs.
d387f67c-de4b-4abf-b77a-4daeaeb5a274	c1	DU REC CHRGR CEF27+2AAA &amp;2 AA Mrp 2499/-	Electrical Goods	Pcs.
bfea6bcf-7d04-44e9-959e-46075a33a65c	c1	DU RECHARGABLE AA13002BL MRP.350/-	BATTERY	Pcs.
f1da5c23-7b89-4092-8cec-cc32b4395103	c1	DU RECHARGABLE AAA750 2BL 350/-	Drycell	Pcs.
63c16031-3568-4a8b-8dac-2a935d6632cd	c1	Du Ul 2ct LITHIUM CR 2032 Mrp.80/=	Drycell	Pcs.
5c3b72c4-d056-4130-a413-6f65017774d1	c1	DU UL 9V 1BL UPGRADE -	BATTERY	Pcs.
56914879-3dc2-4133-a839-5e0f2feca331	c1	DU UL 9V 2BL UPGRADE	BATTERY	Pcs.
e36fd741-c47c-4514-89b2-b2db369b5b59	c1	Du Ul AA 2BL 2x20x12 OLPP  Mrp.110	BATTERY	Pcs.
33d7ddb1-3e5a-4762-af8d-d5b4c674651a	c1	Du Ul AA 2 BL OLPP IN LE  Mrp.90	Drycell	Pcs.
b7518ba7-2476-4cfe-a2c7-b8c1ed6acd76	c1	DU UL  AA 2BL UPGRADE INR 84	Electrical Goods	Pcs.
74e4d1ca-364b-481f-a820-6924b1c1dbab	c1	DU UL AA 2BL VENx2X20 INR 100/-	BATTERY	Pcs.
4cbc22b2-1519-49eb-b026-c73d2eb57bcd	c1	DU UL AA 4BL 4*20*6 OLPP IN LE INR 190	Drycell	Pcs.
a641a74a-e4ed-4e3c-b35e-4c4fd6d379bc	c1	DU UL AA 4BL INR 160	Electrical Goods	Pcs.
82b19380-b3e3-4fc6-bb38-94861e31dc54	c1	DU UL AA 6BL 5+1 MRP.RS.225	Electrical Goods	Pcs.
49047745-62b0-4933-b9d4-25a4a0bebca0	c1	Du Ul AA 6 Bl 5+1 OLPP IN LE  210	Electrical Goods	Pcs.
d4bffbba-1280-4bf8-9e78-70f8a2a2a13b	c1	DU UL AA6BL 6X12X6 5+1 OLPP IN LE RS. 250	Electrical Goods	Pcs.
4b07f70e-042a-458c-b195-52580daff2c0	c1	DU UL AA 6BL OLPP IN LE 252	Electrical Goods	Pcs.
eff00c8a-3f30-44fb-ae9a-29ff6bfaea61	c1	Du Ul AA 6BL OLPP IN LE RS 300	Drycell	Pcs.
69f07b80-5217-4dcd-8a4d-f77d919eefaf	c1	DU UL AA 6BL UPGRADE INR 252	Electrical Goods	Pcs.
e151f05f-9d20-4215-a5f3-f43c1ca978b8	c1	DU UL AA 8BL 8*10*6 OLPP IN LE INR 350	Drycell	Pcs.
e715cb82-91e7-4f74-a48a-a77337c03bd1	c1	Du Ul AA8 TEAR PACK INR Mrp.440	BATTERY	Pcs.
ca362ad7-bef3-445b-8890-5ea0212cfcaf	c1	DU UL AAA 2BL 100 VENxINR 100/-	Electrical Goods	Pcs.
39fce011-df75-4aec-8267-bcbf0645aeaa	c1	Du Ul Aaa 2bl 2x20x18 Olpp in Mrp.100	BATTERY	Pcs.
de5fc407-0eef-4eb3-9e25-65b1aecf7d41	c1	Du Ul Aaa 2bl 2x20x18 Olpp in Mrp.110	Universal  STOCK	Pcs.
aa0ba3c0-18f4-4c62-a8cc-db94b3a497c2	c1	Du UL AAA2 Bl OLPP IN LE 90	Drycell	Pcs.
8a873a7d-a473-467f-b371-5431eecc0a3d	c1	DU UL AAA 2BL UPGRADE INR 84	Electrical Goods	Pcs.
151be712-397a-474a-b366-7a9721c9f975	c1	DU UL AAA 4BL 4*12*4 OLPP IN LE INR 210	BATTERY	Pcs.
d6121dcd-5ad4-474d-a62d-1b4790eb50e6	c1	DU UL AAA 6BL 5+1 MRP.RS.210/-	Electrical Goods	Pcs.
3f567176-f443-44c6-a0ce-5884976627fe	c1	DU UL AAA 6BL 5+1 MRP RS.225	Electrical Goods	Pcs.
48d41176-8f07-4473-9c73-0024880b917b	c1	DU UL AAA6BL 6X12X6 5+1 OLPP IN LE RS. 250	Electrical Goods	Pcs.
2b7aef5e-2a6e-47a5-878e-572037832bed	c1	DU UL AAA 6BL OLPP IN LE 252/-	Electrical Goods	Pcs.
9f6ac60b-1941-403d-8374-a6aec2296aad	c1	DU Ul AAA 6BL OLPP IN LE RS 300	Drycell	Pcs.
11014af0-ffe2-492b-94d0-8738318b9d3c	c1	DU UL AAA 6BL UPGRADE INR 252	Electrical Goods	Pcs.
45092ff1-b6c2-4cad-b4d2-7882abbe265e	c1	DU UL AAA 8BL 8*12*4 OLPP IN INR 350	Drycell	Pcs.
a54d0058-d91b-4d7d-8432-8d79500521cb	c1	DU UL AAA8 TEAR PACK  INR 400	Drycell	Pcs.
5c8dd92d-03e9-406c-8341-0b22f3dd7da9	c1	DU UL AAA8 TEAR PACK  INR 440	BATTERY	Pcs.
d55b0ce3-551f-4a6e-a498-e81dc3880fd9	c1	DU UL AL AA 2BCD RF RS.95/-	Electrical Goods	Pcs.
0f4b849b-edbd-43e1-8972-abc581eefe25	c1	DU UL AL AAA 2BCD	Electrical Goods	Pcs.
bac3430a-fd20-4622-8af0-2d1ead90ab4d	c1	DU UL C 2 BL 2X10X6 OLPP UP GRADE INR 325	BATTERY	Pcs.
5c678d7c-b461-4213-9d99-5498175ec6ff	c1	DU UL C2 BL UPGRADE INR 275/-	Drycell	Pcs.
f5e18cbb-305e-4f56-ad8a-9bf4227408e3	c1	Du Ul D2 Bl UPGRADE INR 400/-	Drycell	Pcs.
33670720-dd14-4704-bb74-78fbdd7cd8af	c1	Du Ul D2 Bl UPGRADE INR 450/	BATTERY	Pcs.
1fca3bab-4fec-406f-b91e-cb57f5ac9b66	c1	DVC  Fine Aroma 100gm	TEA	Pcs.
c701a15e-8cbb-4964-b0a8-fdf203974bce	c1	DVC IP Crema Intense 90gm	TEA	Pcs.
ec53a139-db62-48ad-be63-f1dbb849075b	c1	DVC IP Crema Intense 90gm 749mrp	TEA	Pcs.
0094b1e5-c115-4d8f-880d-ad4211597ef9	c1	DVC IP Espresso 57 100gm	TEA	Pcs.
46655eae-df07-4c21-a694-3564c5ebb8b8	c1	DVC IP Espresso 57 100grm 749mrp	TEA	Pcs.
4a4a6a13-9792-453d-aca4-74967d836cb1	c1	DVC IP Fine Aroma 100gm	TEA	Pcs.
0c6d8d64-7238-42c7-9778-a0236733c07b	c1	DVC IP Origins Asia 100gm 899 Mrp	TEA	Pcs.
80da988d-971a-4599-a902-9d3b71bb6749	c1	DVC IP Origins Brazil 100gm 899mrp	TEA	Pcs.
c50c3dc9-07a0-4664-a13e-d1e098294e72	c1	DVC IP Rich Aroma 100gm	TEA	Pcs.
02c1e198-f977-4fc3-a0a4-9a2ca4b4cca4	c1	DVC IP Rich Aroma  100 Gm Mrp749	TEA	Pcs.
b53cdeb1-a6f5-4fef-89d1-5dd612e29ee5	c1	DVC Origins Asia  100gm	TEA	Pcs.
37729cc5-1233-480d-8df3-0ea05c595c89	c1	DVC Origins Brazil 100gm	TEA	Pcs.
a399b36b-4de1-455a-98de-2af5c5533e49	c1	Edible Gelatine Sheet Gold Trade	Food	kg.
b16d3842-2749-4bbf-a236-6a0810071227	c1	Egg Free Chocolate Cake Mix	Food	Pcs.
8d9ebd94-4853-440b-ad58-6aac022d6cb7	c1	Egg Free Orange Velvet Cake Mix	Food	Pcs.
45d8a86b-1773-42d2-819c-bfbc9be73f09	c1	Egg Free Vanilla Cake Mix	Food	Pcs.
36f246f6-ba29-4f20-b875-a48d8154f7a0	c1	Eggless Moltan Lava 0407	Food	kg.
c8363c6b-d594-458e-9a56-0df3c6a0dea4	c1	Egg Noodle	Food	Pcs.
24e38832-4c23-4fca-aaa5-551be355ff8d	c1	ELMAC Kasundi Mustard 1 Kg	Food	Pcs.
b80453d1-a9d4-4a8c-af23-1c8919be5d79	c1	Entree Jalapeno Slice (12%)	Food	Pcs.
23a32db8-6f9a-43c9-8284-d72d3c0337e0	c1	Entree Red Paprika 720ml	Food	Pcs.
1576797b-0a68-4f2e-9a7e-c6cf49dd9503	c1	Epicurea Coconut Milk Lite 400ml.	Drinks	Pcs.
17df8eff-bd15-4fe6-aa3e-679f67c61a78	c1	Equal Oatmeal Cookies 75gm.	Biscuts	Pcs.
821d89c5-1557-4c47-bb97-37e4d41e8a66	c1	Equal Sach 100 Rs.120/-	Sugar Free	Pcs.
ab911690-c01c-4534-be07-cf8c4631c5d1	c1	Equal Sach 25 Rs.40/-	Sugar Free	Pcs.
2dac8a64-d96f-42c3-acd0-f71cadf4882a	c1	Equal Sach 50 Rs.75/-	Sugar Free	Pcs.
cbac8c47-b410-4213-ba30-e2635ce95f93	c1	Equal SF Butter Cookies 75gm.	Biscuts	Pcs.
e3684e47-15d8-4da9-b149-3b5bfc94e084	c1	Equal SF Casew Cookies 75gm.	Biscuts	Pcs.
d0e3049f-90cf-46a4-9739-24282709c0a3	c1	EQUALSF Choco Vanila Sanwich 75gm.	Biscuts	Pcs.
fbe454bb-2741-40af-8b03-96e95ff624b8	c1	Equal SF Multigrain Cookies 75gm.	Biscuts	Pcs.
72ac6a0e-a8db-4d33-bd90-1e201c0c48c4	c1	Equal SF Orange Cream Sandwich 75gm.	Biscuts	Pcs.
c1837f07-2016-44e6-a1ed-b44a3d5de518	c1	Equal Tab 100 Rs.70/-	Food	Pcs.
d9f1c6f3-eb2f-4f51-b5b0-1d89ee95a6be	c1	Equal Tab 300 Rs.165/-	Sugar Free	Pcs.
1f68dd76-18c6-41f2-bc8b-4770d7b9cc48	c1	Equal Tab 500 Refill Rs.200/-	Sugar Free	Pcs.
720e6207-cec0-4702-82bc-cb86d0791627	c1	Erawan Glutinous Rice Flour 1kg	Food	Pcs.
8796f0b5-c445-4f4a-a0fd-ccbf54c254fb	c1	ERAWAN GLUTINOUS RICE FLOUR 1 KGS	Food	Pcs.
0b2069ff-92be-4030-896a-81753779896b	c1	Erawan Rice Flour 1kg	Food	Pcs.
2b42004c-3975-4719-8b4b-eae22c2a3acd	c1	ESPRESSO COFFE FRAPPE MIX	Food	Pcs.
e327ec2e-c630-4668-ad48-b19c0b58cca9	c1	Eurial Goat Cheese Plain 125gm	Dairy Products	Pcs.
b13acb79-82ce-4c38-9268-e1ba4468e550	c1	Ever Delicious Danish Oat Cookies	Food	Pcs.
897203da-a1e8-46f6-a476-6477c8795714	c1	Eveready Cell 1050	BATTERY	Pcs.
4c9dea47-bc9e-4c64-a912-54bba6851e14	c1	Everest Amchur Powder 50g.	Spices	Pcs.
2b2d22e0-09ab-4033-9168-1255d0db3b11	c1	Everest Blackpepper 100 Gm	Spices	Pcs.
f82f1a0f-4bec-46ce-9c16-c08ff375e2f9	c1	Everest Chaat Masala 100 Gm	Spices	Pcs.
11316914-11b0-439f-a099-5b525491b127	c1	Everest Chhole Masala 100 Gm	Spices	Pcs.
450f06fe-9139-4167-b231-b14e2497a367	c1	Everest Coriander Pouch 100 Gm	Spices	Pcs.
be1e4789-510d-4c65-9641-3979b063b87b	c1	Everest Cumin Powder 100 Gm	Spices	Pcs.
66df41cd-685f-4710-93f9-fbab63567f5a	c1	Everest Dry Ginger 50g.	Spices	Pcs.
3f5cd246-6b73-48c6-9ef7-76d7891d331d	c1	Everest Garam Masala 50 Gm	Spices	Pcs.
76b4ee4f-6e9f-4e3a-8e00-fd32db48c191	c1	Everest Hing Yellow Powder 50 Gm	Spices	Pcs.
5b497e81-13ce-46f9-ab5c-92045103f66d	c1	Everest Jaljira Powder 100 Gm	Spices	Pcs.
40f45be3-6b54-42cf-9ae5-1f0708884a98	c1	Everest Kasmiri Lal 50g.	Spices	Pcs.
eac708a4-9386-4403-9cbc-4ddfc8e75d70	c1	Everest Kasuri Methi 25 Gm	Spices	Pcs.
77a43399-1e54-4721-980c-3d86416f1ddf	c1	Everest Kitchen King 100 Gm	Spices	Pcs.
5c4316f3-dfe2-4ab2-9fab-d82f4f2e0608	c1	Everest Kuti Lal 100g.	Spices	Pcs.
0a944faf-ba13-4f83-90ba-2f92d3796c63	c1	Everest Meat Masala 100 Gm&apos;	Spices	Pcs.
b30d5227-72e2-4a3e-a4e0-84b11c4bf5ed	c1	Everest Pav Bhaji Masala 100g.	Spices	Pcs.
4289c176-96df-4970-9616-1611e0a467f9	c1	Everest Royal Garam Masala 100 Gm	Spices	Pcs.
f26b9bb8-996e-4775-92ed-7eb8da717d0d	c1	Everest Sabji Masala Box 100 Gm	Spices	Pcs.
6729a132-e3e1-449e-b6ec-a269cfa406dd	c1	Everest Sambhar Masala 100g.	Spices	Pcs.
5b705345-43a6-49b6-bdac-1cac4551b1f7	c1	Everest Shahi Biryani 50 Gm	Spices	Pcs.
f9199762-325d-4fc4-b95c-4373e64f5a79	c1	Everest Shahi Paneer Box 100 Gm	Spices	Pcs.
2bc77c31-6504-4ad3-a2e1-4ad2da2791e5	c1	Everest Tikhalal Extra Hot 100 Gm	Spices	Pcs.
29f225f3-9510-4f19-9df2-ed66f284d7b9	c1	Everest Turmeric Pouch 200g.	Spices	Pcs.
70be134b-ddd5-4a98-b22b-9f4c5094779b	c1	Everyday Creamer Sachet 450gm	Food	Pcs.
635cd4ca-5f9f-4917-8a10-bddde0df2f7e	c1	EVIAN SPARKLING WATER 330ML.	Drinks	btl.
00d3ec65-9789-4030-8211-889bc4023314	c1	Evian Water 1000 Ml Mrp.250	Drinks	Pcs.
08869b86-9ea5-490e-a476-835029a8f7ad	c1	Evian Water 1.5 Ltr (18%)	Drinks	Pcs.
6b7a1752-49a1-4b4e-a2fc-609182e29848	c1	Evian Water 500 Ml	Drinks	Pcs.
ac57b732-42ad-441f-98ea-3bc7014ffef5	c1	Evian Water Sports Cap (18%)	Drinks	Pcs.
61e9d248-cbad-4aea-bb91-f34aff4ce967	c1	Excelencia Black Olive Slice 3kg	Food	Pcs.
720846a3-ebc2-4954-920c-7367b5890535	c1	Excelencia Black Pitted Olives	Food	btl.
b450482b-1d94-4d67-b9cb-27b36ed81c0f	c1	Explod Energy Drink 330ml.(Can)	Drinks	Pcs.
0480df6c-b5a6-424a-b705-a17c217df45b	c1	Explod Energy Drink 500ml.(Pet)	Drinks	Pcs.
b662cab4-b7fc-457b-985f-35fb98f34c27	c1	Extra Virgin Olive Oil Truffle Flavour Urbani 250 M	Food	Pcs.
b1b7822e-05c0-4ca1-8459-698768d4a763	c1	EXTRAVIRGIN OLIV OIL TRUFFLE FLAVOUR URBANI 250ML.	Oil	Pcs.
02b2eb15-2fa7-4187-b8a9-f700714bd3de	c1	Fabrice Softener Comfort 2 Ltr (18%)	Confationery	Pcs.
9458e258-06a2-4fbd-a463-a11f46288b32	c1	Face Shield	Cosmatics	Pcs.
e45070dd-5d29-4b42-875b-9c287d0b9692	c1	Family Farms Maple Syrup 236 Ml	Food	Pcs.
b5be5fb7-7d62-4ca8-af74-ff1c011830f6	c1	Fanta Grape	Drinks	CAN
68749ac0-bf76-4056-9571-4571be11f10b	c1	Fanta Lychee	Drinks	CAN
cf5a22a5-c7a7-4aa0-bd36-4a2fba4d2de6	c1	Fanta Orange 1.25 Ltr Pet	Drinks	Pcs.
019c7abc-d85f-4f6a-946c-6b83e0cc217e	c1	Fanta Strawberry	Drinks	CAN
db00d207-adb1-45c2-9bae-b5be39681cc2	c1	Farfalle Spigadoro 500g.	Food	Pcs.
aa00ea87-9f50-4915-9df2-614768591241	c1	FARINA PASTA FLOUR 1kg (POLSELI)	Food	Pcs.
1ea78434-38a4-4383-a464-7d59fa53094e	c1	FARINA Pizza Flour 1kg	Food	Pcs.
6f56b0b2-9425-427b-83a4-e3f6a3db2d64	c1	FARINA PIZZERIA -25KG	Food	kg.
9a45eb55-9f4d-4ff1-b1f7-baaf7e97b52b	c1	Farm Dilight Makhana 200g	Farm Dilight	Pcs.
5c80ed02-c6cd-4bdc-8031-0d2a54c670d5	c1	Fc Italian Pizza Pasta Plus	Food	kg.
5cf6ef19-cad6-4882-8961-8d62f0227639	c1	Fc White Cheese Dressing	Food	kg.
3e4e366c-fdb9-4c70-8240-9438a5ea8445	c1	FENGLING BRAND PERSERVED BLACK 500	Food	Pcs.
7622fc34-993a-4f8e-ae22-58611ef4ea03	c1	Ferrero Collection T-15	Chocolate	Pcs.
c9ddfb63-8e5f-4d40-9e98-a4788ba2f48e	c1	Ferrero Rocher T-16	Chocolate	Pcs.
93833929-319d-4749-a695-12333b36b7bf	c1	Ferrero Rocher T-16 (5pcs)	Chocolate	Pcs.
4096c431-3e07-4de1-83d3-e12e2669153a	c1	Ferrero Rocher T16 Mrp.529	Food	Pcs.
431f77de-467e-4ffc-967f-1b4f71eed03c	c1	Ferrero Rocher T-24	Chocolate	Pcs.
e3fe71bf-77d4-4514-a2a5-efa64704471d	c1	Ferrero Rocher T3	Chocolate	Pcs.
daad29b0-cb3a-491b-ab11-41973a476eef	c1	FERRERO ROCHER T-4 50GM	Chocolate	Pcs.
45163536-d1e4-4704-b927-9145afc79b7b	c1	Ferrero T24	Food	Pcs.
76286eb8-fd73-47a7-9756-2c133dc1da08	c1	Ferro Rocher T-16	Chocolate	Pcs.
f0449d99-0147-45d7-9070-aa1c09b92529	c1	FF AD-L-XL	Sanatry Napkin	Pcs.
d80060e7-0245-4b41-a1af-07cc0be585d9	c1	FF AD Medium -10	Sanatry Napkin	Pcs.
964c34b7-35a7-4d6a-8a5f-03aea820dc84	c1	FF Barbecue Sauce 1kg	Food	Pcs.
88c34880-710f-44a2-8f30-a3af27abc91c	c1	Ff Caramel Sauce 1kg	Food	Pcs.
d14420b4-2631-49e3-8627-169a40229e06	c1	FF CHILLI GARLIC SAUCE 1 KG	Food	Pcs.
88057389-1730-465c-a4cc-f4af527c0b3e	c1	FF CHOCLATESYRUP 1KG	Food	Pcs.
8d8e02a7-8bda-4766-b2e3-e7a941d6386d	c1	FF Chocolate Flavour Syrup 1kg	Food	Pcs.
0f157493-f88b-47fe-93f0-7bb31d448072	c1	FFDC Hand Sanitizer 1 Ltr	Cosmatics	Pcs.
e3bfeb87-a918-4a99-962f-dadf96b95666	c1	FFDC Hand Sanitizer 5 Ltr	Cosmatics	Pcs.
18d31d48-025b-419c-8dda-1b4bcd4c80e0	c1	FF Dressing 1000 Island 1 Kg	Food	Pcs.
d4865a9b-c802-48c8-b101-91ec28b90771	c1	FF DRESSING SWEET ONION 1KG	Food	Pcs.
199cf1f1-d8c4-4210-a86f-c59932fa1084	c1	FF ENGLISH MUSTARD 1KG	Food	Pcs.
5a10d31a-f275-426c-b4b4-92f919a62dc1	c1	FF Italian Pasta &amp; Pizza Sauce 1kg.	Food	Pcs.
b34e059c-0eda-4538-b006-fab5eccb192e	c1	FF Italian Style Cheese Blend 1 Kg	Food	Pcs.
9d869077-153f-4012-a5f4-42bafe298280	c1	FF Italian Style Pizza Topping 1kg.	Food	Pcs.
495905ca-6df8-48c6-b5b9-ce36848cfb3e	c1	FF Mango Chatni 950g	Food	Pcs.
ef153acc-68b1-43d9-ad3c-50abb46ae79d	c1	FF MAYONNISE GREEN MINT 1 KG	Food	Pcs.
f3fbaf9f-c57d-4cfc-aa94-1c685e06eb0c	c1	Ff Mix Cold Coffee 1kg	Food	Pcs.
dd184993-dd26-40d1-893f-b6a1fd9ca52a	c1	Ff Mix Milk Shake Vanilla 1 Kg	Food	Pcs.
edb14435-e1ee-45a4-a910-5987cb17f15d	c1	FF Sugar Syrup 1 Kg.	Food	Pcs.
ed838970-7a34-4235-b8df-6097aea6956f	c1	FF TOMATO KETCHUP 1.2kg	Food	Pcs.
8e9afa20-4816-4c2b-b1df-7ce030b551b0	c1	FF Tomato Ketchup Sachet Box 800g	Food	Pcs.
bbe3ac8b-6557-4650-89d4-10ea1f6a29b8	c1	Ff Topping Strawberry 300g	Food	Pcs.
082fa3db-1ead-4362-9a15-9a4303d7224f	c1	FF Under Pad 1x60 (Sampale)	Sanatry Napkin	Pcs.
b6284af6-6aff-420e-a378-cf75d29bfd19	c1	FF Veg Mayonnaise for Burger 1kg.	Food	Pcs.
e471e5b7-4e5e-4504-ac11-212d3f05f602	c1	Ff  Veg Mayonnaise Garlic 1kg	Food	Pcs.
4183bf96-16f1-4b2b-8e91-484d23ea14d2	c1	FF VEG MAYONNAISE TANDOORI 1 KG	Food	Pcs.
88396366-5f2f-4f55-b01a-b9b560119c6f	c1	FF Veg Mayonnise for Coleslaw 1 Kg	Food	Pcs.
3b63884b-6ddc-49c9-8610-227fad48b6ce	c1	FF VEG MAYO RICH &amp; CREAMY 1 KG	Food	Pcs.
0110804a-bb09-4b28-8c84-25c851417eeb	c1	FF VEG SANDWICH SPREAD CUCUMBER 1 KG	Food	Pcs.
513ec28d-1faa-4e18-b5d8-2e53c45a3c60	c1	Fiama Sundried in Sunflwer Oil 290gm.	Food	Pcs.
853041c5-1902-45f7-98bc-8a4802f401e9	c1	Fiamma Arborio Rice 1 Kg	Food	Pcs.
6411aabe-13c5-4d25-b6a4-ce798886ff54	c1	FIAMMA DURUM WHEAT PASTAE (FUSILLI) 24*500GM	Pasta	Pcs.
6b946c7f-f14e-4d00-9cf6-611065600c3d	c1	FIAMMA DURUM WHEAT PASTA(PENNE RIGATE)24*500GM	Pasta	Pcs.
9b8651dc-7d93-442d-b3ff-7bdd59aa0fab	c1	FIAMMA FARFALLE PASTA 500G.	Food	Pcs.
bdd22504-dea4-4dda-b8eb-805b13759d32	c1	Fiamma Lasagne Sfoglia 500 Gm	Food	Pcs.
b10ee009-d76b-42f9-b763-26d9de5cc02d	c1	Fiamma Nidi Tagliatele 500 Gm	Food	Pcs.
93f7cdfa-4203-4516-be5e-80cecf05bb81	c1	Fiamma Peel Tomato 2.55kg	Food	Pcs.
d80e956f-1589-489c-93e1-da6cfd018bff	c1	Fiamma Spaghetti Pasta 500gm	Food	Pcs.
503c6617-273a-478a-8ad5-8b74a84cce93	c1	Fiamma Whole Peeled Tomatoes 2.5kg	Food	Pcs.
abba76ad-36db-44b3-87fd-7bb2cc018836	c1	Figaro Artichoke Hearts 390 Gm	Food	Pcs.
4f52874e-11ba-4fc7-a0a8-f2e581fc6b3b	c1	Figaro Black Olive Sliced 450 Gm	Food	Pcs.
f70cdf0f-6778-4d12-bec1-5a1155898244	c1	Figaro Black Olives Pitted 420g.	Food	Pcs.
ee0525ae-9107-4b43-8bcf-0e8357c3c034	c1	Figaro Black Olives Plain 450g.	Food	Pcs.
1292d624-1be9-46d6-8afb-5752ce83f7f0	c1	Figaro Black Olives Sliced 450g.	Food	Pcs.
6103868f-1444-40fa-8cea-afbc655ddfc0	c1	Figaro Capers Capottes 100 Gm	Food	Pcs.
f4f11816-a0b8-482a-b45c-6428d193f9e2	c1	Figaro Green Olives Pitted 420G.	Food	Pcs.
195204cf-3daa-4d16-a967-fa13e62433ef	c1	Figaro Green Olives Plain 450g.	Food	Pcs.
fed10380-d884-49e5-9757-470ec75b34dd	c1	Figaro Green Olives Sliced 450g	Food	Pcs.
a435adbd-a166-45e5-a65e-6b38e17246c8	c1	Figaro Green Olives Stuffed 450g.	Food	Pcs.
b99cfcbd-0351-43ee-9571-3f5bb33172df	c1	Figaro Green Peppercorn 100 Gm	Food	Pcs.
85d591ff-f419-4abe-923b-5e57423faf99	c1	Figaro Kalamata Olives 340 Gm	Food	Pcs.
4e79ef7a-f4ff-4ac0-87b9-dd8557e82532	c1	Figaro Peri Peri 100gm	Food	Pcs.
bcf38d28-6fc8-410e-a7f7-5da29d301815	c1	Figaro Pink Peppercorns 100 Gm	Food	Pcs.
b272ce46-fd28-404c-b5f4-69e38e5a72cc	c1	Figaro Sundried Tomato in Oil 200 Gm	Food	Pcs.
7f663ac6-a091-4b3e-9e60-610309398e8a	c1	Filipo Pestro	Food	Pcs.
d8b69af6-05d2-4f13-9f08-0250bc2727f3	c1	FINGER MILLET(RAGI) MIXTURE JAR 80GM	GURU FOOD	jar
251e6c5f-574f-444c-bed4-010cc211d884	c1	First Choice Bamboo Mat Green	Food	Pcs.
118f1858-ac65-4895-aafc-e5e49c51db1b	c1	First Choice Bamboo Shoot 552gm	Food	Pcs.
7f77a54c-33b3-4856-a4a1-584111ab0e39	c1	FIRST CHOICE JALAPENO SLICE 3KG	Food	Pcs.
7dad72ba-935b-4157-bdbc-53945052e36c	c1	First Choice Maraschino Cherries with Stem	Food	Pcs.
802db1bd-88bd-4957-9b14-8b7b48f0c25d	c1	Five Spice Seasoning Powder 65gm.	Spices	Pcs.
43ba6986-b10e-4bfa-80ff-03a4081aace8	c1	Flavour Enhancer Aromatic 100ml.	Food	Pcs.
b0cbd16d-e8d8-4c80-8564-a9f8ab05cfbb	c1	FLEXI CREME DELIGHT	Drinks	Pcs.
8bfa7091-8d8d-4914-abaa-84f81ca166ae	c1	FLEXI CREME GOLD	Drinks	Pcs.
716e9e76-cf36-4a48-b05f-a208522823fd	c1	Flilipo Pesto Green Sauce	Food	Pcs.
6738f3e0-c968-4332-a60c-7a76cad4d273	c1	FLOUR PIZZERIA BLUE  25kg	Food	Pcs.
b4c17ba5-a2b2-4821-93df-115f6d894081	c1	FOCO  Coconut Milk Drink 330ml	Drinks	Pcs.
6ccb4ea1-7142-498a-a469-22321f45c428	c1	FOCO CW Chocolate 330ml	Drinks	Pcs.
a2438d00-cff4-4fca-8b38-294f4f3d092c	c1	FOCO CW Coffee Latte 330ml	Drinks	Pcs.
4322774c-c840-49af-ad56-728a5ef31928	c1	FOCO CW  Lychee 330ml.	Drinks	Pcs.
485637c2-375a-4aad-9d04-099c9b1d0ec6	c1	FOCO CW  Mango 330ml.	Drinks	Pcs.
931fd790-0f45-4be4-9f47-411b72d2505d	c1	FOCO CW Orignal 330ml.	Drinks	Pcs.
d303816e-e00f-4851-8243-72bb673dffed	c1	FOCO CW  Pineapple 330ml.	Drinks	Pcs.
369e950d-21bc-4163-96bd-64e2fe34168b	c1	Foco Cw Pink Guava 330ml.	Drinks	Pcs.
ef8dc6b5-aab4-4c2b-86ab-256e3d5554cc	c1	FOCO CW  Pomegranate 330ml.	Drinks	Pcs.
f8a9dedc-45ff-4dc2-af87-14e17a943782	c1	Fog Machine	Electrical Goods	Pcs.
836ce32d-b568-4cb9-a6e6-899251d2f795	c1	FOODCAOST TOMATO KATCHUP  8gm	Food	Pcs.
35c7732b-e71d-4162-b75e-efad72c162e3	c1	FOODCOAST ITALIAN PIZZA PASTA 1KG	Food	Pcs.
18f6bf80-1f2a-4b92-9fd1-1773670a8b43	c1	FOOD COAST PLUS CHEESY SAUCE 1KG	Food	Pcs.
5c26e654-cb8e-4c19-a5c0-a69299bb45e5	c1	FOODCOAST PLUS MAYONNAISE 1KG	Food	Pcs.
330828fe-8e68-4ff2-9674-27b1862d8ef9	c1	Fox &apos;s 90g.	Food	Pcs.
c9e67836-611a-4610-99ef-48f55cfa5538	c1	Fox&apos;s Berries Bag 90 Gm	Food	Pcs.
ae798776-5c64-4c7d-a958-574a3e17bb53	c1	Fox&apos;s Fruity Mint Bag 90 Gm	Food	Pcs.
6604837e-7d04-4559-883a-cae19a46ba34	c1	Fox Candy Bag - Fruit 125 Gm	Food	Pcs.
532ff7fc-1495-46a3-840c-92f962b1ddb5	c1	FOX Fruit Pouch 125gm.1x24	Confationery	Pcs.
6224c5f8-9805-4213-aad6-f5ecf22b5c82	c1	Fox Pouch (12%)	Food	Pcs.
e6614b2b-2161-423c-a701-5d5812896383	c1	FOXTAIL FUSION JAR	GURU FOOD	jar
e4fb3b0c-33ad-4e24-8672-3e1f629cfb8d	c1	Fox Tin	Food	Pcs.
b90bc0f5-9dab-4b8d-b026-6ef57f8309fd	c1	Fox Tin (12%)	Food	Pcs.
01cf6f3c-bf14-4d62-bb94-da229107077a	c1	Fox Tin 180g.	Food	Pcs.
092b5bf9-4c9a-4ef9-9764-786afe28dc04	c1	FP Fisher Price Baby Wipes30&apos;s Rs.49/-	Sanatry Napkin	Pcs.
bc5831a0-7bb6-47c0-9c1f-0618c1709534	c1	FP Fisher Price Baby Wipes 80&apos;s Rs.99/-	Sanatry Napkin	Pcs.
de97869b-2e0b-49e9-9eb3-0d168b31d321	c1	Fragata Olives Black Sliced 3kg	Food	Pcs.
8deb574d-cef6-4c01-95e7-348951f4be82	c1	Fragata Pomace Olive Oil 5ltr.Tin	Oil	Pcs.
945a636d-6238-4223-8e12-ff05511e5bb8	c1	Frappe Powder	Food	Pcs.
0a7f9a71-a066-4659-8c0b-b98e2f9db552	c1	FR Cookies Butter 135gm.	Biscuts	Pcs.
bb795e61-2b8a-4019-b870-088dea432313	c1	FR Cookies Chocolate 135gm.	Biscuts	Pcs.
c87bca85-e15d-4b03-ac67-604d71896ed9	c1	FR Cookies Cranberry 135gm.	Biscuts	Pcs.
753ca26c-9d2b-4ebc-9dc0-8b6c47d4dfe9	c1	FR Cookies Hazelnut 135gm.	Biscuts	Pcs.
7652b089-44c0-4268-b606-c6986cdc4ad1	c1	FREE DEEPLITE PAPAD 200G	Papad	Pcs.
3f2be45d-3114-4052-b589-2298880ee79f	c1	French&apos;s Yellow Mustard 226 Gm	Food	Pcs.
e653f804-2e35-4e4a-8f66-8d42a0cdc3d8	c1	French Fries 6mm	Food	Pcs.
8c7abac3-37a6-4493-a88c-1f8f70d20126	c1	French Fries 9 MM (12%)	Food	Pcs.
dfbdb587-ad44-4494-919c-166fd940bcb6	c1	French Fries Premium 6MM	Food	Pcs.
76b5a90a-cabb-4cf4-b4a5-0ce2dbf1bd51	c1	French Mustard&apos;	Food	Pcs.
3fcc38cc-f72d-4269-8ae1-47020550f408	c1	French Vanilla Frappe Mix	Food	Pcs.
3c62996e-d4df-4a15-a1d2-f2b3ba5d9d35	c1	Fresh Deo Hero	Cosmatics	Pcs.
b1200d61-18f0-49a2-bd4e-985d3e616e01	c1	Fresh Deo Macho (Blue)	Cosmatics	Pcs.
7fd18e4c-b30d-411a-902e-b73e17b10da0	c1	Fresher Sparkling Apple Drink 250 Ml	Drinks	Pcs.
19b7fa4d-1cd0-460a-8482-686dd73ffdb6	c1	Fresher Sparkling Lemon 250 Ml	Drinks	Pcs.
28f25933-b69b-4059-be84-cf1ea8d975ae	c1	Fresher Sparkling Lemon Mint 200 Ml	Drinks	Pcs.
aa977925-35bf-49e5-bb72-f488bd4360fc	c1	Fresher Sparkling Mandarin 250 Ml	Drinks	Pcs.
9135e9b7-9817-4959-94a0-f609c8b8e868	c1	Fresher Sparkling Mojito 250 Ml	Drinks	Pcs.
3ea330d8-c04c-42bf-8fdb-6e9626ed3fa5	c1	Fresher Sparkling Watermelon 250 Ml	Drinks	Pcs.
7ce83c25-1335-438d-be5c-e5f788f9ef6c	c1	Freshos Artichoke Hearts 390gm.	Food	Pcs.
22a45ff2-6be8-48da-bb0e-114dfbf94a2a	c1	FRESHOS Bamboo Shoot 565 Gm	Food	Pcs.
2cd24453-c9d8-4a73-a89a-dc7a6e17ba63	c1	FRESHOS Cocktail Onion 480 Gm	Food	Pcs.
6232b6bb-0093-4d43-b0f7-b55686e79609	c1	Freshos Cocktail Onion 500 Gm	Food	Pcs.
812b4705-f2f4-4b63-ac7c-306b1c46b122	c1	Freshos Cous Cous	Food	Pcs.
fb6283a2-ade4-40df-bacc-205920cd947d	c1	FRESHOS Dijon Mustard 370 Gm	Food	Pcs.
3bc3e2e5-1277-4547-a282-e622be286e31	c1	Freshos Polenta 1kg (0%)	Food	Pcs.
2299e002-06cc-4e5a-988d-07d8843c33ec	c1	Freshos Potato Flakes 1 Kg	Food	Pcs.
a427c40d-550f-4ab7-b43b-53bdea5aea5e	c1	Freshos Seasme Oil 500 Ml (5%)	Food	Pcs.
e9914b47-2dbd-43fc-8570-298739815cbc	c1	FRESHOS Sundried Tomato in Oil 200 Gm	Food	Pcs.
f4946614-de45-4557-96cd-3c09f653d648	c1	FRESHOS Water Chestnut in Water 567 Gm	Food	Pcs.
54430b70-711c-40f2-8369-b6a7e5285d3b	c1	Fresh Smile Water Chestnut 567g	Food	Pcs.
3c66462b-fd28-4b6c-8474-b56d2821f157	c1	(Fresh to Go)Tortila Wrap Whole Wheat 348gm Mrp.169	Food	Pcs.
81382516-7bfc-462e-8114-d2b987f2ce13	c1	(Fresh to Go) Tortilla Wrap 348 Gm Mrp.225	Food	Pcs.
0edcffc0-c905-4d74-ac09-289138357c2d	c1	(Fresh to Go) Tortilla Wrap 480G	Food	Pcs.
0a95b490-adc4-4780-9471-be706e08df28	c1	(Fresh to Go)Tortilla Wrap Multigrain 348gm Mrp.179	Food	Pcs.
9aa56ecb-f263-4c3d-a4fa-caeb5721f2da	c1	Fresh Tortilla Wrap 8.5&quot;inch 48 Gm*	Food	Pcs.
b1c01b98-8354-4adc-b3d4-19e08de9b7e1	c1	Frozen Green Peas 200 Gm	Food	Pcs.
37bc76a6-da8e-428b-beca-89eaf2e40e2c	c1	Frozen Sweet Corn (1kg)	Food	Pcs.
6da16b5b-0553-4c6f-8d4d-6f809caec70d	c1	FROZEN SWEET CORN 1 KGS	Food	Pcs.
1a7a49ca-0d51-41f8-9b88-32ab687ee5b0	c1	Frozen Sweet Corn 200 Gm	Food	Pcs.
4e1af9f3-cbb4-427a-b0b6-3cc368fc2e94	c1	Frozen Sweet Corn (500 Gm)	Food	Pcs.
9a7c57ea-ff42-45af-8590-847768d1ec11	c1	Fr T16	Food	Pcs.
6323172c-06b5-4e27-8fac-63ef264ade64	c1	Fr T16 (Imp)	Food	Pcs.
61d9a26e-af8d-4b71-b091-4cdd46202637	c1	FR T24	Chocolate	Pcs.
23733328-857b-4d77-9e37-0688ccc16122	c1	Fruit Cake 200g	GURU FOOD	Pcs.
29aa8108-ac1f-42dd-afa1-20ff5025f156	c1	Fruit Shoot-300ml.Apple and Pear	Drinks	Pcs.
861c57e6-8794-4de7-b95a-a8792fa020a6	c1	Fruit Shoot-300ml.Apple and Pear Mrp.Rs.60/-	Drinks	Pcs.
b2fa2586-777d-4c73-a52d-793371bb24f3	c1	Fruit Shoot-300ml. Apple Blueberry	Drinks	Pcs.
ec785ff7-119e-4e02-b350-c703fd3c9ba8	c1	Fruit Shoot 300ml.Apple Blueberry Free	Drinks	Pcs.
b3412b33-78f4-44b2-87cd-ad5b52e204e8	c1	Fruit Shoot-300ml.Apple Blueberry Mrp.Rs.60/-	Drinks	Pcs.
b273436a-9355-435c-a89b-fe31df5904ae	c1	Fruit Shoot 300ml.Apple &amp; Pear Free	Drinks	Pcs.
477e3962-498e-4e61-a039-dfcd3b931406	c1	Fruit Shoot-300ml.Mango	Drinks	Pcs.
c4f26a25-dd60-4e98-88e2-ee134ea3e6a4	c1	Fruit Shoot-300ml.Mango Mrp.Rs60/-	Drinks	Pcs.
68d2c27f-a767-474b-ad99-933d292d9713	c1	Fruit Shoot-300ml.Strawberry and Rasberry	Drinks	Pcs.
a33c6618-913c-41a0-ac9c-2cf07681d229	c1	Fruit Shoot 300ml Strawberry and Rasberry Free	Drinks	Pcs.
072b2675-7a28-4ac0-997f-40008900a9f2	c1	Fruit Shoot-300ml.Strawberry and Rasberry Mrp.Rs.60	Drinks	Pcs.
e262fbd3-5aa7-4271-86c7-229b9c59f284	c1	Fruit Shoot Diwali Festive Assorted Pack of 4	Drinks	Pcs.
940cec00-326b-421f-baba-9167a85116a5	c1	Fruit Shoot Mango 300ml.Free	Drinks	Pcs.
1a42a01a-7fb3-4407-9733-42bd77193ef4	c1	Fruit Wave 300ml.	Drinks	Pcs.
e854fcb9-f940-4c81-bcfc-6c2ce8846501	c1	Fruit Wave -300ml. Orange Lime Mrp.Rs.40/-	Drinks	Pcs.
118551b1-6477-4859-9d57-a92e3f04cc0f	c1	Fruit Wave Pineapple Strawberry 300ml.	Drinks	Pcs.
5661d482-23d2-4262-a735-0b6fdcb8fa7c	c1	FS PACK CHILLY FLAKES VIVA ITALIA 1kg	Food	Pcs.
ae1e2b8b-c5d4-45ab-baf6-75b34d391439	c1	Fs Pack Chilly Flex 1 Kg	Food	Pcs.
1133da7a-7d63-4b53-befe-cbbde9ddfaee	c1	FS PACK OREGANO REGULAR 1kg	Food	Pcs.
02aacc5e-cc72-4c86-9d39-23a4d673e8a3	c1	FS PACK PIZZA SPICE MIX 1kg	Food	Pcs.
cfb6abe2-f23c-4825-a6f8-cffe278eecbd	c1	FT PIZZA CHEESE 200 GM	Food	Pcs.
5ef12f53-06c3-4e73-ae10-68731455e59a	c1	Fudgy Brownie Mix Veg	Food	Pcs.
9abdac0c-e6ef-4cfb-a784-31c52533b0b2	c1	Fun Food Cheese Blend 1kg	Dairy Products	Pcs.
9ca87a03-6369-4475-84a1-b7673f5231d0	c1	Funfood Ketchup Sachet Dispenser (800 Gm)	Food	Pcs.
d59aab75-de28-432e-9261-70690c9578f3	c1	Fusion A.S.Balm	Cosmatics	Pcs.
20198956-66aa-4d4d-acd3-a05001b3b59e	c1	Fusion A/s Balm Cl Skn	Cosmatics	Pcs.
185d8be1-e111-42aa-949a-63439f45be12	c1	Fusion Crtg.2x1	Cosmatics	Pcs.
2f46fa26-88c5-47de-b251-69db7cef241b	c1	Fusion Crtg.4x1	Cosmatics	Pcs.
4aa5ce8d-79ae-4fac-9104-34c256663ff9	c1	Fusion Crtg.8x1	Cosmatics	Pcs.
38db355e-34b5-4527-b5ff-be6929eac1de	c1	Fusion Gel 70z Mrp.Rs.275/-	Cosmatics	Pcs.
dffeddf3-10b7-48c2-809e-a3a5d26db3a9	c1	Fusion Hyd.Gel Cir Sk	Cosmatics	Pcs.
d9b6ebae-36f5-4cff-8e38-49d06afd66cf	c1	Fusion Hyd.Gel.Cl.Skn 3.4oz.	Cosmatics	Pcs.
9cb6b5b5-a142-41f1-9605-131b627ea14f	c1	Fusion Hyd.Gel Frs.	Cosmatics	Pcs.
ad600da3-e2d0-4f0f-929b-34207a1e454b	c1	Fusion Hyd.Gel Mat.	Cosmatics	Pcs.
cd0734f7-d9cd-4e50-ad4d-fd854c2d12c5	c1	Fusion Hyd Gel Sen	Cosmatics	Pcs.
0504c904-dc94-4ec8-993b-23a5738597e2	c1	Fusion Power Crtg.2x1	Cosmatics	Pcs.
d1bcf6c8-1aef-446b-bf36-efda38fcfe8d	c1	Fusion Power Razor	Cosmatics	Pcs.
05d051f2-6fe3-498d-9126-65b7d5fdaa40	c1	Fusion Proglde PWR CRT 4 RS.1099/-	Cosmatics	Pcs.
1aa91750-d42f-420d-9962-eb0d1da38701	c1	Fusion Proglide PWR CRT 4	Cosmatics	Pcs.
4dd14c73-596b-4c8d-9ea3-0272392242ed	c1	Fusion Proglide RZR TMR	Cosmatics	Pcs.
95be5cbd-cce3-4e0d-8d65-666dd6673050	c1	Fusion Proglid MNL Crt.1x4	Cosmatics	Pcs.
5759f383-fe6b-4263-8a89-e608cc3f34cb	c1	Fusion Razor	Cosmatics	Pcs.
226ef9f0-6a26-45d0-abc9-a0407b12f5a1	c1	Fus.Proglide MNL Crtx2+1MNL Tzr Free	Cosmatics	Pcs.
b7bdc2fb-19b4-49b5-b3a2-1d19c5ba1caf	c1	FUS Proglide PWR RZR TMR RS.599/-	Cosmatics	Pcs.
734c2075-c808-4c8d-a97d-0df5a897bfc4	c1	Fus.Proglide Pwr Styler Rzr	Cosmatics	Pcs.
393c4ddf-5a95-4eab-8e5d-b9cea52f4a64	c1	FXLO-12XL5L-B BATTERY	Electrical Goods	Pcs.
7acb61aa-7894-4b36-88ff-fcc75a22f017	c1	GB PRB SUPERIOR LIGHT SOYA SAUCE 500ML	Food	Pcs.
da109450-e60b-40d0-a16c-bb53fbb3b57b	c1	Gc Aluminium Foil 1 Kg	Packing Material	Pcs.
be892b5e-c6ce-42ee-b5f3-ec57b59dda3a	c1	GC BREAD CRUMB 1 KG	Food	Pcs.
f4080395-6ca2-4870-b3ad-e100e792ed45	c1	GC Button Mushroom in Brine 800 Gm	Food	Pcs.
c8013649-00e4-4c3b-b461-5524e6fcbd61	c1	GC Button Mushroom in Brine (Tandoori) 800 Gm	Golden Crown	Pcs.
4775bf30-8d86-4cf2-b34d-61a50a1afc1b	c1	Gc Button Mushroom Premium800gr	&#4; Primary	CAN
992ce83c-a852-4f89-8124-945b54378c60	c1	Gc Button Mushroom Slice	&#4; Primary	CAN
a115179c-dc18-4f7e-8568-7733bac5fdfc	c1	Gc Custard Powder 1kg	Food	Pcs.
01ea737a-ade7-42eb-b1c2-3b011b70af7c	c1	GC- Kewra Water 500 ML	Food	Pcs.
ce71c5ea-39e7-4bc3-9068-83126883207b	c1	Gc Lime Juice Cordial 700ml	JUICE	Pcs.
0e1cd498-5676-486f-b2a0-9eb83ce9123b	c1	GC- Mango Pulp (Totapuri) 3.1kg	Food	Pcs.
9380bb72-7e15-4629-b415-47b20dfcad34	c1	GC MUSTARD KASUNDHI 1KG.	Food	Pcs.
2577707d-9333-468b-ac09-d8023a03b62b	c1	GC Pineapple Slice 850 Gm	Golden Crown	Pcs.
69d540d2-da2f-4466-b8f5-b19ee5d252a7	c1	GC PRB Premium Oyester Flavour Sauce 510 Ml	Food	Pcs.
b522db97-7efa-4993-a21c-7f4e7ab68e77	c1	GC PRB Premium Oyester Sauce 510 Ml	Food	Pcs.
357fd732-1daf-4c2b-b4d4-24fc7d222bbb	c1	GC PRB SUPERIOR DARK SOYA SAUCE 500ML	Food	Pcs.
667d8651-6e89-40f9-8cb1-7e7b80ce5693	c1	GC- Red Peprika Slice 3kg	Food	Pcs.
de3b327d-8fce-4543-b08b-4b8405e1e61a	c1	GC- Rose Water 500 ML	Food	Pcs.
06ab481b-6241-4055-b529-782030adeed8	c1	Gc Sarso Ka Sag 450gm	Food	Pcs.
2289c7a6-a608-4d4b-b528-c3ae7284a436	c1	GC Sweet Corn Kernel in Brine 430 Gm	Food	Pcs.
85500abf-0da8-456a-b3b7-dd3fe0a62daf	c1	GC- Sweet Corn Kernel in Syrup 1.25 Kg Retort	Food	Pcs.
ae1e83ab-e4a8-472a-a55a-e9c05d49fe30	c1	Gc Tomato Ketchup 1.2kg	Food	Pcs.
fe805c1d-1984-4230-b82e-54da3b549444	c1	Gc Tooth Piks	Confationery	Pcs.
5ca9aefc-6dcc-4329-ad3b-24ca797343fb	c1	GC- Veg Matsaman Curry Paste 1kg	Food	Pcs.
295a93b5-4f1d-45fb-9041-5b3e1111f49e	c1	GC- Veg Red Curry Paste 1 Kg	Food	Pcs.
d8ce4b1f-ac8f-41f7-82cf-187b7975734b	c1	GELATINE LEAVES GOLD /EWALD/1KG.	TEA FLAVOURED	Pcs.
7877cdb0-2ea3-490d-a9b8-2e9a74c34a61	c1	Gemma Black Olive Pitted 450g	Food	Pcs.
a5fd5a3b-ab64-4589-962a-947d3a7d49bb	c1	Gemma Black Olive Slice A-10	Food	Pcs.
1e970bac-f299-4bcc-bacd-9b441db88553	c1	Gemma Black Olives Sliced-3kg	Food	Pcs.
df6fb222-9ae4-476d-9927-df3e77a2710f	c1	Gemma Green Olive Slice	Food	Pcs.
bf438543-fbe9-40bc-9904-813d93e4a832	c1	Gemma Green Olives Pitted 450g	Food	Pcs.
299f3e72-611a-4b31-acf5-477ee43336a3	c1	GEMMA OLIVE OIL 1 LTR	Oil	Pcs.
d11bfb4f-085c-4348-b435-6ee9e8fd4b11	c1	GEMMA OLIVE OIL 5LTR	Oil	Pcs.
661583f8-542a-4a6c-867b-42fe5ddb17d7	c1	General Marchent	&#4; Primary	Pcs.
7ca3e652-6e6f-4514-a546-4ce65d8395d2	c1	German Mustard 190g.	Food	Pcs.
d233d7eb-3260-4b84-b5f7-0c1d5ae64eee	c1	Gil.3x Clear Gel AP 113gms Cool	Cosmatics	Pcs.
8bb6388f-bac9-4bd9-926d-045701f74524	c1	Gil.3x Clear Gel AP 113gms.Power	Cosmatics	Pcs.
17332f74-4907-4756-b7b0-1215f852f379	c1	Gil.3x Clear Gel AP 113gms Sports	Cosmatics	Pcs.
e88344a7-0e3c-46aa-b2bc-db7ffcb2ed66	c1	Gil.3x Clear Gel Cool 113g.Rs.165/-	Cosmatics	Pcs.
c0c68845-2868-47e1-8e68-51ec2c3a347c	c1	Gil.3x Clear Gel Sport 113g.Rs.165/-	Cosmatics	Pcs.
6c1b2fea-391b-4bbd-a4cd-4320743ab274	c1	Gil.3x Clear Power Gel 113g.Rs.165/-	Cosmatics	Pcs.
d9962aba-e3d9-48e7-b485-70f4973c70a3	c1	Gilett.3x Clear Gel AP 113g.Rs.149/-	Cosmatics	Pcs.
5edcc3c5-816e-4b58-a45e-63cd08d24511	c1	GILETTE FW/BW 473ML.	Cosmatics	Pcs.
a06b95f6-c376-4232-a8e2-35fbbf866ba5	c1	GILETTE SHAMP&amp;B/W 473ML	Cosmatics	Pcs.
15dc2b9f-6b67-45b5-b5f5-701c75c3913b	c1	Gill.Clear Gel Sport 113g.Rs.149/-	Cosmatics	Pcs.
5439147e-f01a-49dd-b7e2-6ff6deefb20f	c1	Gill.Clear Gel Wave 113g.Rs.165/	Cosmatics	Pcs.
1b66c012-996d-4fe6-b295-d34dd96544cc	c1	Gillette Venous Razor	Cosmatics	Pcs.
416b424e-8c8b-4f59-93a5-a567c42d32f5	c1	GilletteVenus Crtg(4x1)	Cosmatics	Pcs.
e00f2a1d-cd6a-47e6-a800-1474d0e81225	c1	GINGER GARLIC PICKLE	Food	Pcs.
94eefc16-f23a-4b73-951c-228dea64caf5	c1	Ginger Spront 160gm	Food	Pcs.
38e5a90c-ddd9-43d0-9038-b7386e806721	c1	GINGER VEGITABLE JAR 1.5KG.	Food	Pcs.
3b9b25d3-f481-44d1-8cb8-f44a5718dccd	c1	Giolly Extra Virgin Olive Oil 1 Ltr	Oil	Pcs.
92a30c79-6e03-4e99-b80e-f2c7b1f25fab	c1	Glass Noodels Vermicelli 500g	Food	Pcs.
6741a9eb-d2e4-4719-b185-d67e52926646	c1	Glass Noodle 200 Gm	Food	Pcs.
66bef5bb-5d1d-42da-a18f-c3a4985435ad	c1	Glass Noodle 500gm	Food	Pcs.
bac8c4ee-9f7e-490b-bada-7b2b7f381985	c1	Glass Noodle 80 Gm	Food	Pcs.
24e0634a-1b5f-4463-9bcf-a222e71a4665	c1	Glass Vermicelli (Double Tiger) 500gm	Food	Pcs.
076ea48d-e83a-4a8c-974e-1d89e057b227	c1	Glasur Blueberry Glaze 3kg	Food	Pcs.
1a9e36a7-ba41-4599-aebe-29ee7dc1e02c	c1	Glasur Chocolate Glaze 3kg	Food	Pcs.
0ba3d188-09ed-42a9-b231-06e46ff685a1	c1	Glasur Kiwi Cake Glaze 3kg	Food	Pcs.
9906bb96-5521-408a-a59c-40e69f52d01c	c1	Glasur Milky White Glaze 3kg	Food	Pcs.
359b68b2-c404-4963-86d4-4fdb20b23ecf	c1	Glasur Neutral Glaze 3kg	Food	Pcs.
3604618b-ef02-4d69-b9c2-f7d895c6fba5	c1	Glasur Orange Glaze 3kg	Food	Pcs.
a2251291-fdd2-471c-a543-ddb6dc1ea23e	c1	Glasur Pineapple Glaze 3kg	Food	Pcs.
176c101b-f8da-40d4-bff1-9993bcd9faa9	c1	Glasur Strawberry Glaze 3kg	Food	Pcs.
5f4cedcc-7d8c-4dc8-8e0b-8f3abcd1920d	c1	Glaze Sauce with Balsmic Vinegar 250 Ml	Food	Pcs.
0c192156-9624-4e88-9dfa-913c3f2be61a	c1	Gm Assorted Cereal (Reese&apos;s Puffs)	Food	Pcs.
c8b97b0c-bd73-4c3d-b006-8283456d4dcb	c1	Go Cheese High Melt 1kg	Food	Pcs.
44794c04-4f05-4bbc-902c-4211329fef4b	c1	Gochujang Hot Pepper Paste 500 Gm	Food	Pcs.
0b3158ad-bb01-4329-8234-7b2043d0d1ff	c1	Gochujang Korean Chilly Paste 500 Gm	Food	Pcs.
f82f7648-397c-4a17-bac1-8366448403e4	c1	Golden Crown 8 to 8 Sauce 290 Gm	Food	Pcs.
1be52bf6-5b8d-4ebe-9dc0-14d1211754bc	c1	Golden Crown Baby Corn 800gm 0%	Food	Pcs.
7ee25bd8-250d-434f-a82a-5558b806e7d8	c1	Golden Crown Baby Corn (Brine) 800g 0%	Golden Crown	Pcs.
3f3d9fd6-8288-441f-9b69-14906a7fa560	c1	Golden Crown Baby Corn in Brine 425 Gm (0%)	Food	Pcs.
895980bc-0f9b-4be7-808b-4acf632d4576	c1	Golden Crown Baby Corn in Brine 450 Gm	Food	Pcs.
5413ad55-986d-408b-bd73-19385df678ac	c1	Golden Crown Button Mushroom in Brine 800 Gm (0%)	Food	Pcs.
1aa578a2-9a93-4dde-9177-42e183d5e2cc	c1	Golden Crown Corn Floor 25*1kg	Food	Pcs.
206d330c-aa16-4376-9756-5814c4f9b729	c1	Golden Crown Fruit Cocktail in Syrup 850 Gm	Golden Crown	Pcs.
bcffaadd-9ba7-4d40-a2f7-fe042ba2bd22	c1	Golden Crown Lime Juice 250 Ml Mrp.63	Golden Crown	Pcs.
5ca0d998-495e-447d-8f0c-281de18bddb4	c1	Golden Crown Lychee in Syrup 850 Gm	Food	Pcs.
a7f6c9fb-ad7c-4c75-8fa0-c14ff5947a24	c1	Golden Crown Monosodium Gultamate 500 Gm	Golden Crown	Pcs.
cbbca594-d900-4ff7-ad57-9cd07b95ff7a	c1	Golden Crown Mustard Kasundi 1kg	Food	Pcs.
47901bc2-f000-4ad7-8e0a-6c1f967fa416	c1	Golden Crown Pineapple Slice in Syrup 840 Gm	Food	Pcs.
6ec40f82-683b-4a46-8d16-401f5cfb453b	c1	Golden Crown Pineapple Tit Bit in Syrup 840 Gm	Food	Pcs.
a59c9f77-0edf-408f-bd99-a9ccb0e9f6c8	c1	Golden Crown Red Cherry in Syrup 840 Gm	Golden Crown	Pcs.
23db7544-caec-4714-8749-455053d83482	c1	Golden Crown Sugar Invert Syrup 1 Kg	Food	Pcs.
c54b9634-c341-46e6-b6fe-ccd181f05fc0	c1	Golden Crown Sweet Corn Cream Style 450gm	Food	Pcs.
db843245-52c2-40e5-bcfe-6f37e724383e	c1	Golden Crown Sweet Corn Kernel in Brine 430 Gm	Golden Crown	Pcs.
162bc30d-0f87-443d-886e-de0251a64ee4	c1	Golden Crown Synthetic White Vinegar 700 Ml	Food	Pcs.
d30342c5-063a-42b0-9091-7aef3ef27d15	c1	Golden Crown Tomato Puree 825 Gm	Golden Crown	Pcs.
9eb108f5-bcfd-4d5a-bb59-82477d14086c	c1	Golden Mountain Soya Souce	Food	btl.
c6411f5e-2621-4cde-8257-9bae5d5821b2	c1	GOLDEN PRIZE OYESTER SAUCE 330 ML	Food	Pcs.
f85b49d7-909f-475e-a3a2-15bc5a37f9e1	c1	Go Mozzrella 2kg	Food	Pcs.
5cd451c4-5a35-467a-b2b4-893c9e68e02c	c1	Gone Mad Chocolate	Biscuts	Pcs.
a2a4dbab-ac32-4f06-80bc-2a9f599dde68	c1	Gone Mad Mango	Biscuts	Pcs.
a552f636-806c-4ac6-99b5-cc765221002a	c1	Gone Mad -Strawberry	Biscuts	Pcs.
c850f94d-a4d8-4c4f-a0a8-b479194b0b93	c1	Good Vibe Green Apple 250ml	Good Vibe	Pcs.
d15d54bc-e603-4a95-8372-75f08dd74613	c1	Good Vibe Guava Chilli 250ml	Good Vibe	Pcs.
77caf37f-4fae-49c4-aac4-ee5f7f3985ee	c1	Good Vibe Litchi Lime 250ml	Good Vibe	Pcs.
93c3961d-f73c-4c98-919b-15533f16add1	c1	Good Vibe Peach Berry 250ml	Good Vibe	Pcs.
ccfcb4ff-e41f-483e-8ead-14866452057a	c1	Good Vibe Pina Colada 250ml	Good Vibe	Pcs.
ed7b9bda-96fd-4988-9a6b-185c0a45bb73	c1	Good Vibe Virgin Mojito 250ml	Good Vibe	Pcs.
213ed947-0c03-4acf-8a87-a8c3faec1622	c1	Goude Chesse	Dairy Products	kg.
8c7d2f0b-e7da-4fed-a6ab-b07bbc7a663e	c1	GOUMET COOKING RICE CHIEW 750ML.	Food	Pcs.
8b8b74ec-cce8-40d0-bc46-28330102454d	c1	Gourmet Cooking (Imp) Hsing Hua Tiao Chiew 640	Food	Pcs.
066d83e3-846a-45d0-a1af-fbec9b99f93d	c1	GOURMET COOKING SHAO HSING HUA TIAO CHIEW (640*12)	Food	Pcs.
0c925ec9-da43-40a3-9fc2-5e1455213a0f	c1	Grain Shakti Atta Noodles 350 Gm	Food	Pcs.
8ef7bf29-0984-4624-9228-5b8097d7b9b2	c1	Grain Shakti Egg Noodles 350 Gm	Food	Pcs.
7960dd6b-27e5-44dc-8d99-3486dfa7c331	c1	Grain Shakti Multi Grain Noodles 350 Gm	Food	Pcs.
c5e20581-d057-489d-96da-db3277c942da	c1	Grain Shakti Veg Noodles 350 Gm	Food	Pcs.
e8677f5d-3a0c-40e3-9e9f-b830d6a66012	c1	Gran Cacio Hard Veg Cheese - Wheel	Dairy Products	kg.
0ac9a2f5-561c-443a-a306-eaec20baf307	c1	Grandducas Cranberry Sauce 250gm	Food	Pcs.
06f91571-bb35-4717-83a1-cc6ac9cf0752	c1	Granoro Coloured Fusilli 500g	Food	Pcs.
5ee3b223-5d01-4320-bbef-a6d33ccb5e3c	c1	Granoro Farfalloni 500g	Food	Pcs.
d5d91420-034c-4d1f-8339-c5e201a17feb	c1	Granoro Fettuccine 500g.	Food	Pcs.
3c3efe08-1c91-43af-8a56-8951c9a9ef41	c1	Granoro Lasange 500g.	Food	Pcs.
ee414c39-09d4-418b-ba50-adddda0cc35c	c1	Granoro Pasta 500g	Food	Pcs.
dc3fba4b-ad29-4010-85a5-1ee503cbcd32	c1	Gran Sapore Balsmic Vinegar Glaze 250ml	Food	Pcs.
3ec86825-c728-414c-9df2-9d5e76554736	c1	Gran Sapore Balsmic Vinegar Glaze 500ML	Food	Pcs.
473dab3f-227e-412d-a177-49cb11b5ca4f	c1	Green Chilli Sauce 1.15kg.	Food	Pcs.
da4eb4d2-02c7-4663-8f0a-8afe4864728a	c1	Green Curry Paste 400gm.	Food	Pcs.
4110c206-ed65-4047-8fdf-85496c1e4c8a	c1	Green Gate Gherkin	Food	Pcs.
e157fc8f-b881-4a9d-8f10-e71da35a32b7	c1	Green Gate Jalapeno A10 3kg	Food	Pcs.
b28ffc50-0754-4241-89ed-17a29fbb6744	c1	Green Gate Jalapeno Slice	Food	Pcs.
7bceb50d-bf43-4996-aac0-e010bc3377f3	c1	GREEN GATE RED PAPRIKA	Food	Pcs.
08a93c7f-f171-431e-8ba7-c33cc0f3fcf6	c1	GREEN GIANT SWEET CORN	Food	Pcs.
2e30987e-1464-4cc0-8648-f43fc2bf0885	c1	Green Pepper	Food	Pcs.
e06de6ec-4c0a-44b7-b966-91332e78911d	c1	Green Peppercorns in Vinegar (3.5 Cyl)	Food	Pcs.
c4f05900-602e-4b71-9053-c8d730e7c597	c1	Green Pesto Sauce	Food	Pcs.
34b1ce5e-a0d9-4479-9e1a-fea5f129e05f	c1	GREEN PESTO SAUCE 190GM	Food	Pcs.
97dc9bb2-9272-441a-aa6e-d85dc9d6f836	c1	GTS-B GEL 150ML.RS.90/-	Cosmatics	Pcs.
29c43a6b-7b4d-4f47-8b3f-224ae98701da	c1	GTS-B GEL 300G.RS.130/-	Cosmatics	Pcs.
4c25f2a1-78fa-4543-9098-eb53687c4bd4	c1	GTSB PU DEO SPRAY 150ML.RS.150/-	Cosmatics	Pcs.
fe059cbc-3e5b-499c-bc8b-d34b328e40f6	c1	GTS-B SHOWER GEL 259ML.	Cosmatics	Pcs.
5f2bd90b-70fb-4f9b-8e36-a7bf5c354feb	c1	Gts-by Air Freshner	Cosmatics	Pcs.
b2967800-054d-404a-b01c-b10706f98c68	c1	Gts-by ASLRS.125/=	Cosmatics	Pcs.
68b5c77e-ac85-4eb1-857d-5f885dcdc166	c1	Gtsby B/lotion  150ml.Rs.65/-	Cosmatics	Pcs.
8412f8f2-e627-40b2-b835-d2b2e66700e1	c1	GTSBY DEO 175ML.RS.150/	Cosmatics	Pcs.
ce12a6c0-2c23-4f03-aa50-796b67dd5ef6	c1	Gts-by Deo 200ml 140/-	Cosmatics	Pcs.
5b5fdfe2-d617-4462-a74a-5ada56865ac5	c1	GTS-BY Double Proof Deo 50ml.	Cosmatics	Pcs.
c3e442e6-1cb9-42f3-a3cf-3292eb74464c	c1	GTS-BY EDT100ML.	Cosmatics	Pcs.
d82b47e6-d262-4c70-a67a-c3bd94971c4e	c1	Gts-by Face Wash 40g. 60/-	Cosmatics	Pcs.
0562f771-3f24-4f1d-811b-39c25905d7a9	c1	Gts by F/Wash 80g.Rs.90/-	Cosmatics	Pcs.
2dbcb0a8-bac0-4152-b832-ee8d5ad1ae72	c1	Gts-by Gel 100g.Tube 60/-	Cosmatics	Pcs.
b45835d9-4703-4709-9ee1-3638a837c518	c1	Gts-By Gel 150g. 75/-	Cosmatics	Pcs.
71341319-36e4-4703-8f7e-8e37eb100c7b	c1	Gts-By Gel 300g.110/-	Cosmatics	Pcs.
54c8cece-d635-4ee4-a717-67f33ff54815	c1	Gtsby Gel 30g.Rs.25/-	Cosmatics	Pcs.
77da85df-1487-4054-a3b5-d4e7786b3085	c1	GTSBY GEL 50G.	Cosmatics	Pcs.
35382078-b92e-4ddc-b9fe-f45531a59110	c1	Gtsby Mois.Cold Crm.150g. Rs.85/-	Cosmatics	Pcs.
14eb3e16-4e49-4402-a47b-d9fd1215ea96	c1	Gtsby Mois Cold Crm.30g.Rs.25/-	Cosmatics	Pcs.
a2efa0d8-10a4-4416-b6be-174f6f2c276d	c1	Gts by Mouthfreshnor	Cosmatics	Pcs.
b87c207e-fd63-4850-b02d-1e3697a9031c	c1	Gtsby Set &amp; Ext.Hold 250ml.Rs.150/-	Cosmatics	Pcs.
cbddc535-224e-45db-9576-acd6f8395d31	c1	Gtsby Set&amp;Keep Spray Rs.130/-	Cosmatics	Pcs.
b88134f2-2a8b-4d02-a91d-cf20817e69ed	c1	Gtsby Shave Foam 250gm	Cosmatics	Pcs.
cd13b37c-3ef3-4ff1-a779-c562512bfda4	c1	Gts-by Shaving Crm 70g 45/-	Cosmatics	Pcs.
bcdc5b7e-dd0a-4692-b3a1-f4f9faefb674	c1	Gtsby Styling Wax 160ml.	Cosmatics	Pcs.
f8eb8500-4002-4fd6-8bc0-4799a3f87dfe	c1	GUACAMOLE DIP 1020GM	Food	Pcs.
48b15d34-3f03-48e6-8e65-4b2c7871d5a9	c1	Guang Ya Canned Water Chestnut	Food	Pcs.
86a98386-31df-4b74-aa88-56b5f0f0281a	c1	Guava-Baar-250g	Food	Pcs.
28137ec5-902a-4ab7-8835-847ac3c7ed3c	c1	Guava Baar-500g	Food	Pcs.
587d305a-ce87-43ba-aeab-6d986fe3e3d6	c1	Guava Bar 200 Gm	Food	Pcs.
d496154c-3c90-4831-94b6-766868f47323	c1	Guava Bar 500gm (5%)	Food	Pcs.
5a379fa4-678f-4c68-9d1c-23e78466c8d1	c1	Guava Barfi (S)	Food	Pcs.
15f7d196-ae80-4da3-9ed4-b393f990a860	c1	Guava Barfi (S-4)	Food	Pcs.
b9f23735-5ac6-4b59-b87c-da563107fcec	c1	Gulaab Patti 300g	GURU FOOD	Pcs.
fd0c2afe-216a-44e4-aae7-f6942a0f5e19	c1	Gulab Patti	GURU FOOD	Pcs.
b02eb538-e4a8-4d11-9888-245fe08ca4d8	c1	Gulttinous Rice	Food	Pcs.
9d1fe7fb-9aa9-430e-87be-a3aebf6a8bb4	c1	Gum Dinger Ast.15gx70pcs	Food	Pcs.
3e3fb5a8-43dd-481c-bb00-b773b8511c2a	c1	Gum Dinger Black Currunt 15gm. Mrp.250/-	Food	Pcs.
c1eb5147-2ad2-4da7-a542-866d87fea64e	c1	Habit Bake Beans Tomato Sauce 415g	Food	Pcs.
0cdaf27f-bef5-473a-9bed-364bf0fb8354	c1	Habit Button Mushroom 800g.	Food	Pcs.
0ae8a317-a4a5-4e7a-8996-99056fc9d18e	c1	Habit Gherkins Whole 680 Gm	Food	Pcs.
45e6704a-52d2-48a4-8850-fa9f8224915d	c1	Habit Jalapeno Slice 680 Gm	Food	Pcs.
8727c6dd-3f88-4de9-8486-a7068f37e5c4	c1	Habit Lasagne Pasta 500 Gm	Food	Pcs.
add6ef00-1ffe-459c-bf2d-9c22167427a6	c1	Habit Olives Black Pitted 430gm	Food	Pcs.
9d05a664-602c-4748-a818-bda15ac04734	c1	Habit Olives Green Pitted 430gm	Food	Pcs.
d84d6d30-ad72-486f-b37a-1b8a69c52325	c1	Habit Peprika Red Slice 680 Gm	Food	Pcs.
a157d9fc-2234-4e0f-8a2a-6ca1eafc6579	c1	Habit Seasme Oil 500 Ml	Food	Pcs.
f002270b-8dbe-4922-8290-156c1b52fea3	c1	Habit Speghetti Pasta 500gm	Food	Pcs.
d3160a2e-b9f3-4385-bade-976a9b4bdef1	c1	Habit Tomato Puree 825gm	Food	Pcs.
78180a18-11dd-492d-a939-8315144035c2	c1	Hales Syrup 710 Ml	Drinks	Pcs.
82b9fdb8-4024-468e-a82a-ec805f0d0bcd	c1	Hand Rub 5 Ltr	Cosmatics	Pcs.
f83f1c97-dda4-46fb-93dd-e501f1bcc6a0	c1	Hand Sanitizer 100ml Batch No.M025	Cosmatics	Pcs.
271af48c-a10c-423e-b755-28c25b08120e	c1	Hand Sanitizer 100ml Batch No.MCSHSN01	Cosmatics	Pcs.
a281c7cf-8fce-40f2-a60f-0c397490b298	c1	Hand Sanitizer 500ml Batch No.MCHSN01	Cosmatics	Pcs.
cc13e827-2235-4e48-bc10-3ef5aeaa6644	c1	HAND Sanitizer 50ml Batch No.M025	Cosmatics	Pcs.
77c514e8-bb96-487a-a961-a10d9040877e	c1	Hand Sanitizer La Nature&apos;s 100ml	Cosmatics	Pcs.
d9c15c3e-721d-4d21-9df3-967757126aa1	c1	HAPPY Vibes Blue Hawaiain 1 Ltr.@250	Drinks	Pcs.
d438c2f2-ad1f-4e81-a16e-d32d96f5afa3	c1	Happy Vibes Mojito 1ltr @250	Drinks	Pcs.
c57a47cd-2e93-4572-aca4-36acfc0e70c0	c1	Happy Wibes Pinacolada 1 Ltr.@250	Drinks	Pcs.
3d90c700-d318-4a5d-a68e-c7da8ae4f29c	c1	Happy Wibes Strawberry Margrita 1 Ltr.@250	Drinks	Pcs.
fb1c41ac-6924-4d1f-a376-108628b4bf2e	c1	Happy Wibes Sweet Sunrise 1 Ltr.@250	Drinks	Pcs.
52496379-9542-44a9-9a45-79afa8c3e321	c1	Hard Chees Veg Gran Mantovano 200 Gm	Dairy Products	Pcs.
862f95c4-4b81-4c40-a6e7-65389012748a	c1	Haribo Chammalows (Imp)	Food	Pcs.
1095ace8-af18-4e73-aef5-12dedcc3ca03	c1	Haribo Goden Bears (12%)	Confationery	Pcs.
c357ed22-7ac9-4fb7-a2d2-c4dfa023df12	c1	Haribo Golden Bears (18%)	Food	Pcs.
3f7fe5d9-3a22-4137-a003-c806e5c7b59f	c1	Haribo Marshamallows (Imp)	Food	Pcs.
0e941b85-4df3-4b6a-99b1-954020488039	c1	HARIBO MARSHMALLOW	Food	Pcs.
9a03cf83-de5c-4ae3-b5c4-fdd9ab6a4050	c1	HB Soyabean Paste 700ml/800gm	Food	Pcs.
9d0a4dd7-6c4c-4aa3-a365-e5d770ca61c3	c1	Hb Sweet Soya Sauce 700ml/800 Gm	Food	Pcs.
c1084c7a-27b0-4d79-8c2c-a19557610ac8	c1	HBT American Bread Crumbs White 1kg	Food	Pcs.
c05f1447-8467-45fd-bd4a-46aca845fbab	c1	HBT Lasagne Pasta Italian 500g	Food	Pcs.
3cfc139b-8b57-49a8-a529-aea67855a1de	c1	HBT Panko Breadcrumbs Indian 1kg	Food	Pcs.
ed39784e-633e-4430-addc-fa705cd5ab81	c1	HBT SESAME OIL TOASTED 500ML	Food	Pcs.
3ddbc684-4965-4be7-926e-84f69a819bb8	c1	Healthy Boy Thin Soy Sauce 700 Ml	Food	Pcs.
5d56a120-7182-4a0b-ab9e-d5e901a3fa39	c1	Heinekein 330 Ml Bottle	Drinks	Pcs.
f5652545-5a26-45f7-a8f1-2a66c0f59c81	c1	Heineken 0.0 Can (330 Ml)	Drinks	Pcs.
bef801e1-d615-40e3-96c0-3b067a8d90b4	c1	HEINZ APPLE VINEGAR	Drinks	btl.
6482ad02-9155-4cbf-b6a2-e73453835df6	c1	Heinz Baked Beanz 415gm	Food	Pcs.
3f310a9f-37ae-477b-a38a-7c993d46c526	c1	Heinz Baked Beanz (Imp)	Food	Pcs.
cc645e95-670a-4b69-b3e7-7631c289463b	c1	Heinz LP Worcestershire Sauce 290 Ml (Imp)	Food	Pcs.
37370746-ef95-4508-aacc-7c26cc190305	c1	Heinz LP WORCESTERSHIRE SAUCE 325 Gm	Food	Pcs.
353e08a4-dab8-4b9c-ae20-0ff2675bfdd1	c1	Heinz Malt Vinegar	Food	Pcs.
fdfd523d-41dd-4020-9e25-0676b425d794	c1	Heinz Tomato Ketchup 100 Gm Mrp.22	Food	Pcs.
64ff8bab-3c54-4fa4-ab10-21311a4ecd79	c1	Heinz Tomato Ketchup 1 Kg.	Food	Pcs.
9fd9c523-cb09-4ff0-8ded-50a780f2ec8e	c1	Heinz Tomato Ketchup 200gm	Food	Pcs.
47036fbd-446d-4d4b-934b-379d84850e3b	c1	Heinz Tomato Ketchup 300 Gm	Food	Pcs.
416b8bbf-2823-4cb4-9211-e83d40646bc9	c1	Heinz Tomato Ketchup 450g.M	Food	Pcs.
56b8bf8f-6770-448c-9f5c-bdb798eff6d1	c1	Heinz Tomato Ketchup 875 Gm	Food	Pcs.
b794d43e-1dda-4766-a223-c2abf0f8399f	c1	Heinz Tomato Ketchup 900 Gm	Food	Pcs.
82bd6036-71e9-4346-95f0-c3e039201c8f	c1	Heinz Twist Tomato Ketchup 435gm	Food	Pcs.
2ddf61c9-cfcb-4df2-85d9-3f17485c5521	c1	Heinz White Vinegar	Food	Pcs.
e048c7ca-1d89-4690-a724-79a596e3d896	c1	Hellman Light Mayonise 430ml.	Food	Pcs.
c1a8cbbd-7136-4e23-8bc3-4d6ccc3aac6a	c1	Hellman Mayonaise	Food	Pcs.
0e83fdd3-5863-4dd8-a06e-973d22515692	c1	HELLO PANDA BISCUITS	Biscuts	Pcs.
e555ee98-b3f8-4668-824a-a6f262abaed6	c1	Hello Panda Milk Vanilla 42 Gm	Food	Pcs.
8f25ac0b-520f-4b8c-ad9c-a6bfcb869c6c	c1	Herbale Ess.Shampoo 300ml.	Cosmatics	Pcs.
f43d23b7-9cf1-47b3-aea1-8f7fac38a0cd	c1	Herbal Shampoo Free	Cosmatics	Pcs.
fddc55e5-06ec-44af-a94c-f048b7833ee3	c1	Hersays Chlt.Syrup 1.3kg.	Chocolate	Pcs.
3209a7f3-08e7-4dc0-ad6a-539b953124a4	c1	Hershays Choclate Syrup.	Food	Pcs.
617deca6-6643-4390-9584-05a15c1018ed	c1	Hersheys Choclate Syrup 1.3 Kg	Food	Pcs.
e3196c21-6a40-4c3b-8335-d96804114045	c1	Hersheys Sofit Soymilk200ml	Food	Pcs.
dd338e7d-c1f6-43ac-8822-1f7f1d4afe8d	c1	HERSHEYS SYRUP CARAMEL 623GM	Food	Pcs.
fb96e577-b440-4d07-b2e2-62f53d4fdb08	c1	Hersheys Syrup Strawberry 200 Gm	Food	Pcs.
dd36704c-b7bc-4c25-b6b2-dbc00843e9e0	c1	HERSHEY SYRUP CHOCOLATE BOTTLE 623G	Food	Pcs.
af789b0a-ee38-4ff2-8432-7b068634ecf8	c1	H.Essence US Shampoo 355ml.	Cosmatics	Pcs.
1d1a412f-947d-42ea-b244-336a784f6181	c1	HEZELNUT NUTELLA	Chocolate	Pcs.
cd6cc442-0edc-46ea-86f9-9538520172e6	c1	HILLWAY COCONUT WATER 320 ML	COCOCNUT	Pcs.
c850529b-20c2-4f85-8d88-d9938c634c12	c1	Hlt.Kravour Hexagun Mini 150g.	Chocolate	Pcs.
84af844c-b10d-428f-9dd7-47cb5f33a0b3	c1	HOISIN SAUCE 330GM. Lkk	Food	Pcs.
53bac65a-1e57-40c1-9da4-2a5076329c2a	c1	HONDASHI 1KG.	Food	Pcs.
3d7d912e-411b-4c43-8cab-9bd6dd4755ba	c1	HONDASHI 500GM	Food	Pcs.
09651344-4d32-49c8-ac01-56f1910e4620	c1	Honey Capilano (5%)	Food	Pcs.
a6820f64-54d6-4763-9184-3cca181be263	c1	Honey Ducks 100gm Chlt.Tray	Chocolate	Pcs.
0fb29b7e-c0a0-47bd-ae50-d0fb4a8a8b62	c1	Honey Ducks Chlt.Tray 200gm.	Chocolate	Pcs.
b3f14493-59b7-4682-a081-7dade8c1df82	c1	Honey Ducks Choco Bar 50gm.Assorted	Chocolate	Pcs.
733aff55-7939-46c3-9a48-e192c47cf882	c1	Honey Ducks Greeting Gift Pack 400gm.	Chocolate	Pcs.
dcbe2e9c-5e75-4dbe-907a-951a2f9bef24	c1	HONEY DUCKS TIN 200GM.DRAGEES ASSORTMENT	Chocolate	Pcs.
f93ae728-dc3b-4f7b-a6b2-abe805af3609	c1	HONEY DUCKSTIN 200GM.HONEY DUCKS	Chocolate	Pcs.
d8dc7d59-f049-4224-acf3-6f13d8a48308	c1	Honey Duke Magic 350gm.	Chocolate	Pcs.
46628f3c-3ff3-4b4d-8a6e-6edea856582f	c1	Honey Dukes Big Ruby 200gm.	Chocolate	Pcs.
756b8bc3-ad46-4757-9d08-1db736bf5e40	c1	Honey Dukes Chocolate 100gm.	Chocolate	Pcs.
b4fda5fd-62af-47b0-8feb-f224722a4c2b	c1	Honey Dukes Heart Choco Dragees Almond 90gm.	Chocolate	Pcs.
e7956801-6272-4328-86bc-6aa0470f55eb	c1	Honey Dukes Love Forever 90gm.	Chocolate	Pcs.
068ad45a-5594-4e2a-a506-6377286e717b	c1	Honey Dukes Ruby-Choco Dragees Alomonds 200gm.	Chocolate	Pcs.
f248e45d-0dfb-4218-9979-93f8eee8b6bf	c1	HONEY DUKS 200GM. GREETINGS	Chocolate	Pcs.
d1b17b55-f325-4866-9c55-e66af69c13af	c1	Honey Duks Chocolate Tray 125gm.	Chocolate	Pcs.
b437f3df-54d1-4787-96fa-21e22af2ae20	c1	HONEY DUKS TIN 200GMS DRAGEES ALMONDS	Chocolate	Pcs.
74e4a182-0d9d-4f0e-99aa-867edde9e4a6	c1	HON MIRIN 1.8 LTR.	Food	Pcs.
81a16f7a-66f5-40bc-9c9f-3c0df3946a1e	c1	Honmirin Sweet Cooking Seasoning 1.8 Ltr	Food	Pcs.
859e3118-4efd-402e-ac42-e47dff42b21b	c1	HONMIRIN SWEET COOKING SEASONING (1.8 LTR *6)	Oil	Pcs.
0e26ce59-a844-47a6-9cbb-556f6cde90cd	c1	HOT 6250ML.(LOTTE)	Drinks	Pcs.
62965561-ab17-45fa-8acf-35099b029ece	c1	Hot Bean Souce 250ml.	Food	Pcs.
b0aa638b-9c60-49c7-9a19-e8d7fffd3756	c1	HOT DOG SKINLESS SAUSAGE 200gm	Food	Pcs.
3dc5d2a2-611c-4d44-9db0-c8d53f354384	c1	How How Rice Stick 5mm 12%	Food	Pcs.
08dec3c0-80ec-474e-ae42-9be249fdc030	c1	How How Rice Stick 5mm 5%	Food	Pcs.
9753e132-bc96-416d-bfb1-f3875e42b165	c1	Hp Cooking Sauce (Imp)	Food	Pcs.
1a664b0f-b1f5-47ce-b310-c9f0994092e0	c1	H P Cooking Souce	Food	btl.
3f94cbc7-f0a8-4eab-8720-52994844da52	c1	Hp Sauce	Food	Pcs.
59fd0ae2-28b2-4962-b884-13b7eb821324	c1	Hp Sauce 255gm	Food	Pcs.
8a9046b7-4525-4dad-a29d-dd0f04b7710f	c1	HP SAUCE PET 255 GM	Food	Pcs.
d6461332-a9f8-4f0d-9840-c85c2206c8c6	c1	H P Sause 255g	Food	Pcs.
d824a136-4c99-4d6e-bf41-2479121c93dd	c1	Hrbl.Cond.300ml.Brk.Ovr.	Cosmatics	Pcs.
874fddca-3b77-4698-b236-a08c304201b0	c1	Hrbl.Cond.300ml.Colour	Cosmatics	Pcs.
2d0d4a77-0df4-4e5e-9fcf-210ffd72ee99	c1	Hrbl.Cond.300ml.Dry/damage	Cosmatics	Pcs.
18d84f0d-2881-4ccd-8d3a-8cf99db7ffa5	c1	Hrbl.Cond.300ml.Strait	Cosmatics	Pcs.
59bd8c1e-15b9-428c-bbcf-4acd9017b7e4	c1	Hrbl.Sham.160ml.Brk.Ovr.	Cosmatics	Pcs.
7b4746de-439f-4433-9411-4727c428a739	c1	Hrbl.Sham.160ml.Colour	Cosmatics	Pcs.
9ebea4f9-624f-4c55-bf3c-d2796ef11db1	c1	Hrbl.Sham.160ml.Hyderating	Cosmatics	Pcs.
55bbae61-4c0b-470d-9824-beb30125ed4b	c1	Hrbl.Sham.160ml.Strait	Cosmatics	Pcs.
1b9561ec-a863-4dbf-802e-a9605e6747fc	c1	Hrbl.Sham300ml Break Over	Cosmatics	Pcs.
1f3d6fa6-d31c-4be1-9976-6a982335eafd	c1	Hrbl.Sham.300ml.Colour	Cosmatics	Pcs.
d3151b9f-aa82-4f5b-931a-ce1054aa6419	c1	Hrbl.Sham.300ml Hyderating	Cosmatics	Pcs.
be2a94d5-a9c1-4d91-8f18-f34aa45e369c	c1	Hrbl.Sham.300ml.Strait	Cosmatics	Pcs.
1ae0841a-f1e5-4e63-963b-b0c748374cfb	c1	Hrbl.Shamp.160ml.Anti-Dand.	Cosmatics	Pcs.
2f5af95e-14d8-4e7e-b0c4-ed03dfdb3fe5	c1	Hrbl US Shmpo Hello Hydrating 2in1	Cosmatics	Pcs.
4dde4fc0-4b67-4b06-8106-89bed9b22ce0	c1	H-R Choco Syp	Chocolate	Pcs.
9294d8f2-65ae-4670-96f4-19902593798a	c1	H-R CHOCO SYRUP	Chocolate	Pcs.
92ea95e6-284e-4237-97ec-18d80cb0c0ff	c1	HS Chia Seeds 200g	Food	Pcs.
e5aaacc8-c7df-41cd-bef8-d01279c81920	c1	HS CLEARSMOK 60 GUMMIES	Food	Pcs.
6f8ab8ec-c932-4185-9f02-bd4387ab8e1f	c1	HS Flex Seed 200g	Food	Pcs.
16384250-e8c3-4bcc-85de-0ff3716bfae5	c1	HS GOOD SLEEP 60 GUMMIES	Food	Pcs.
b5cc2237-8140-4b8a-812e-9b5a768a1531	c1	HS PCOS 60 GUMMIES	Food	Pcs.
dc6f8ab6-9d89-4d51-8413-48457fce937c	c1	HS Pumpkin Seeds Green 150g	Food	Pcs.
f6500154-daac-4146-b73c-2c1820eeabce	c1	HS Quinoa Seed 500g	Food	Pcs.
492cc5fc-bbaa-4d68-8886-21056e665c13	c1	HS Rosted Pumpkin Seed 150g	Food	Pcs.
7f5b3306-aed8-4bab-9fff-bc5c1577d510	c1	HS SHILAJIT 60 GUMMIES	Food	Pcs.
ea6bd6f8-cfa0-4cd9-ad36-f2d3f676a127	c1	HS Sunflower Seed 200g	Food	Pcs.
6238760c-2640-434a-a89d-31abf1382077	c1	HS VITAMIN D3 K2 B12 GUMMIES	Food	Pcs.
928697fa-0419-4840-85ba-fe1a9e333574	c1	HS Watermelon Seed 100g	Food	Pcs.
cecd2aa5-36dd-45c0-b2fb-d00cde98faec	c1	Hubba Bubba Chewing Gum	&#4; Primary	Pcs.
fa8c3e74-5aa1-4d15-8b10-a00d307e0d16	c1	HUL Aromat Seasoning 500gm	HUL	Pcs.
b34f6c8b-0c4c-43ea-8270-063f4fba9d5f	c1	HUL Best Foods Real Veg Mayonaise 1kg	HUL	Pcs.
26a7d7b9-cf81-4122-90a0-93d030c466f5	c1	HUL Brown &amp; Polsan Corn Flour 1kg	HUL	Pcs.
842b4209-8255-4b37-821a-79e27126f05e	c1	HUL Brown &amp; Polsan Custard 1kg	HUL	Pcs.
20f6c332-fd11-44f0-869c-ea007a055ec3	c1	HUL Brown &amp; Polsan Custard 50kg	HUL	Pcs.
3eafde56-3e41-4f0d-8340-44651d5c22f0	c1	HUL Bru Gold 100 Gm Jar	HUL	Pcs.
c471fc7f-1ab8-4870-b8a5-da7e2a26eaf9	c1	Hul Bru Inst 2 Gm Mrp.2/- (18%)	HUL	Pcs.
f2cec5e3-ccad-4aa7-9c5d-71784364a4a6	c1	HUL Chicken Browth Powder 5*100gm	HUL	Pcs.
27f8ac3e-1026-4958-9c87-a19d8ca774ee	c1	HUL Demi Glace Sauce Powder 5*100gm	HUL	Pcs.
542f8507-96a0-485a-b6e5-46f1c4f0aa26	c1	Hul Domex Disinfectant Floor Cleaner 500 Ml	HUL	Pcs.
0b93216f-6b82-4444-804d-c2eb6fea2c36	c1	Hul Ftk Doy Pack 950 Gm	HUL	Pcs.
98a9979e-d1ab-48c4-a594-903153a6ed45	c1	Hul Kissan Fresh Tomato Ketchup 2kg	HUL	Pcs.
2ac0cbb2-a2f1-40c2-b968-4e05adffcb71	c1	HUL Kissan Ftk 1kg (Glass Bottle)	HUL	Pcs.
72ee57b1-13fd-45ec-8a49-810a0eeb9be2	c1	Hul Kissan FTK 500 Gm (Glass Bottle)	HUL	Pcs.
e72dabb8-fe4a-4be5-900e-bd6868f0246f	c1	HUL Kissan Mixed Fruit Jam 1 Kg.	HUL	Pcs.
4b5e1fd0-47bc-49c6-be78-b5dfcf9f5af4	c1	HUL Kissan Mix Fruit Jam 500gm	HUL	Pcs.
4fe29f67-8aa0-4a07-a26c-93903657cc84	c1	HUL KISSAN ORANGE MARMALAD 500G.	HUL	Pcs.
632c2097-9277-465f-a9cc-7b64d8cb0cfa	c1	Hul Kissan Pineapple Jam 500 Gm	HUL	Pcs.
72a1f772-9342-44f2-a23e-454317068907	c1	Hul Kissan Sauce Dip 930gm Pouch	HUL	Pcs.
13965902-0872-4312-b932-c33cbf14ce13	c1	HUL Knoor Sweet Corn Veg Soup 500gm	HUL	Pcs.
57b74be0-6219-4ab1-9b26-970577059b66	c1	HUL Knoor Thick Tomato Soup 500gm.	HUL	Pcs.
bc7bb6a8-429a-426e-b713-1b23af516b55	c1	HUL Knorr All Purpose Seasoning 500 Gm	HUL	Pcs.
661f941e-5641-4c5d-b80f-5e9700ba51c5	c1	Hul Knorr Indian Aromat Masala 100 Gm	HUL	Pcs.
1922daca-893e-437f-b6b6-2c8fdbc8031e	c1	HUL Knorr Lime Seasoning Powder 500gm	HUL	Pcs.
6dd931aa-89bc-41c3-8bd1-5dbeb8a6bf00	c1	HUL Knorr Onion Tomato Gravy Base 1kg	HUL	Pcs.
9b49c1a6-f595-48e6-82a2-19ccdd69046a	c1	Hul Knorr Red Marinade 100 Gm (Smoky Tandoori)	HUL	Pcs.
73026b8a-9b7e-4898-8ab2-389d450e5a06	c1	Hul Knorr Soupy Noodles Mast Masala 75 Gm	HUL	Pcs.
c27f3765-55e9-4d8e-8d89-f5ed33d87922	c1	Hul Knorr White Marinade 100 Gm (Malai Tikka)	HUL	Pcs.
5e3d864e-a180-4db1-9fb2-6d1b93fa7c92	c1	Hul Ksn MF Jam Pouch Rs.2/-	Food	Pcs.
309c128e-6aea-42af-adc4-cc6852c045f9	c1	HUL KSN Sauce Dip 1kg Pouch	HUL	Pcs.
471531d0-2e3e-4e78-866b-af5252874f7a	c1	Hul Ksn Sauce  Dip 930 Gm	&#4; Primary	Pcs.
f50f8460-3267-40cc-beaf-400640fae337	c1	Hul Ksn Sauce Dip 980gm Bottle	HUL	Pcs.
853a23da-b483-4ce3-8be0-2164fc8dac7a	c1	HUL Ksn Tomato Paste 1kg	HUL	Pcs.
aa0b34fc-db35-4595-bbcc-657cd328bea3	c1	HUL Ksn Tomato Puree 1kg	HUL	Pcs.
c77f2c25-21b6-4a82-a397-3c0ddf7dfbf5	c1	Hul Lb Germ Kill Spray 75 Ml	HUL	Pcs.
7762e297-f398-4509-8a7c-8e91e7f744a8	c1	Hul Lemon Squash 750 Ml	HUL	Pcs.
25e053da-6c59-4d4c-b9f7-b2b294880a54	c1	HUL LIPTON GREEN HONEY LEMON OOH 1.4GM*100TB	HUL	Pcs.
b64033dc-6578-4688-94ad-e2a001ca0748	c1	Hul Lipton Green Pure &amp; Light 25 Tb	HUL	Pcs.
1a56807d-71a4-49af-aef6-70b46202fed6	c1	HUL Red Label 1 Kg Pillow Pouch	HUL	Pcs.
43398a4b-e38c-463d-aef0-1c219d5b9fb5	c1	HUL Red Label 500gm	HUL	Pcs.
1f6e7b83-272d-4f19-8573-31ee323e722b	c1	Hul Red Label Leaf Blend 1 Kg	HUL	Pcs.
2841e5b5-1b3b-4b89-9515-5c8d848d3bf0	c1	HUL REX  Baking Powder 3kg	HUL	Pcs.
e7435e20-67a6-4f88-90f4-f3275e890fa7	c1	HUL Rex Baking Powder 500gm	HUL	Pcs.
02d6f03e-a68c-4fac-8033-ef5c752a6ad5	c1	HUL Rostip Chicken Seasoning 800gm	HUL	Pcs.
84545539-2202-4f92-a1b4-220de3b20674	c1	Hul Taj Mahal Tea Nonsouth 1 Kg	HUL	Pcs.
ae621f83-c704-4073-b46e-ee5d7eaa45d8	c1	HUL TAJ MAHAL TEA NON SOUTH 250GM	HUL	Pcs.
fb534403-f34a-45f2-b3e3-44fbb28fc160	c1	Hul Taj Mahal Tea Nonsouth 500 Gm	HUL	Pcs.
2d69ceca-a8c8-48a1-8a0b-c4ee24f2453f	c1	Hul Thick Tomato Soup Railways 500gm	HUL	Pcs.
d645433d-856d-4e77-a179-941c3db7be64	c1	HUL TK Sauce Maker 1.75kg	HUL	Pcs.
40022616-d522-4396-9352-4f9047eb6392	c1	HUL Tomato Makhani Gravy Base 1kg	HUL	Pcs.
228d8ebe-0491-444f-a53b-86520a831423	c1	HUNGAR JACK LITE SYRUP	Drinks	Pcs.
17e3b718-9c1f-4123-a309-30723a3ba0c9	c1	HUNGAR JQACK BUTTER SYRUP	Drinks	Pcs.
7d48ddf1-2506-4dc2-9e62-d71e6116f25f	c1	HUNGARV JACK ORIGNAL SYRUP	Drinks	Pcs.
6ee5cfa2-e4e4-4e74-8ce1-067c5cdc2379	c1	Hutesa Black Olive 450 Gm	Food	Pcs.
a5b64e2c-48ae-4db5-8575-73883e61b672	c1	Hutesa Black Olive Pitted 450 Gm	Food	Pcs.
822327c1-0b2f-47ef-9aff-c9de1f15b472	c1	Hutesa Green Olive Pitted 450 Gm	Food	Pcs.
3b6f6744-d443-4b69-a992-71d2a849504b	c1	Hz Lp W&apos; Shire Sauce Orig 290ml.	Food	Pcs.
b9b8b0e4-ac5a-477c-84ca-31db9c8150a0	c1	Ibizza Basil Squash	Ibizza	Pcs.
7069411a-a056-43a8-b8fc-096ca1d4346f	c1	Ibizza Black Currant Squash	Ibizza	Pcs.
a3c8bb83-dcef-4c43-940e-bd3ac56750e2	c1	Ibizza Blood Orange Squesh	Ibizza	Pcs.
05e1ee17-82aa-4fd2-8264-7b3c2ba77360	c1	Ibizza Blueberry Squash	Ibizza	Pcs.
b8f9efbe-419c-43e8-a9ca-f32161b243d4	c1	Ibizza Blue Curacao Squash	Ibizza	Pcs.
72184ef5-f41b-4df6-bd6b-6889099f5efc	c1	Ibizza Caramel Squash	Ibizza	Pcs.
50fbe1dd-741e-4852-a426-3f56d4f4b11f	c1	Ibizza Coconut Squash	Ibizza	Pcs.
13ffd38c-5d03-4507-a958-f88cef5ae6f2	c1	Ibizza Coffee Squash	Ibizza	Pcs.
83e61126-ce86-4744-99cf-8674c2c0fda3	c1	Ibizza Cranberry Squash	Ibizza	Pcs.
eec2758f-ae30-4cb1-afd8-b52ce60e5127	c1	Ibizza Ginger Squash	Ibizza	Pcs.
d9d77d7a-e6fe-4335-86b0-cab216ce7a12	c1	Ibizza Green Apple Squash	Ibizza	Pcs.
784708ef-ba11-4e16-bece-bb7b0a6989fc	c1	Ibizza Green Mint Squash	Ibizza	Pcs.
c36277e3-0ccf-4b7a-b18f-b2a4f8438108	c1	Ibizza Grenadine Squash	Ibizza	Pcs.
801b3ecb-b8a1-4d64-af53-eb66fb0df04f	c1	Ibizza Hazelnut Squash	Ibizza	Pcs.
ebcd5600-0651-49bd-852e-26cb7718e567	c1	Ibizza Irish Cream Squash	Ibizza	Pcs.
0a339211-7fc8-4823-9999-5a80489efd33	c1	Ibizza Kala Khatta Squash	Ibizza	Pcs.
0ccac086-d4e2-41a8-abde-41bf6f60a081	c1	Ibizza Khus Squash	Ibizza	Pcs.
35383ebb-d43c-407c-ba40-e6162c504023	c1	Ibizza Lemon Tea Squash	Ibizza	Pcs.
18b0a6f3-93fc-49a2-9543-e7d5369ce6d7	c1	Ibizza Mango Puree 1ltr.	Drinks	btl.
644b36c7-b12f-45b4-86d8-77605212da35	c1	Ibizza Mint Mojiti Squash	Ibizza	Pcs.
a6237886-8ebc-4c79-89b1-172b6fd8425c	c1	IBIZZA MINT MOJITO SYRUP(MOCO) 1 LTR	Drinks	btl.
6b623acd-d9b7-4ef8-85d4-20806078d0c7	c1	Ibizza Mojito Mint Squash	Ibizza	Pcs.
5f8f98f5-60a7-4d33-80ac-f45b81aa4ffd	c1	Ibizza Paan Squash	Ibizza	Pcs.
cb640aa1-068b-4e44-b8c1-67884f469f6b	c1	Ibizza Passion Fruit Squash	Ibizza	Pcs.
685cd8d7-562a-464b-83d3-5ce022dd26d4	c1	Ibizza Peach Squash	Ibizza	Pcs.
49566e8c-26b9-4ba0-8c53-20d3e370d52b	c1	Ibizza Peach Tea Squash	Ibizza	Pcs.
2c3ef52f-0942-4422-ac8e-37844e29f4c2	c1	IBIZZA PINACOLADA SQUESH	Drinks	Pcs.
e51fc588-5d36-4e45-b51a-2a23a9a93753	c1	Ibizza Power Squash	Drinks	Pcs.
7b4c0cc0-f5ec-40e4-81de-62f54d5263d6	c1	Ibizza Rabdi Falooda Squash	Ibizza	Pcs.
e3c4b2a4-b528-479b-9dec-23edae170936	c1	Ibizza Rasmalai Squash	Ibizza	Pcs.
202f4b4c-8787-4589-8c93-9639df590494	c1	Ibizza Raspberry Squash	Ibizza	Pcs.
4be3b552-f6c3-4b6b-9c33-80da05c0eabb	c1	Ibizza Rose Squash	Drinks	Pcs.
728a72e1-fa22-48d6-907f-599b9c9ff486	c1	Ibizza Strawberry Spuash	Ibizza	Pcs.
a7cd234b-d96d-4503-af01-60702c928f1b	c1	Ibizza Triple Sec Squash 750 Ml	Ibizza	Pcs.
899b70f2-5a8a-45e1-ad7d-11a7272bbb63	c1	Ibizza Vanilla Squash	Ibizza	Pcs.
f309bc8e-80b4-4d78-bda1-8d50bce88174	c1	Ibizza Watermelon Squash	Ibizza	Pcs.
6cbec294-bec4-4cb0-933e-467959be55ac	c1	Ice Dry	Box	Pcs.
31e31e87-7614-4e62-b98e-de471ce87da9	c1	ICE PACK	Food	Pcs.
75982953-0051-439a-8fb0-05d728ec733e	c1	Impact Mint 14 Gm	Food	Pcs.
ef809295-5d2b-4455-a813-183a24c63c04	c1	IMPERO BURRATA CHEES 200GM.	Dairy Products	Pcs.
cadf839d-22c8-4142-b76b-eadf846502a2	c1	Indian Flatbread 8&quot;	Food	Pcs.
d910dc0e-6a5f-44e8-993e-37dd586574e8	c1	Indo Me Noodle	Food	Pcs.
0a4816a4-65c4-4a22-8dd4-6c360988494c	c1	Instant Drinking (12%)	Food	Pcs.
96f86bac-4244-42f6-8d0f-2029c0d9963b	c1	Instant Drinking Powder (O) (12%)	Food	Pcs.
43a111bb-70d7-4816-9c9e-9e7987fc1fea	c1	Instant Drinking Powder (P) (12%)	Food	Pcs.
1ef74655-e12b-4b80-b7b1-7e80701e859d	c1	Instant Plain Tea	Drinks	Pcs.
29fe4531-e0ed-4485-8574-1c0ca391d0f1	c1	Instant Sugar Free Tea	Drinks	Pcs.
ebca6c7c-d712-414d-8cac-c5d925002252	c1	Intant Coffee Premix	Drinks	Pcs.
361a1c7c-56e2-433a-a11a-c36c8152ab3b	c1	INTL CADBURY COCA TN 125g	Chocolate	Pcs.
e7c4ae68-f44d-4415-be42-001add57da4b	c1	Italian Garden Arborio Rice 1kg	Italian Garden	Pcs.
2ebefb90-2e7e-4495-9cbf-5cb5c3513f40	c1	ITALIAN GARDEN BALSAMIC CREAM 250ML	Italian Garden	Pcs.
33917302-6592-4ef2-91b3-31d185afd6b8	c1	ITALIAN GARDEN BALSAMIC VINEGAR 500ML.	Italian Garden	Pcs.
1c01b503-2793-46aa-8a2a-41509f914079	c1	Italian Garden Bamboo Shoots in Water 567 Gm	Food	Pcs.
aad4b158-4463-4bb2-b980-924a14b3321d	c1	ITALIAN GARDEN BLACK FUNGUS	Italian Garden	kg.
3be0c9a0-59d1-484d-b119-d62c7d18b111	c1	Italian Garden Black Pitted Olive 450gm	Italian Garden	Pcs.
6d5c0ccd-2e7c-45d7-8711-939f45c2251e	c1	Italian Garden Black Sliced Olive 450gm	Italian Garden	Pcs.
eef4b6d0-e22e-4964-9cd9-2dae23092d9f	c1	Italian Garden Chipotle Pepperin Abodo Dauce 2.8kg.	Food	Pcs.
c27963c7-5749-4e1a-9fb6-b3f62f71df33	c1	Italian Garden Coconut Milk 400ml	Italian Garden	Pcs.
def65f4d-e0c6-4b1a-a52d-d3bd03f6428f	c1	Italian Garden Coconut Water 330ml	Italian Garden	Pcs.
9a15724c-d0b7-424a-8280-b2d73269ca30	c1	Italian Garden Cocxtail Onion 350g.	Food	jar
c8930d5b-4cd1-4930-a7bd-96e0338ee044	c1	Italian Garden Dijon Mustard 350g	Food	Pcs.
8cd01e4f-33b2-4774-afab-6786d0db575d	c1	Italian Garden Dried Morels 250g	Italian Garden	Pcs.
68e49703-a57d-4b85-892b-10c3196cfadb	c1	Italian Garden Extra Virgin Olive Oil 1 Ltr	Italian Garden	Pcs.
8f8ad6f7-4750-46b1-a350-3c3b15d04e94	c1	Italian Garden Fusilli Pasta 500g	Italian Garden	Pcs.
5e53c51e-4fe6-4b0b-bbe4-117b757629cb	c1	Italian Garden Gherkins 670g.	Food	jar
9055cafa-f9d6-435d-b4bc-e7568ffa2f67	c1	Italian Garden Gomti Pasta 500g	Italian Garden	Pcs.
ad24091f-a379-4018-86ef-7ed4adc37c54	c1	Italian Garden Green Pitted Olive 420gm	Italian Garden	Pcs.
f3066770-f8f0-431c-bdf1-59d233dec1d6	c1	Italian Garden Hon Mirin 1.8 Ltr	Italian Garden	Pcs.
bc0e9375-93b9-424d-bf8c-f1636e94bada	c1	Italian Garden Jalapenos Sliced 670 Gm	Food	Pcs.
90e48ab6-121f-4f36-98e8-633626aa0140	c1	Italian Garden Mango Juice with Pulp 250ml	Italian Garden	Pcs.
e4dfd46c-024a-4ac1-8f41-8f779051c8a9	c1	italian garden Mix Fruit Juice with Pulp 250ml	Italian Garden	Pcs.
e9fbceb2-78eb-4072-8259-4daf8424eb82	c1	Italian Garden Orange Juice with Pulp 250ml	Italian Garden	Pcs.
761640dc-8cf3-407f-b3a2-026b9016710c	c1	Italian Garden Oyster Mushroom 1 Kg	Food	Pcs.
b464b38b-f3d9-4b56-be3a-1971d44555c1	c1	Italian Garden Peeled Tomatoes 2.5 Kg	Food	Pcs.
3998e7ea-abe1-42ad-be63-2bdb7bb7ba5a	c1	Italian Garden Penne Pasta 500g	Italian Garden	Pcs.
d82ca8f2-b78c-452c-a4d0-dd25e374779f	c1	Italian Garden Pineapple Juice with Pulp 250ml	Italian Garden	Pcs.
45e26e2c-be7e-4860-ab39-b964472943dd	c1	Italian Garden POMACE OIL 1 LTR	Italian Garden	Pcs.
4c940767-6d46-4341-b330-67219a29edb8	c1	Italian Garden POMACE OIL 5 LTR	Oil	Pcs.
cc841d8d-830f-4771-a183-1b1dc5c2c0c0	c1	Italian Garden Porcini Mushroom 500g Jar	Italian Garden	Pcs.
3ab0d28d-9c45-43a9-80ec-6a09cf488fea	c1	ITALIAN GARDEN  RED GRAP WINE VINEGAR 1LTR	Food	Pcs.
089ef983-0b99-41e6-9a10-250fe5fe9e35	c1	Italian Garden Ryorishu 1.8 Ltr	Oil	Pcs.
754fec39-7d9e-40ae-8638-5674e888400d	c1	Italian Garden Shitake Mushrooms 1 Kg	Italian Garden	Pcs.
aa4fc232-73c3-43e0-8fc6-1672b3f793a9	c1	Italian Garden Sundried Tomatos in Oil 230g	Food	Pcs.
d096d8f3-706b-4d11-ba9e-6a60a68a940e	c1	Italian Garden Sundried Tomatos in Oil 280g	Food	Pcs.
355885e8-3f9a-441e-aba0-41e8bcece34d	c1	Italian Garden Sushi Vinegar 1.8 Ltr	Italian Garden	Pcs.
19334023-fa00-4d6d-9b44-c70d8210a32a	c1	Italian Garden Tahina Paste 600g	Food	Pcs.
b4789bec-5407-4692-bbbc-d6c2ca055e61	c1	Italian Garden Waterchesnuts in Water 567 Gm	Food	Pcs.
81330587-07b2-47d5-b776-4612a1bcd623	c1	ITALIAN Garden White Fungus Mushroom 1kg	Italian Garden	Pcs.
a2937325-d739-4ca3-a566-a315fb5999ec	c1	Italian Garden White Grapes Vinegar 1ltr	Italian Garden	Pcs.
62b5d711-01cd-45d8-acc4-8fb9a9a1ad21	c1	Italian Garden White Truffle Oil 250 Ml	Food	Pcs.
3ba6901f-bab6-4dbc-bc03-7e08ca3afdc3	c1	ITALIAN GARDEN WHITE WINE VINEGAR 1LTR	Food	Pcs.
7ee68b7a-dc3c-447c-94d3-ce381739bda0	c1	Italn Garden White Wine Vinegar 1 Ltr	Food	Pcs.
9cfcb677-342c-4de7-b201-23c49b617c4e	c1	Itelian Garden Chipotle Peppers in Adobo Sauce 215g	Food	Pcs.
0c19b4d0-f2ac-424a-a79b-6b06dfda891a	c1	Jacker Wafer Cube 100gm.	Biscuts	Pcs.
e4aa3ce8-a2ab-4478-b6fe-74589312db5c	c1	Jaggic Gud Atta Biscuit-Pack of 2	JAGGARY	Pcs.
13937fc1-eb18-4aea-bf94-217472aa6c21	c1	JAGGIC GUD CHANA	JAGGARY	Pcs.
30e52130-b8e4-4a3d-9906-fb65d31a8d9a	c1	JAGGIC GUD IMLI LADOO	JAGGARY	Pcs.
f19b275e-d071-482f-a46e-4557c45023f9	c1	JAGGIC GUD MILLET BISCUIT	JAGGARY	Pcs.
932dfc03-2314-424f-85a1-63130fef6c54	c1	JAGGIC GUD NAMKEEN BISCUIT	JAGGARY	Pcs.
7a14d492-c3f6-45d3-b248-f3f66676f98f	c1	JAGGIC GUD RUSK -PACKOF 2	JAGGARY	Pcs.
3136de08-408b-43b5-afa9-5cb874287d99	c1	Jaggic Jaggery Cubes 500g	JAGGARY	Pcs.
02fad391-030a-4cea-890b-cd9697b1a9ba	c1	Jaggic Jaggery Powder-500g	JAGGARY	Pcs.
6cd4ebe5-c560-44d8-b262-ee329969f847	c1	Jalapeno Sliced in Jar 720 Ml (Imp)	Food	Pcs.
be04241c-133d-4166-9a47-ac9013ace15d	c1	Jalapino  Slice 3.1kg Caneen	Food	Pcs.
12dcf719-579b-4279-80bf-b7c118898177	c1	Jamun Bar 80gm	Food	Pcs.
53667d6c-edf1-4719-9cfd-a1684a7db7d3	c1	Jamun Juice 500ml	Food	Pcs.
a8178349-76b7-4223-82b3-34032881dbe4	c1	JAMUN JUICE 800 ML	JUICE	Pcs.
4c646243-e4c0-4add-bf24-f094fec6755f	c1	Jamun Powder	Food	Pcs.
0b03591a-1a6c-4563-890f-b0514cd98cd5	c1	Japanese Style Mayonnaise 1 Ltr (Yilin)	Food	Pcs.
bd0964c1-b06d-47cb-ab6e-da6cb8b75f1f	c1	JAR	GURU FOOD	Pcs.
738314a0-9386-4564-bdef-03eef08a6d38	c1	JASMINE RICE 1KG.	Food	Pcs.
16eb05e4-3337-4332-91c6-c8a89a4ca3bc	c1	Jasmine Rice 2 Kg (MAHABOONKRONG	Food	Pcs.
65eb2c03-d712-40d4-9fed-707c9d55e3ed	c1	JB Coin Stick (12%)	Food	Pcs.
15bc7ed3-c14a-4557-8cdc-f30d3ce42e4a	c1	Jb Sugar Boiled Confectionery 168 Gm	Food	Pcs.
6f7d834a-e7cd-40e2-bdd3-7eeb700fae4a	c1	Jb Sugar Boiled Confectionery in Strip	Food	Pcs.
8c7c1444-a929-466c-b47c-02f0618d56b3	c1	Jb Sugar Boiled Confectionery on Box	Food	Pcs.
ac5ecbfc-50e9-4bd9-9631-b602796f4c7b	c1	Jelly Candy Drop	Food	Pcs.
58f2c890-3f18-403e-99f0-d1ebc96ccbbc	c1	Juice 1 Ltr. Delmonte	JUICE	Pcs.
fa1be94d-0d13-43b0-b202-83bc022ef95f	c1	Julee&apos;s Oat 25 Ten Grains 200gm.	Biscuts	Pcs.
568c0449-de0b-412f-9ad7-388d4c506a23	c1	Julee&apos;s Oat 25 Ten Strawberry&apos;s 200gm.	Biscuts	Pcs.
183884db-6180-4cba-ab41-aac35f73ab18	c1	Julle&apos;s Oat 25 Haz.&amp; Chocolate Chip 200gm	Biscuts	Pcs.
2c838102-2008-463c-b0f9-b30ef4899beb	c1	Jullies Puff Chees	Biscuts	Pcs.
b198e1e6-900c-43ca-93cc-7f514a1df75d	c1	Jullies Puff Lemon	Biscuts	Pcs.
d52d45c9-bb30-41ba-afd7-c45a69446d84	c1	JUSCOCOCO COCONUT WATER 330ML Mrp.90	Drinks	Pcs.
2e7a98da-96b5-46ac-aad9-7d2c076dd905	c1	JUSCOCO COCONUT 200 MI(Un Register)	Drinks	Pcs.
21b528dd-352b-4ad8-80dd-fb6bf5217b4c	c1	Juscoco Coconut Tetra 150 Ml (Rs20)	Drinks	Pcs.
5c880cf8-9c3e-487b-9318-6d895c9c51a6	c1	Juscoco Coconut Tetra 200 Ml Mrp.40	Drinks	Pcs.
2faca5a2-48b5-4729-bf1a-2c1a21025b08	c1	Juscoco Coconut Wat 330 Ml Mrp 80	Drinks	Pcs.
c01305f7-f29e-403d-b17b-aee2deb0d29a	c1	JUSCOCO  COCONUT WATER 150ML.	Drinks	Pcs.
8ae0cff1-2aa9-442b-a076-b10d05470313	c1	JUSCOCO COCONUT WATER 150ML.MRP.25/-	Drinks	Pcs.
8ecd33eb-44f4-4edb-8d44-720e359e89aa	c1	JUSCOCO COCONUT WATER 1LTR.(UN REGISTER)	Drinks	Pcs.
bc2c0861-5fd5-41ad-acd9-72186ea326da	c1	Jus Coco Coconut Water 200ml(50mrp)TETRA	Drinks	Pcs.
d4db3552-ec67-4213-adc4-bec62c645542	c1	JUSCOCO COCONUT WATER 200ML MRP.30 (30x1)	Drinks	Pcs.
44c1a423-0fbc-46ce-82dc-85c232fbbfd8	c1	Juscoco Coconut Water 330ml Mrp.50	Drinks	Pcs.
cd131626-3b2b-4d42-8bcf-dc4e9686320d	c1	Juscoco Coconut Water 330 Ml Mrp.60	Drinks	Pcs.
6e95d6e2-9e85-4ee7-b113-9b53d2616e20	c1	JUSCOCO COCONUT WATER 330ML Mrp.70	Drinks	Pcs.
0210048c-13a8-4bfc-93e1-9c8fa48ac0fb	c1	Juscoco Coconut Water &amp; Rose 330 Ml Mrp.50	Drinks	Pcs.
e75c8190-7f82-4287-a085-322465766683	c1	Juscoco CW 200 Ml Bottle  (12%)	Drinks	Pcs.
819c6ddc-f5f7-4de3-8e4b-0de631f8a667	c1	JUSCOCO CW 200ML MRP.RS.45/-	Drinks	Pcs.
4c997054-7454-48d1-96a8-a778c828d676	c1	JW CHUNK IN BRINE 185 GM	Food	Pcs.
b10fb77c-c6e6-443f-9748-9e7ee647045e	c1	JW TUNA	Food	Pcs.
45fef88a-9d16-4259-a28a-1015794d4dbb	c1	KABLI CHANA 1 KG	Food	Pcs.
ac73c6ec-dbc0-4a79-9bc3-005aaa97800e	c1	KALA MATA OLIVES 370ML.	Food	Pcs.
a4de9694-a329-400e-9632-cb3a8e26261d	c1	Kare in Adlt.Daiper L-10	Sanatry Napkin	Pcs.
91070a41-eccd-4530-9809-dce6c5082a13	c1	Kare in Adlt Daiper Large 10&apos;s*12	Sanatry Napkin	Pcs.
f38a4b69-bfd2-452b-bcaa-0f14c2c2a943	c1	Kare in Adlt. Daiper M-10	Sanatry Napkin	Pcs.
390a8daf-437e-418e-bee3-e99f534df72b	c1	Kare in AD PULL UPS L-10 RS.600/-	Sanatry Napkin	Pcs.
1aeaf774-efd9-48ad-9733-853a65b11d3b	c1	Kare in Classic AD Pants Medium-10X12&apos;spacks	Sanatry Napkin	Pcs.
b98c0220-32f7-4c89-85d0-cef7efa7267f	c1	Kare Med AD-L10	Sanatry Napkin	Pcs.
8f532107-a40f-43d9-8b30-548ececa912d	c1	Kare Med AD-M-10	Sanatry Napkin	Pcs.
07c41638-a7ef-49c2-bacd-fb7233f9be89	c1	Kare Med AD - M12 Mrp.500	Sanatry Napkin	Pcs.
660b457e-0399-4d30-b5d4-3645de22cbd4	c1	Kare Med Classic AD L-10	Sanatry Napkin	Pcs.
0f9b5fc0-b4af-4124-aaae-0d2659083f9a	c1	Kare Med Under Pads L12 (1*16) Mrp.500	Sanatry Napkin	Pcs.
71adf356-6dce-43d3-8626-bf5a81f17e0f	c1	Karo Corn Syrup	Food	Pcs.
5918bad0-3ce4-4a3d-8159-c97812554bac	c1	KATO Grape Juice 330ml.	Drinks	Pcs.
40b73d0d-60a5-4d29-8e42-18f6797d15f8	c1	KATO Melon Juice 330ml.	Drinks	Pcs.
ddcda1bb-6065-4663-922f-b0a47e6ec65a	c1	Kato Orange Juice 330ml.	Drinks	Pcs.
6e0041eb-1605-443c-881b-8730bc0fa1ab	c1	KATO  Strawberry Juice 330ml.	Drinks	Pcs.
25754296-32e2-44f4-a4bb-a75a10624392	c1	KAYZ CORNFLOUR 1KG	Food	Pcs.
4bbbd701-1f5f-41de-8bbf-dc2bb37d694d	c1	Kellogg&apos;s All Bran Wheat Flakes 400 Gm	Food	Pcs.
f62a1035-72df-40c7-9718-98e82fd4b9d6	c1	kellogg&apos;s all bran wheat flakes 440 gm	Food	Pcs.
40494d70-bf85-4b66-9c1e-999853ede13a	c1	kellogg&apos;s chocos 675 gm	Food	Pcs.
b7397d6c-dbab-4e72-9da3-1983caa15f02	c1	Kellogg&apos;s Chocos 715 Gm	Food	Pcs.
44cdcb86-27d5-4ecd-997f-56b8f45ed4d9	c1	kellogg&apos;s CORN FLAKES 288g	Food	Pcs.
28eb066f-6781-4325-b665-625811b03315	c1	Kellogg&apos;s Corn Flakes 475 Gm	Food	Pcs.
fad937ca-71a0-44e8-9c5e-b4f50cc230bb	c1	Kellogg&apos;s Muesli Fruit &amp; Nut 500 Gm Mrp.360	Food	Pcs.
7d8cca79-6279-447c-8860-aa0721648cfe	c1	Kellogg&apos;s Muesli Nut Delight 500g.	Food	Pcs.
12376715-55fe-4771-81d4-7159d12bb9e8	c1	Kellogg&apos;s Oats 900 Gm	Food	Pcs.
32777fcb-7f45-4c72-b0ea-f27e4898686a	c1	Kellogs Cereal Froot Loops	Food	Pcs.
c3be4f00-d226-4136-8f64-add732904218	c1	KELOGS CHOCOS 127G.	Food	Pcs.
0bdf326e-3ab3-47df-befa-6405494f9172	c1	KELOGS CHOCOS 700G	Food	Pcs.
d0e4c640-846c-4645-9b8f-9b3ce22628f0	c1	Kelston Ms	Cosmatics	Pcs.
3336c53a-7c0d-466e-8885-03b417b9c074	c1	KESU PAAN (20 PCS MIX FLAVOUR )	PAAN	Pcs.
cc0765cb-4529-4000-805d-3be392b7a90e	c1	Kewpie Mayonaise 520 Ml	Food	Pcs.
78b74090-235d-4663-9c27-f33550a19e3b	c1	Kewpie Mayonnaise 310gm	Food	Pcs.
016545d8-1029-4cde-af0e-01d73196e0cf	c1	KEWPIE MAYONNAISE 520 ML SAUCE	Food	Pcs.
44f28885-4def-4953-b030-dcfa475ec324	c1	Keya Italian Pizza Oregano	Food	Pcs.
47e1250e-af97-4917-b894-0407d1cbbce4	c1	Keya Peri Peri Sauce Bottle	Food	Pcs.
760678d7-b360-4b76-b884-aff32b7e7788	c1	Keya Sezwan Sauce Bottle	Food	Pcs.
83e576b4-43d4-434a-9749-82146b67b76e	c1	KEYA SRIACHA SAUCE	Food	Pcs.
a7743b1a-830d-4fa4-b12f-029e8152231e	c1	KF ULTRA BOTTLE 300ML.	Drinks	Pcs.
1b39caaf-d5ec-40d0-a083-b1aa7afce58c	c1	Khajoori Guda 250g	Food	Pcs.
0cd81f3e-7f65-456b-961d-ba6da5d01215	c1	KHASOBUSHI	Food	Pcs.
748de759-5d65-4ff0-ae50-a15968e48c45	c1	KIDNEY BEANS / CHICK PEAS	Food	Pcs.
f781ecfe-840b-4cc6-9be6-b99b76eb3ed5	c1	Kikoman 1 Ltr (Soya Sauce)  Mrp.435	Food	Pcs.
badd568c-2cce-48f0-a4a3-63a86e8bde2d	c1	Kikoman 500 Ml Soy Sauce	Food	Pcs.
edda1207-b94b-4221-b1e5-0a12b4aa8776	c1	Kikoman Soya Sauce	Food	Pcs.
1cf4c123-ee24-4a06-8e6d-586f130707cb	c1	KIKOMAN SOYA SAUCE 1 LTR.	Food	Pcs.
f6bfeb83-52e6-4368-8935-e9ca93399576	c1	KIKOMAN SOY SAUCE 150 ML	Food	Pcs.
4b03a79b-10ae-46db-b56f-61a26af16ca8	c1	KIKOMAN SOY SAUCE 1 LTR (Imp)	Food	Pcs.
c804e25c-4258-49e0-a389-3b70f7b31e7b	c1	KIRIN YELLOW KIRIN FLOOR 1KG	Food	Pcs.
08827bc0-4e65-4a49-a5b2-19302870b657	c1	Kissan Tk 200 Gm Mrp.56	Food	Pcs.
47800055-3ed8-4f83-945e-73872b3d8b2e	c1	Kit Kat Bits 250 Gm	&#4; Primary	PKT
3b3b4099-64e4-4819-b227-2c70b453708c	c1	Kitty PANKO BREAD CRUMB WHITE 1KG.	Food	Pcs.
4ae1daa8-48a4-43da-951a-f277b70f7cdc	c1	Kitty Panko Bread Cumb White 15 Kg	Food	Pcs.
8ebf9246-5648-4c86-a11d-b8e61a465be5	c1	Kiwi Strawberry Flav 300ml Mrp.Rs.55/-	Drinks	btl.
610482dd-abb3-4008-8324-d56640029bf1	c1	Knoor Aromat Seasoning 500gm	Food	Pcs.
37c55045-d852-4c1f-b94c-cbddb56a1578	c1	Knoor Aromat Seasoning Powder 1kg.	Food	Pcs.
214324aa-ed84-435d-9a3d-c218a5060979	c1	Knoor Chicken Seasoning 1kg	Food	Pcs.
9ed46d18-1608-422a-ad65-11c83bdb6e99	c1	Knoor Rostip Chicken Seasoing Powder 800gm	Food	Pcs.
c10a8297-7f63-41ee-9aeb-2ccdc73f5af0	c1	Knorr Seasoning Cubes	Food	Pcs.
68ff4d0c-c72b-46bc-ab41-56c242930f72	c1	Kokos Natirel Beetroot Powder 200gm	Food	Pcs.
a892e0be-207a-4dc1-bc7d-080b5cc8b32d	c1	Kokos Natirel Cassava Flour 400gm	Food	Pcs.
765c63d9-b297-4de6-b444-2cd119b005a7	c1	Kokos Natirel Immunity Powder 150gm	Food	Pcs.
0c20d534-d76b-4f37-8d09-41fd4a5e2154	c1	Kokos Natirel Raw Banana Flour 500gm	Food	Pcs.
3a6d242b-4681-484c-ac58-721e2b1da3ab	c1	Kokos Natirel Supergreen Powder 150gm	Food	Pcs.
62f44d52-cbfb-43b1-95d2-8e864e4cc0b7	c1	Kokos Natirel Tropikoko Coconut Flour 400gm	Food	Pcs.
c14dcc85-d86b-47d5-9916-49ab17921986	c1	Kokos Natural Himalayan Pink Salt 200gm	Food	Pcs.
e02eaf7c-5d46-4336-94ba-bb20a4889ad6	c1	Kokos Natural Tropikoko Organic Coconut Sugar 125gm	Food	Pcs.
5a5a6521-532e-4d2b-b152-18dd9b1e2609	c1	Kokos Natural Tropikoko Organic Coconut Sugar 250gm	Food	Pcs.
133a2bca-9d5e-40f6-9861-a8bdfeba2fcc	c1	KOKUHO ELLOW SUSHI RICE 10 KG	Food	kg.
7a6bfdf2-a359-426e-8d1f-efb8559bb93a	c1	Kokuho Yellow Sushi Rice 22.680 Kg	Food	Pcs.
d1f05541-1ca0-4e96-92fc-221edc6b6d68	c1	KOKUHO YELLOW SUSHI RICE 2kg	Food	Pcs.
b003ba90-dbc2-4801-8d5b-57eb582dcd37	c1	KOLESTON MS 302/0 Black AP-DE	Cosmatics	Pcs.
daf306d4-86e5-495d-8987-6090c64c4175	c1	Koleston MS 303/0 Dark Brown AP Dem	Cosmatics	Pcs.
90089cc4-79f3-4566-beef-ef02e537cab9	c1	Koleston Ms 303/4 Dark	Cosmatics	Pcs.
e1953129-3200-4bd4-b461-b22f5445d002	c1	Koleston MS 304/0 Medium Brown AP DEM	Cosmatics	Pcs.
4006665a-7c46-428a-bdec-aaf472a8b904	c1	Koleston MS 304/5 DARK MAHOGANY AP DEM	Cosmatics	Pcs.
8f3cce21-e0a9-4ae9-a631-88a330882937	c1	Koleston MS 305/0 Light Brown	Cosmatics	Pcs.
bc833d0a-938f-4bb8-93c3-846dfb0e4a63	c1	Kraft Bbq Original Sauce	Food	Pcs.
576b3fc3-0366-4f90-9a92-bfb68024641c	c1	Kraft BBQ SAUCE Thk N Spy Orignal 510g	Food	Pcs.
a8a53747-59bf-461b-9202-3b718bf0c6c6	c1	KRAFT CHEDAR BLOCK CHEESE	Food	Pcs.
2f86fe6f-ad3f-47a1-ba44-c4b60209b273	c1	Kraft Cheddar Cheese	Dairy Products	Pcs.
b8a4468f-ce9f-4bc4-8a59-13374d38ca2c	c1	Kraft Chees Spread 190 Gm (Tin)	Food	Pcs.
85adcc74-3109-4d49-958b-a5bb9189eb3e	c1	Kraft Macroni N Cheese	Food	Pcs.
2c35b875-e26b-4377-a57b-034b8e8abf06	c1	KRAFT PARMESAN CHEESE	Dairy Products	Pcs.
c3b7c89e-303c-40a9-a5a2-91192a1069a0	c1	Kraft Permeson Flavoured Powder 85gm	Food	Pcs.
12d9b565-e2ac-4219-9ac1-6a7cfb70df57	c1	Kraft Permision Cheese	Food	Pcs.
3836bf6f-7f5f-4a47-bfa5-70f616c4e2a0	c1	KRAVEMORE COCONUT WATER 300ML	Food	Pcs.
d2ba5de2-fc16-402e-9f00-1dfc2f90a751	c1	Kravour Wafer Biscuits 8g.X45pcs	Biscuts	Pcs.
af626dff-8795-49fd-83ec-82fb031742b0	c1	Krj Msp Cheese	Dairy Products	kg.
663b3ec3-7841-4bb3-9ccd-2e41476c90d1	c1	K SOYA SAUCE 1LTR.	Food	Pcs.
aeb5290f-0fe6-46f1-aecf-ce44a5cbdee4	c1	Kunafa Pistachio	Food	Pcs.
7ca86285-49fc-48bf-9b53-9e83a2f579b6	c1	LA Apple 150gm.	Biscuts	Pcs.
cfe58c81-a985-4d36-b0e8-3a90dd006588	c1	LABEL	Packing Material	Pcs.
fab4f27d-993f-43ef-b054-c23116622df4	c1	LABEL 5%	Packing Material	Pcs.
a65b4035-ca49-4fb4-8425-2fc6df7696fc	c1	LA Cookies Hazelnut 150gm.	Biscuts	Pcs.
6f9ff7f8-37d8-4d82-9c33-32aebfabe961	c1	LA COSTEN Black Bean Whole 560gm	Food	Pcs.
15d860ce-6c41-4c8e-aaff-d6a71124abf2	c1	Lady Finger Biscuit 200g.	Food	Pcs.
32bb8cac-6cc1-48fe-ae68-b8178018e178	c1	Lady Fingers 200 Gm (18%)	Food	Pcs.
76f6977f-0748-4943-ad7c-9610081755f0	c1	LADY FINGERS BISCUITS	Food	Pcs.
315dda16-f439-4777-ba7f-3bb927c46d2b	c1	Lamasia Extra Virgin Oilve Oil 5 Ltr	Food	Pcs.
de77bcb5-834d-4892-9df5-5fa6302d33a1	c1	LAMASIA POMACE OLIVE OIL 1 LTR	Oil	Pcs.
e4033a26-b538-4756-8f90-a6d3dc0150ab	c1	LAMASIA POMACE OLIVE OIL 1LTR. PET	Oil	Pcs.
bd6efb2f-8730-419c-9cb2-8dd96613bafc	c1	LAMASIA POMACE OLIVE OIL 5 LTR TIN	Oil	Pcs.
971ee18c-0b54-42c1-b2b3-5c5ff1276732	c1	La Nature&apos;s Green Tea 25 Sachet	TEA	Pcs.
322670b6-85f5-451d-8b51-e891a04cbbd1	c1	Landessa Ice Caffelatte (230 ML) Mrp.250	All Items	Pcs.
110685fd-668b-4c27-a561-f0369795640d	c1	Landessa Ice Coffee Cappuccino (230 ML) Mrp.250	All Items	Pcs.
3d6d0c1b-3668-4c0b-b27e-8f3b239e1735	c1	Landessa Ice Coffee Vanilla (230 ML) Mrp.250	All Items	Pcs.
c58679b7-1713-423c-a328-e4751dfaf88b	c1	Langnese 250 Gm Golden Clear Honey	Food	Pcs.
5000e442-6cf2-4f0b-bc6f-9fb8049a10c8	c1	Laoganma Spicy Chilly Sauce 210 Gm (12%)	Food	Pcs.
969f1c1c-c4f3-46f2-a0ad-33985454a0e0	c1	Lavazza	Food	Pcs.
c60f3344-4205-49ec-b421-fa188367ce3d	c1	LC Peanut Butter Creamy 510gm	Food	Pcs.
a3bac258-9103-4d0e-ac39-68493b15980d	c1	Le Chef Almond Powder 1kg	Food	Pcs.
1e0855db-c6ed-4330-80e4-c85242003230	c1	Le Chef Asparagus White 330gm	Food	Pcs.
551b454a-0c30-498f-a08f-3a0e151b0e4e	c1	Le Chef Balsmic Glaze 250 Ml	Food	Pcs.
13853050-fd90-4252-ae19-35ff741e5375	c1	LE CHEF BBQ SAUCE 510g	Food	Pcs.
c4d69fb1-b5ea-4af0-9f8b-58cf45db0a5e	c1	Le Chef Black Olives Sliced 3 Kg	Food	Pcs.
43853a73-16a2-4e34-924d-a981070461fe	c1	Le Chef Black Pitted Olives 450gm	Food	Pcs.
8674c599-44fa-46f4-a724-a3b4899f11ce	c1	LE CHEF BREAD CRUMB 1KG	Food	Pcs.
28b93189-e803-4388-8daf-0dc6da5c0093	c1	Le- Chef Cooking Sake 1.8 Ltr	Oil	Pcs.
2abd1479-f5bc-49e2-8d99-53324e692ab7	c1	Le- Chef Green Pitted Olives 450gm	Food	Pcs.
f8d08884-619f-4ab8-a599-538d789be12e	c1	Le- Chef Jalapeno Sliced 3kg	Food	Pcs.
2c1a6b64-8b97-4412-be1b-1a740b8bd359	c1	Le-Chef  Lady Finger Biscuit 200	Food	Pcs.
6bccf3bd-2b0f-4ab0-b64f-3a8843abf1e3	c1	Le-Chef  Lady Finger Biscuit 400g.	Food	Pcs.
3959ef84-892e-493f-973e-4c91c450cb04	c1	Le Chef Lychee in Syrup 800g	Food	Pcs.
466770ab-60c2-465f-9028-9a663889f3f8	c1	Le Chef Peanut Butter Creamy 340g	Food	Pcs.
6f4ef6c1-83a4-4a0a-80dc-2fdc83ccc829	c1	LE CHEF PEELED TOMATOES 2.55KG	&#4; Primary	CAN
cf501e46-22b3-4f87-b1f2-6275cc4cc813	c1	LE- CHEF PERI PERI RED SPICY 100g	Food	Pcs.
bb83b7de-d05b-4286-aec5-829af369311e	c1	Le Chef Prunes 227 Gm	Food	Pcs.
61788011-e0a2-4129-940a-84d93680da81	c1	Le Chef Red Paprika 680gm	Spices	Pcs.
8e3eb6d7-022e-47f0-8e59-8bd760dc8b21	c1	LE CHEF SHAO SHING VINEGAR 640 ML	Food	Pcs.
6ef8e4e7-0897-42d3-8866-411ad5f23190	c1	Le Chef Straw Mushroom Whole in Water	Food	Pcs.
7d85892b-0fb5-4995-a631-4a305b7fde56	c1	Le-Chef Water Chesnut 567 Gm (12%)	Food	Pcs.
6890bd73-ec85-45d1-8b45-3e0fb534b86d	c1	Le Chef Yellow Peach Halves 820g	Food	Pcs.
e31bbee0-dd74-4536-9d77-219f58388ddd	c1	Lemonade Flav 300ml.Mrp.55/-	Drinks	btl.
62747d6b-084f-486e-a612-857653b3bf53	c1	LENG HENG BLACK SESAME 1KG	Food	Pcs.
2c6fa47d-c61c-4b6c-be62-5fe0caf31771	c1	Leng Heng Ginger Pickle 1400g	Food	Pcs.
101c3ed0-bcf3-4a59-bf8c-154290aa427b	c1	Leng Heng Ginger Pickle 1500gmJAR	Food	Pcs.
da563e06-10c7-4ab1-8e80-6f8d9c74a701	c1	LENG HENG GINGER PICKLE 1.6 Kg.	Food	Pcs.
90b0d087-5231-416d-bcae-728f5b31c876	c1	Leng Heng Hua Tua Seasoning 640ml.	Food	btl.
287422ba-12e3-4428-b909-b11029c649c8	c1	LENG HENG RICE VINEGAR 750ML	Food	Pcs.
234843dd-09d3-4829-999c-53043e4ca8d2	c1	LENG HENG WHITE SESAME 1KG	Food	Pcs.
7ede2a30-c9e8-4245-8f82-f03ef13808f3	c1	Lex Cream Biscuit Cheese 190 Gm	Biscuts	Pcs.
2e1f2e54-4caa-4f49-babd-b953517cab07	c1	Lex Cream Biscuit Cheese Flv 60gm	Biscuts	Pcs.
d34b5798-31ec-421f-a2e3-c69d0881fe1b	c1	Lex Cream  Biscuit Cheese Hlv 152gm	Biscuts	Pcs.
034b731a-810d-48fd-8f8f-cde49f14b07d	c1	Lex Cream Biscuit Chocolate 190 Gm	Biscuts	Pcs.
c63cd332-4ac5-46a3-bcd8-d8c139b64657	c1	Lex Cream Biscuit Chocolate Flv 152gm	Biscuts	Pcs.
3664d0f6-1ea9-4482-b6fb-91d6ac4bcf33	c1	Lex Cream Biscuit Chocolate Flv 60gm.	Biscuts	Pcs.
2e0231be-fd60-445d-b0dd-6f3e2226686e	c1	Lex Cream Biscuit Lemon 190 Gm	Biscuts	Pcs.
165dc6c3-d086-4289-9c7d-1a577f938183	c1	Lex Cream Biscuit Lemon Flv 152gm.	Biscuts	Pcs.
1f071984-6afa-4521-8501-cf2e5f20c5db	c1	Lex Cream Biscuit Lemon Flv.60gm.	Biscuts	Pcs.
c95781b4-3fcd-4439-bb3b-76292852751b	c1	Lian How Sesame Oil 630 Ml	Food	Pcs.
81dca7bd-b898-412c-9d48-e3b0b2bf5e7f	c1	Light Soy Sauce 765g Smiki Suprior	Food	Pcs.
918288e8-b752-4aa9-b150-c9b3e12e0e5b	c1	Limca 1.25 Ltr Pet	Drinks	Pcs.
5d00d9e2-153b-4e10-946b-eb4f2a1c5a69	c1	Lindt Excellence 70% Dark 100 Gm	Chocolate	Pcs.
dffbcf7f-4f5f-48c4-ab1f-a1a728778343	c1	Lindt Excellence 85% Dark 100 Gm Mrp.400	Chocolate	Pcs.
7f36905e-6489-4b4f-ac69-c9340759e719	c1	Lindt Excellence 90% Dark 100 Gm Mrp.450	Chocolate	Pcs.
05f58b7b-ddff-4d54-b702-f687570bbf8a	c1	Lindt Excellence 99% Dark 50 Gm Mrp.400	Chocolate	Pcs.
e0cde4b1-def3-4e98-9d42-468ec9925582	c1	Lindt Excellence Black Currant 100 Gm Mrp.300	Chocolate	Pcs.
5debf65d-1423-43b3-8f1f-b35066c72c34	c1	Lindt Excellence Chilly Dark 100 Gm Mrp.300	Chocolate	Pcs.
9da805a8-47b7-4dd3-b4c4-5e731ee332ea	c1	Lindt Excellence Dark Caramel 100 Gm Mrp.300	Chocolate	Pcs.
ff79e9f3-2fb1-42a3-9c5f-bd91de10e2e0	c1	Lindt Excellence Extra Creamy 100 Gm Mrp.300	Chocolate	Pcs.
ee2a7197-a4fd-4602-95fa-fc64f78ffdf7	c1	Lindt Excellence Orange Intense 100 Gm Mrp.400	Chocolate	Pcs.
a5f8a412-5cda-4e0b-be9f-04739b6e71f6	c1	Lindt  Excellence Salt Dark 100 Gm Mrp.400	Chocolate	Pcs.
d9d3f38e-f25b-4aa7-906f-c45d4ccb7407	c1	Lindt Lindor Singles 60% 100gm Mrp.350	Chocolate	Pcs.
cd0260a4-d233-49fe-ac09-941985bc42c9	c1	Lindt Lindor Singles Milk 100 Gm Mrp.350	Chocolate	Pcs.
f5c56209-c9f8-4ee7-a714-a5757629f718	c1	Lindt Lindor Singles White 100 Gm Mrp.350	Chocolate	Pcs.
e776d20e-0d68-4470-babd-e4653909e92f	c1	Lindt Swiss Classic Almond SF Bar 100gm Mrp.290	Chocolate	Pcs.
56e7d5c1-50cc-40f9-8da9-d4ea0a343d97	c1	Lindt Swiss Classic Dark Hazelnut 100 Gm Mrp.290	Chocolate	Pcs.
65756ed4-3223-44a1-9e5c-2c6dcc556b6d	c1	Lindt Swiss Classic Hazelnut SF 100gm Mrp 290	Chocolate	Pcs.
80a93682-dfc1-41d3-bffd-8fbd305ffb9a	c1	Lindt Swiss Classic Milk Sf 100 Gm Mrp.250	Chocolate	Pcs.
446289a8-d5fb-48f6-9651-f032553ce5a1	c1	Lindt Swiss Classic Raisn/n SF Bar 100gm Mrp.290	Chocolate	Pcs.
b3f4b3e5-5616-40cf-8b6d-438b67f93b3b	c1	Lindt Swiss Classic Surfin 100 Gm Mrp.250	Chocolate	Pcs.
c8f207bd-70d8-418a-9e46-9045d079c88a	c1	Lindt Thins Milk 125gm Mrp.590	Chocolate	Pcs.
344d4d7e-cbc5-4d37-82f1-066f176f818c	c1	Lipton Green Tea (5%)	Food	Pcs.
76a4b444-d579-4660-8615-68b96fe50da9	c1	Lipton Ice Tea 240ml	TEA	CAN
69978600-5714-43f8-927c-957aea9a132d	c1	Lipton ICE TEA CAN 245 Ml	TEA	Pcs.
beb1c59a-78f3-4cf7-9010-0bc333a1a672	c1	Lipton Ice Tea Can (Peach) 245 Ml	TEA	Pcs.
a6da5143-f36c-4421-aa5e-f0784e8c4d84	c1	Lipton Ice Tea Lemon 325 Ml (18%)	Food	Pcs.
5de87142-788b-4657-9c6a-17ee8c76083a	c1	Lipton Yellow	TEA	Pcs.
a5d6def1-6eca-4f27-8253-1cec12c5ea58	c1	Lipton Yellow Lable Tea	TEA	Pcs.
29417438-8516-410b-a5d0-6da33859a175	c1	Lipton Yellow Tea (5%)	Food	Pcs.
84a71398-1ef0-4c36-8d93-a3f5bf4f5392	c1	Lkk Blackbean Sauce	Food	Pcs.
10ddf8af-adb2-4673-92ee-6f4b008fbafd	c1	Lkk Black Bean Spicy 226 Gm	Food	Pcs.
1a287499-1d3f-4273-8ab0-5b0556ea3e5f	c1	(LKK) CHILLI BEAN SAUCE 226G	Food	Pcs.
6a1c1d5b-476a-4a3a-81fa-eb428095a56d	c1	Lkk Chilli Garlic Sauce	Food	Pcs.
f5f2521a-cb85-4e52-87d5-3311c4e5f7ea	c1	LKK CHILLI GARLIC SAUCE 226G	Food	Pcs.
f3c03487-401d-46e3-9cfa-16aaca8ab541	c1	L.K.K DARK Soya Sauce 500ml	Food	Pcs.
2a7d8ed9-05c5-430a-8433-59751f74c786	c1	LKK Dark Soya Sauce Superior 1.9 Ltr	Food	Pcs.
fe89daf7-2c3b-4c78-9a12-0f14d3f0dc4b	c1	LKK HOISIN SAUCE 240G	Food	Pcs.
6f50ae9f-4e68-40d1-ae95-5bc37e7d47ec	c1	LKK Light Soya Sauce 1.9 Kg	Food	Pcs.
1503b097-46f4-4935-94ee-1622af8ff71d	c1	L.K.K Light Soya Sauce 500ml	Food	Pcs.
1ded9a37-738c-4a97-9443-91a8580b02dc	c1	LKK Oyester Souce Vegitarian 510ml.	Food	Pcs.
e5b2159b-2f74-4e09-b1fe-991d7715ef54	c1	LKK PANDA BRAND OYESTER SAUCE 2.2 Kg	Food	Pcs.
b1ab2034-f24d-4073-a67b-463cab89359e	c1	Lkk Panda Non Veg Oyester 510 Gm	Food	Pcs.
588e3bf5-50cc-40aa-aa99-3219bb6de276	c1	Lkk Panda Veg Oyester Sauce 510 Gm	Food	Pcs.
53cda979-b190-4537-865a-3f9e1b161714	c1	LKK PLUM SAUCE 260G	Food	Pcs.
fb9678f5-cc71-4de7-8a5f-8018e7b2294c	c1	Lkk Pure Seasme Oil 200 Ml	Oil	Pcs.
a1e96220-6801-45c8-be30-0ce8dc1fb2e2	c1	LKK TERIYAKI SAUCE 250GM	Food	Pcs.
c0217528-1c4e-4f9e-905f-e2f34b00fc12	c1	Lkk Xo Sauce (Extra Hot) 220gm	Food	Pcs.
5a54414b-9135-474d-bd7c-bedd603eee6a	c1	Ll Baby 4 Pcs Grooming Set-Blister Pack Mrp.229	BABY PRODUCTS	Pcs.
34430880-504b-437d-ac84-f74cc8833fac	c1	Ll Baby Bottle Cleanser 1000 Ml Mrp.549	BABY PRODUCTS	Pcs.
fa304743-3633-482a-8384-fa69783f01a4	c1	Ll Baby Bottle Cleanser 500 Ml Mrp.349	BABY PRODUCTS	Pcs.
27410638-33fe-42f0-93aa-a26376d7bd25	c1	Ll Baby Detergent 1000 Ml Mrp.549	BABY PRODUCTS	Pcs.
e9cd13fc-5642-4276-8ae8-b18bf167f915	c1	Ll Baby Detergent 500 Ml Mrp.349	BABY PRODUCTS	Pcs.
a3c7a441-084d-4944-9da3-7de8b4e41ad2	c1	Ll Baby Wipes 2+1 Pack Mrp.198	Sanatry Napkin	Pcs.
dd9ce865-48ea-43a8-b77a-c4389901d665	c1	Ll Baby Wipes 72+8 Pack of 2 (Save Rs.50)	Sanatry Napkin	Pcs.
7d1b8dd8-371d-4576-8759-12900f3bdfce	c1	LL Baby Wipes 72+8 Pack of 3 MRP 297	Sanatry Napkin	Pcs.
3dfac798-ed08-47d6-ac33-b698b9919342	c1	LL Baby Wipes - 80&apos;s Pack Rs.99/-	Sanatry Napkin	Pcs.
2690bcce-34a6-4cc5-9376-a5d26babf974	c1	Ll Baby Wipes Aloevera 72&apos;s	Sanatry Napkin	Pcs.
ba2ab7c6-bfd4-400c-a718-340066109e3a	c1	LL Baby Wipes Aloevera with Lid 72&apos;s	BABY PRODUCTS	Pcs.
83b3b8bb-2274-488d-92b4-7b104c20ece7	c1	Ll Baby Wipes Jojoba Oil 72&apos;s	Sanatry Napkin	Pcs.
51ad160b-deba-4845-8675-18897c748540	c1	Ll Baby Wipes Sensitive 72&apos;s	Sanatry Napkin	Pcs.
0553ca65-28ce-4a3c-91b0-fad7562a1395	c1	LL Bbay Wipes 20&apos;pack	Sanatry Napkin	Pcs.
2c48c49a-b46f-4a8c-86d6-9da0b232abc7	c1	LL Birdie Sipper 160ml. Blue Rs.455/-	BABY PRODUCTS	Pcs.
fe0dd452-646c-47a2-86cf-7e5f01a8e860	c1	LL Disposable Breast Pads 24 Packs Mrp.179	BABY PRODUCTS	Pcs.
0971ecfd-6672-4cf8-9519-a6eecc8dc251	c1	LL  Dolphin Sipper 160ml. Pink MRP.RS.425/-	BABY PRODUCTS	Pcs.
6dfee8fc-1bcf-41f4-b58d-c6cf7cb2432d	c1	LL Elegant Baby Carrier -Black &amp;Green	BABY PRODUCTS	Pcs.
85c5a7f1-3ae3-43ed-bad1-6d21346cc456	c1	Ll Hippo Spout Cup 225 Ml Green Mrp.265	BABY PRODUCTS	Pcs.
be21ab0c-175a-4cf7-a782-f3d863c14da1	c1	Ll Hippo Spout Cup 225 Ml Orenge Mrp.265	BABY PRODUCTS	Pcs.
116af64f-0a76-4207-9fc8-4b072252b31f	c1	LL Jumbo Sipper 240ml Green MRP.RS.275/-	BABY PRODUCTS	Pcs.
16e1c40d-1a88-45a2-a10d-8d88f576ed20	c1	LL MANUAL BREAST PUMP RS.799/-	BABY PRODUCTS	Pcs.
69b69723-995c-4f2a-984b-cf8292ff06f4	c1	Ll Mosquito Repellent Patch (12pcs)	BABY PRODUCTS	Pcs.
395291f2-645c-4314-b7eb-a11394ab1129	c1	Ll Mosquito Repellent Roll on (10ml)	BABY PRODUCTS	Pcs.
e1a0ab20-e101-47f9-b4a5-0f1799000f25	c1	Ll Mosquito Repellent Spray (100 Ml)	BABY PRODUCTS	Pcs.
a7eddfc7-6463-4c8c-a51f-90e4e76b34cc	c1	LL Steam STERLIZER 3 IN 1 RS.2995/-	Electrical Goods	Pcs.
68d68804-acba-45d4-846c-b9864630d261	c1	Loacker Classic Creamkakao 90g	Chocolate	Pcs.
0d569282-491d-4cba-8b0d-22ebd4395017	c1	Loacker Classic Nepolitaner 250g	United Distributor	Pcs.
e5f5855a-c296-4dda-8ac7-77f3ca5990c4	c1	Loacker Classic Nepolitaner 90g	Chocolate	Pcs.
75683090-d7e6-416a-a3ca-8a85a055b369	c1	Loacker Quadratini Cacao 250g	United Distributor	Pcs.
538caa59-f417-49f6-9cb3-d2fb7fed5e1a	c1	Loacker Quadratini Dark Chocolate 125g	Chocolate	Pcs.
13600369-614e-45f2-add5-4029a4182122	c1	Loacker Quadratini Vanille 125g	Chocolate	Pcs.
e87cbe75-e7cd-4649-b621-554d87052108	c1	Longobardi Peel Tomato	Food	Pcs.
47ec84d3-1fb8-46d1-bf54-a4d2d8a7d639	c1	Lotus Biscoff 125 Gm	Biscuts	Pcs.
57bafdde-b508-497d-88d2-68437cba50e4	c1	Lotus Biscoff 250 Gm	Food	Pcs.
25252214-071c-409c-aba4-b9641e3ef458	c1	Lotus Biscoff 250 Gm(Imp)	Food	Pcs.
bc5b2a7a-66ba-4a4c-9d67-a6180b93c290	c1	Lotus Biscoff Biscuits (Imp)	Food	Pcs.
e9525876-e24e-4fb2-9493-b33a0fe35edc	c1	Lotus Biscoff Family Pack 250 Gm (18%)	Food	Pcs.
5838d3dd-f771-4313-b667-d5320d1f12c6	c1	Lotus Biscoff Spread (12%)	Food	Pcs.
c48d249e-a881-4ea2-80a3-8e8cf9de3d56	c1	Lotus Biscoff Spread (18%)	Food	Pcs.
693da114-7862-4153-9079-b497679e8d25	c1	Lotus Biscoff Spread 400 Gm	Food	Pcs.
e0079b56-4459-4450-9814-aced6c9e8c61	c1	Lotus Biscoff Spread 400 Gm @18%	Food	Pcs.
cffe586f-a37d-4651-9f11-9edb44ea00fa	c1	Lotus Biscoff Spread 400 Gms	Food	Pcs.
2829f659-7a14-4d6b-8a1f-6ae180cc8a89	c1	Lotus Biscoff Spread @ 12 %	Chocolate	Pcs.
8281f321-7b59-40e9-bb85-33cf08ecf548	c1	Lotus Biscof Sandwich Biscoff Cream	Food	Pcs.
98898303-fbbf-4d3c-bf91-daff13ce692d	c1	Lotus Biscof Sandwich Vanilla 110g	Food	Pcs.
2a177d6d-294c-47f6-b389-5013edd8622f	c1	Lotus Smooth Biscoff Spread 400 Gm	Food	Pcs.
36210091-bf62-4f61-8016-71991980830e	c1	Lotus Spread Bucket 8 Kg	Food	Pcs.
7067c008-7968-4728-a680-7b0e212b8d64	c1	Lozenges Green Stripe 25g	Food	Pcs.
930ab037-93d8-4321-892a-444ff4642172	c1	LUCIANA ARTICHOKE IN BRINE 400g	Food	Pcs.
05f76050-7080-48cd-a94c-f415ce08b614	c1	Luciana Bamboo Shoot Halves	Food	Pcs.
bd4535f0-67dd-4c00-9b6d-3dc826b39591	c1	Luciana Black Olives Pitted	Food	Pcs.
eafc2d3c-b23d-4134-967f-18b1d8d70b3a	c1	LUCIANA BRAND OREGANO 1KG	Food	Pcs.
a3d179ba-4364-47f5-9fbd-39918297638f	c1	Luciana Bread Crumbs 1 Kg	Food	Pcs.
8657b1f1-df64-4703-b5a4-2bda6dabbaa4	c1	Luciana Cajun Spice Seasoning 500g.	Food	Pcs.
e34725ef-1186-4661-89cb-e74a0c68ac2f	c1	Luciana CANNED WATER CHESTNUT567G	Food	Pcs.
cb669a2a-824e-49c5-a2a4-ab300cd8b9e2	c1	Luciana Capers Vinegar 3.5 Cyl	Food	Pcs.
2c3de86f-f15a-48ce-ad8d-b1cbefbb8a4b	c1	Luciana  Chilly Flakes 1kg.	Food	Pcs.
a7ffc21c-63e1-4ca1-a1dd-2280d6be83da	c1	Luciana Cocktail Onions 350g	Food	Pcs.
0d1de653-91e9-4c14-aebf-7084397ef04f	c1	Luciana Garlic Powder 400g	Food	Pcs.
eac018fc-4707-4668-bba9-5dfbf6203cc1	c1	Luciana GHERKINS IN JAR 720 ML	Food	Pcs.
7498faf7-ccc3-421c-81af-b00d74a896a8	c1	Luciana Green Olives Pitted	Food	Pcs.
435fb809-9f13-425a-8366-281131c018ec	c1	Luciana Jalapeno Sliced A-10	Food	Pcs.
49430714-c15d-4452-8262-b2795d00b4bb	c1	Luciana Jalapeno Sliced in Jar 720 Ml	Food	Pcs.
255eb0f1-a580-4a9c-b4e8-5433bebbb73d	c1	Luciana Jalapeno Slices IN JAR 720ML.	Food	Pcs.
496b6326-ff65-4028-9887-1e5c2294f408	c1	Luciana Onion Powder 400g.	Food	Pcs.
0442e5ee-25a0-4fb8-b491-3481d07988ba	c1	Luciana Oregano (Pizza/pasta Seasoning)	Food	Pcs.
e0a05d18-deb1-4212-8c90-15bfde0aed59	c1	Luciana Panko Bread Crumbs 1kgs	Food	Pcs.
3f218852-ace3-4a38-8d72-744da97d000b	c1	Luciana Paprika Seasoning 454gm	Spices	Pcs.
81fa9a37-262f-4e00-8b47-057dac947704	c1	Luciana PEEL TOMOTOES	Food	Pcs.
d9d923b9-1d71-44ff-856a-222f6dc4a415	c1	Luciana Peri Peri Seasoning 500g.	Food	Pcs.
59de9610-afe7-47c4-966c-2345a8fb5683	c1	Luciana Rosemery 1 Kg	Food	Pcs.
d0ee7653-a63a-4b82-8756-8e74b8878828	c1	Luciana Sundried Tomatoes in Sunflower Oil 320 Ml	Food	Pcs.
74a2606c-40a9-4b14-874f-04f3436c20fe	c1	LuvLap 4 in 1 Slim Steel Sipper with Cover Blue	BABY PRODUCTS	Pcs.
6843fd0d-330a-4949-8b35-4798ce8e5adf	c1	Luv Lap Baby Care Oral Hygiene Combo Mrp.229	BABY PRODUCTS	Pcs.
be4c4770-e555-499f-b776-1cc9d020cfbd	c1	Luvlap Diaper	BABY PRODUCTS	Pcs.
1403b57a-3533-4d0e-800e-3851aef3bc1f	c1	Luv Lap Easy Squeezy Food Feeder 90 Ml Mrp.319	BABY PRODUCTS	Pcs.
99b72e9b-771f-45dc-b960-c9d4d125394d	c1	Luv Lap Elegant Baby Comb &amp; Brush Set Mrp.219	BABY PRODUCTS	Pcs.
ae45df2a-a80b-4151-a3b2-c08cf6a1935c	c1	LuvLap Ess Neck F Botl, 125 Ml Jungle Tales Mrp.125	BABY PRODUCTS	Pcs.
8673cc4e-11e2-4565-8e85-cef8c18bd6f8	c1	Luv Lap Ess S Neck F Botl 125 Ml W Flowers Mrp.125	BABY PRODUCTS	Pcs.
68273e41-76b3-4d58-98c6-00a71f4014fc	c1	Luvlap Ess S Neck F Botl,250ml Jungle Tales Mrp.155	BABY PRODUCTS	Pcs.
6ba8254f-4ce1-4875-8510-3c3dff4baa19	c1	Luv Lap Ess S Neck F Botl,250ml W Flowers Mrp.155	BABY PRODUCTS	Pcs.
fc6645c2-7e86-49a0-ba5a-937c6c381c77	c1	Luv Lap Ess S Neck F Botl, Plain 125 Ml Mrp.115	BABY PRODUCTS	Pcs.
9e01dab1-f1d2-49dd-a117-0981f7314c04	c1	Luv Lap Ess S Neck F Botl, Plain 250 Ml Mrp.145	BABY PRODUCTS	Pcs.
f1f4ff76-5a3c-4cd8-aeb5-94f29dcaddf2	c1	Luv Lap Flo W Neck F Botl,250ml Red Blue Floral	BABY PRODUCTS	Pcs.
8d957047-0450-4e24-9476-6d4f2f02cbc9	c1	Luv Lap Heartfills Food &amp; Fruit Nibbler Mrp.219	BABY PRODUCTS	Pcs.
13f4ddea-eabe-49d2-90dc-0eabbee713aa	c1	Luv Lap Joystarfood &amp; Fruit Nibbler Mrp.199	BABY PRODUCTS	Pcs.
6ae77c12-424f-4c23-9997-10be4dfb66b9	c1	Luv Lap N Flo W Neck F Botl150ml Red Blue Floral	BABY PRODUCTS	Pcs.
29b5c43f-96e4-4130-b5fe-b1b2fad22965	c1	Luv Lap N Flo W Neck F Botl150ml Stars Mrp.175	BABY PRODUCTS	Pcs.
9a7eaa17-da70-4b7d-81db-0385a1b80288	c1	Luv Lap N Flo W Neck F Botl,250ml Stars Mrp.195	BABY PRODUCTS	Pcs.
c3967bbf-43d8-4e8e-9043-316578339dd6	c1	Luv Lap N Flo W Neck F Botl, Plain 150 Ml Mrp.165	BABY PRODUCTS	Pcs.
1e67dfef-fbb2-4966-8eb6-5aa38c81fbef	c1	Luv Lap N Flo W Neck F Botl, Plain 250 Ml Mrp.185	BABY PRODUCTS	Pcs.
dea46236-52c1-4a1c-a790-da181b34020b	c1	Luv Lap Pearly Food &amp; Fruit Nibbler Mrp.219	BABY PRODUCTS	Pcs.
0ffb1917-330f-4b2d-a852-d2067b57189c	c1	Luv Lap Silicone Teether - Pizza Pie Mrp.249	BABY PRODUCTS	Pcs.
77ba3cf8-a495-443b-8058-9ee181978b46	c1	Luv Lap Silicon Teether - Milk Time Mrp.249	BABY PRODUCTS	Pcs.
1e76da2e-2503-4ca1-a32b-baa280d6d6da	c1	Luv Lap Silicon Teether Yum Scoops Mrp.249	BABY PRODUCTS	Pcs.
0eb34315-47da-4a18-92d9-482583b3f242	c1	Luvlap Silicon Theether Yellow Duck Mrp.249	BABY PRODUCTS	Pcs.
73110713-4a5b-47ac-8745-dde779e549be	c1	LUVLAP STEEL FEEDING BOTTLE 240ML	Confationery	Pcs.
2a371b3a-7cbc-4ab5-a08a-8fc4f45d89e2	c1	Luv Lap Sunshine Teether Mrp.269	BABY PRODUCTS	Pcs.
2949f674-c6c4-4e08-adbb-e564e85419ff	c1	Luv Lap Tiny Love Heat Sensitive Spoon Set Mrp.159	BABY PRODUCTS	Pcs.
6c324f0c-48ef-4c4b-94a8-cbad630dd44e	c1	Luxeapers Black Pitted Olives 430gm.	Food	Pcs.
ead45ddd-459e-4198-9a6c-8f74a09bd929	c1	Luxeapers Black Sliced Olive 3 Kg	Food	Pcs.
eb6b7e7e-b767-43f3-8c36-a8ab22251fbd	c1	Luxeapers Black Sliced Olive 430 Gm	Food	Pcs.
b6b6bd21-bbdb-4e60-a502-2b633d798fe3	c1	LUXEAPERS CAPERBERRIES	Food	Pcs.
21a6ea33-ba53-46e4-9353-cd23b137588c	c1	Luxeapers Capers 100 Gm	Food	Pcs.
dfd71555-87b8-445d-af6c-bdfaf014e3a8	c1	Luxeapers Green Peppercorn 110gm	Food	Pcs.
2c3ac634-15ed-45a4-a630-d486e34c926e	c1	Luxeapers Green Pitted Olives 420gm.	Food	Pcs.
03b56313-36ef-4020-b2d8-e719fcc69871	c1	Luxeapers Peri Peri Chilli	Food	Pcs.
abcc7d34-c069-4368-b340-e70cb0e5e5be	c1	Luxeapers Sundried Tomatoes	Food	Pcs.
d34f3442-af82-40c0-af7c-a67ff1132ef4	c1	mabu coco juice apple 320ml	Drinks	Pcs.
a04810a4-d5ea-441d-9367-094e226b4ca5	c1	mabu coco juice grape 320ml	Drinks	Pcs.
b08e078f-9621-4e2d-b267-29a3775f76d6	c1	Mabu Coco Juice Lychee 320ml	Drinks	Pcs.
26c4c21f-c914-4df9-a4c0-7ea06fd85bfb	c1	Mabu Coco Juice Mango 320ml	Drinks	Pcs.
b6f71688-b51a-487c-bc45-d57a4248e76a	c1	mabu coco juice melon 320ml	Drinks	Pcs.
62c6522f-ab2a-4ee2-8788-ab0fc380c9c6	c1	Mabu Coco Juice  Orange 320ml	Drinks	Pcs.
749d1dc8-7a61-4e75-97d0-c0644dc220f8	c1	Mabu Coco Juice Peach 320ml	Drinks	Pcs.
09447d73-e6d8-4083-b613-fd716b95214e	c1	mabu coco juice pineapple 320ml	Drinks	Pcs.
e9365991-7dbf-4fc7-98d0-a0219fc0b922	c1	mabu coco juice strawberry 320ml	Drinks	Pcs.
92f81102-924f-431d-bef5-f2a5f8060808	c1	Mac 3 Fruit Marm 340g	Drinks	Pcs.
ebcd72fd-0377-4aca-9a1b-4595e793859e	c1	MAC BLUE BERRY &amp; BLACKCRUUNT 340G	Food	Pcs.
f36d16d4-fc66-428c-86bf-dbd91596ebb3	c1	MAC BLUEBERRY &amp; BLACKKUCURNT 340G	Food	Pcs.
f6d93d61-9bc5-414e-9222-9994a80eb251	c1	Mac Donald Pure Maple Syrup 370 Ml	Food	Pcs.
726c5464-f159-45a3-b670-842a3c7cda50	c1	MAC ORANGE/LEMON/GINGER 340G	Food	Pcs.
4be5a325-a609-4a96-82ce-85459c21bf60	c1	Mac Scottish 3 Berry 340g	Drinks	Pcs.
1fea32c5-2021-4069-813e-f557cebc1c73	c1	Mac Scottish Strawberry 340g	Drinks	Pcs.
3a6a81bf-7cfe-4b00-9caa-a4f749163a7c	c1	MAC SEVILLE ORGANGE MARM 340G	Food	Pcs.
7344abc5-70fe-4a6a-8e30-0855d0a9bcf9	c1	Madras Curry Powder 500 Gm	Food	Pcs.
2b477624-4d01-48df-990b-5be04e0eaaae	c1	MADRASI CURRY POWDER 500GM	Food	Pcs.
39186c29-d163-4f35-9a22-1945a124449c	c1	Maekrua Oyester Sauce	Food	Pcs.
229a7c3b-7857-4936-8984-8f36989e8ca8	c1	Mae Ploy Vegetarian Green Curry Paste 1 Kg	Food	Pcs.
e45c8426-2d1d-44f7-9b50-f6105f61f250	c1	MAGGI CHICKEN CUBE (12%)	Food	Pcs.
ed5df311-4bf1-4995-82c5-b1587b3b97e4	c1	Maggi Coconut Milk Powder 1 Kg.	Food	Pcs.
5818c97d-d9ff-40ab-a5c7-5b6a43e87d58	c1	Maggi Coconut Milk Powder 1kg.Mrp.	Dairy Products	Pcs.
2ac863fd-3775-4fb3-8083-e099d3b838c0	c1	Maggi Coconut Milk Powder 1 Kg Mrp.665 (18%)	Food	Pcs.
e011524c-40c8-4fc5-9ce9-650b3d172003	c1	MAGGI COOKING SOUCE 680ML	Food	Pcs.
86500c19-3df8-4008-8d79-688473b2029f	c1	Maggie	Food	Pcs.
7a162b72-0465-466c-8c22-d9ac5b20aefe	c1	Maggie Chicken Cube 18%	Food	Pcs.
fa84caa5-7d25-4bcd-872f-00e5343e0d74	c1	Maggie Cube Veg	Food	Pcs.
19a1d1fc-95d1-4a85-906b-68ff1e9cdec3	c1	MAGGIE SEASONING 160ML (IMP)	Food	Pcs.
d1d05848-0768-41ac-a482-8ca0a3859a5d	c1	Maggie Seasoning 200 Ml Imp	Food	Pcs.
24233113-73b1-449a-8046-e8ce612ade41	c1	Maggi Liquid Seasoning 200 Ml	Food	Pcs.
f55d8d03-2f08-4f77-af4e-0bb20923e5f5	c1	Maggi. Liquied Seasoning 200ml	Food	Pcs.
a9418437-f2fe-4d30-a9bd-3bfb44346f86	c1	MAGGI SEASONING 200ML.@18%	Food	Pcs.
c178b944-c4b0-4d08-b623-cea3cc4671bc	c1	Maggi Seasoning Sauce 800 Ml (12%)	Food	Pcs.
ccaceab7-32be-4824-8130-8c5a1517761d	c1	Maggi Seasoning Sause 200ml.	Food	Pcs.
5f9f8dc1-477f-40be-9432-cecc89d69e5b	c1	Maggi Stock Sauce N.Veg (6*1.2 Kg ) (My)	Food	Pcs.
edab8432-0a35-414e-8192-a66ebad6f6e7	c1	Maggi Stock Sauce Veg (6*1.2kg) My	Food	Pcs.
85a5ca99-b075-4969-8497-b64d340a4a5a	c1	Maggi Veg Cubes 20gm	Food	Pcs.
ccc054d6-5005-492d-b817-b81e6240e26d	c1	Maida	Biscuts	kg.
3c6aa502-fefc-4aad-bfef-e63bc968efcd	c1	MAILLE DIJOHN MUSTARD	Food	Pcs.
0d4e824f-b807-4afa-b0c6-c0ffd8e4ddaf	c1	MAKHANA-BBQ JAR	GURU FOOD	Pcs.
ef595854-2548-4710-9af1-9075b7e0bada	c1	Makhana Chips	GURU FOOD	jar
801bd634-3349-4146-a0dc-7b87931e28cb	c1	Makhana Classi 250	Food	Pcs.
f9cbbc16-f71d-4b08-b0b4-caaf068e2faf	c1	MAKHANA -CRISPS	GURU FOOD	Pcs.
5dff647b-a55c-468d-9b00-da2bfdc2515f	c1	MAKHANA FUSION	GURU FOOD	Pcs.
2c30d44d-34a1-404f-a673-55cf964aea77	c1	MAKHANA -PERI PERI	GURU FOOD	Pcs.
9ad39d18-1f47-418b-ab31-09c26d6acd0e	c1	MAKHANA -PUDHINA	GURU FOOD	Pcs.
192d910a-dec6-4809-9961-090c5984a396	c1	Makhana -Salt&amp; Black Pepper Jar	GURU FOOD	Pcs.
28f6910f-b332-41d7-9e90-386f6197cc8d	c1	Makhana (Salted)	GURU FOOD	Pcs.
27f14afd-2410-43b6-b70f-fe9c3c58cc98	c1	Makhana Tomato Chilli	GURU FOOD	Pcs.
29890ee9-2120-4a87-8b87-29990bc89bd6	c1	Makhanna Chips Jar	GURU FOOD	Pcs.
c315c47c-96ca-46b0-af19-44f64bc2cff3	c1	Makino Nachos Jalapeno 200 Gm	Food	Pcs.
3cecca16-38b8-4721-a577-c50abd0489bc	c1	MALA	Drinks	Pcs.
69c75172-af86-46a1-bbf6-bb31a403515e	c1	MALA BLACK CURRANT CRUSH 1LTR	Drinks	Pcs.
df7b4068-bf80-443d-a0d9-4ceffe82ba48	c1	MALA BLACK CURRUNT CRUSH (1LTR.)	Drinks	Pcs.
5230f454-4012-4146-b522-e0adc64de593	c1	MALA BLUEBERRY CRUSH (750ML)	Drinks	Pcs.
5a1cb8fd-7474-4bc9-8e04-cdb9e4dc9d82	c1	MALA KIWI CRUSH (750ML)	Drinks	Pcs.
8b925bd3-1281-4f63-bb0b-0ee026a3c02a	c1	MALA LITCHI CRUSH (1LTR.)	Drinks	Pcs.
f28f78e2-39ce-42de-8dfa-429c82b04b63	c1	MALA MANGO CRUSH	Drinks	Pcs.
9180a96b-f32a-43fb-bab8-e8beafa9d28c	c1	MALA  ORANGE CRUSH (1 LTR.)	Drinks	Pcs.
44956d42-633a-48dc-a431-927cc481a28e	c1	MALA PINEAPPLE CRUSH	Drinks	Pcs.
b207c271-787a-455f-a3c2-b79c74032c1f	c1	Malas Black Current 700 Ml	Drinks	Pcs.
c66508b9-0bc1-47ab-b3de-868c1898a46e	c1	MALA STRAWBERRY CRUSH (1LTR)	Drinks	Pcs.
5b858b7b-5ef2-4f9a-8b8c-15d8bb0e58a1	c1	Manama Banana Crush 1 Ltr	Drinks	Pcs.
52a09125-1ed2-45bf-9ca9-57d009c49522	c1	Manama Black Currant Crush 1 Ltr	Drinks	Pcs.
9e4664b3-d789-4c0d-9c3a-7d56b1d709f0	c1	Manama Black Curren 750 Gm	Drinks	Pcs.
51e94339-e4b5-4ffa-8689-acf33c52dfcb	c1	Manama Blue Berry Crush 750 Ml	Drinks	Pcs.
5eba853f-805c-4a2b-98a8-d5f0db02e285	c1	Manama Butter Scotch Syrup 1 Ltr	Drinks	Pcs.
b02448e9-8dda-415d-b17b-c1ddab850ed6	c1	Manama Chocolate Syrup 1 Ltr	Drinks	Pcs.
905be2b4-287f-47ae-85a3-5f94c2526106	c1	Manama Kiwi Crush 750 Ml	Drinks	Pcs.
0d2f8795-ce6e-4f34-9f52-328e8d46bd53	c1	Manama Lichi Crush 750 Gm	Drinks	Pcs.
781b5dfb-9d57-4726-a544-6544d8f4c559	c1	Manama Litchi Crush 1 Ltr	Drinks	Pcs.
46d4fc39-6db9-44d9-acd5-ba1ccf47e4c7	c1	Manama Litchi Crush 750 Gm	Drinks	Pcs.
2101dec2-a106-4757-b9a9-1966e45c0609	c1	Manama Mango Crush 750 Ml	Drinks	Pcs.
26618106-43b9-4aab-ab15-b016ea72cc7b	c1	Manama Orange Crush	Drinks	Pcs.
47beab4b-7d07-4c20-a57d-3df3f16ea814	c1	Manama Orenge Crush 750 Gm	Drinks	Pcs.
0abf18c8-2d8c-44bf-961d-860d3c9265bd	c1	Manama Peach &amp; Apricot Crush 1 Ltr	Drinks	Pcs.
579abbbb-8687-4001-be89-638e00a862a7	c1	Manama Pineapple Crush 750ml	Drinks	Pcs.
2a1f4893-ab41-416c-a9b6-44151cf42ec9	c1	Manama Strawberry Crush 750ml	Drinks	Pcs.
3398ae10-d130-49fc-9a5f-682101282c7b	c1	Mango Baar (S)	Food	Pcs.
a3b87070-4e9d-46c3-a503-4a0afc525d4f	c1	Mango Barfi (S-4)	Food	Pcs.
1188256b-bd88-466e-b5f4-fda8f0a4c65f	c1	Manora Cracker 500 Gm	Food	Pcs.
e67220f1-e4dd-49ba-856a-89a5f2c2be21	c1	MANORAMA UNCOOKED SHRIMP CHIPS	Food	Pcs.
50120475-0af4-4032-9c83-46fce21e7e09	c1	Mapple Syrup	Food	Pcs.
908cd950-4b90-42c0-ae87-c3f1805ca463	c1	Mara Kidney Beans	Food	Pcs.
3613427c-16f8-44df-a155-7bce6f4ca1f8	c1	MARA PEELED TOMATOES	Food	Pcs.
80659104-5caa-4ebd-881a-6d34b02a6dd4	c1	Marmite Paste	Food	Pcs.
44d9a108-67b3-47ed-b10b-525d411eacab	c1	Marshmallow Bonfire Soft Candy (12%)	Food	Pcs.
0b9c7263-df70-47b9-97b2-d310ebc53731	c1	Mars Milk Shake 350ml.	Drinks	Pcs.
d9d354b6-6be2-43b5-8b47-79d4ba2e4513	c1	MARTINO COUS COUS 12* 500 GRM	Food	Pcs.
01461417-136a-40b5-bcc3-36d40954f3e4	c1	Marvel Edt Doctor Strange 110ML	Deo	Pcs.
b5dcb75c-2820-4c27-a05d-069dcd605c9d	c1	Marvel Edt Doctor Strange Pocket Spray 18 ML	Deo	Pcs.
079b9293-3db7-49cc-94bb-906a15c3cf74	c1	Marvel Edt Hulk 110ML	Deo	Pcs.
810d087c-7d44-4e1d-80a4-c659635e8894	c1	Marvel Edt Hulk Pocket Spray 18 ML	Deo	Pcs.
f22e5e1c-c533-4fa8-b179-6247b4cda728	c1	Marvel Edt Thor 110ML	Deo	Pcs.
6b6355cb-3f09-4235-9be4-12a690d8a51f	c1	Marvel Edt Thor Pocket Spray 18 ML	Deo	Pcs.
e46f4b6f-df35-44e0-8461-7e3f4c9c1692	c1	Marwari Papad Chana Masala	Food	Pcs.
5d192081-eded-4085-8fc6-b14db361ead3	c1	Marwari Papad Moong Spcl.400g.	Food	Pcs.
5c29a3e6-9840-4741-8227-17550aaa467e	c1	Marwari Papad Moong Spcl.Big	Food	Pcs.
bf85fbe1-d28f-40b6-b8eb-b8976a6e90ee	c1	Marwari Papad Panjabi Masala	Food	Pcs.
ede86060-33e2-42b7-987b-3acd2a605b74	c1	Masala Dates 200gm	Food	Pcs.
a40b6497-50b4-469f-9b83-61651a1dbfe3	c1	Mawa Cake 200g	GURU FOOD	Pcs.
caf5d58b-98bd-464f-ba4d-4dac8f76970e	c1	Max Protein 2 Fold Leaflet-Hindi	Chocolate	Pcs.
19dabe21-0aa5-4b12-9d7f-5dc2f6ccfffb	c1	Max Protein Samples Bar -15g.	Chocolate	Pcs.
5cb5c0f9-9cde-4fe6-8fbf-29bec70e5baa	c1	Mayannaise Sauce	Food	Pcs.
1a929fcf-b686-46fb-957c-90bf4edc573b	c1	Mayonaise 1 Kg (Remia)	Food	Pcs.
09eb4e01-13b4-482f-a840-154ae86f8b9d	c1	Mayonnise Kewpie 520gm. Jap	Food	Pcs.
bfc3b5bc-4371-4bfc-8afb-bd3ce693c907	c1	MBK THAI GLUTINOUS RICE (2KG*10)	Food	Pcs.
8903c4b3-4f39-4822-9ebf-4749146cb9aa	c1	MBK Thai Jasmine Rice (Silver) 2kg	Food	Pcs.
2ceb052e-d0a8-4645-b77b-8c9d20893141	c1	MBK THAI JASMIN RICE GOLD 2KG.	Food	Pcs.
0d404bb6-86e4-4190-81ae-e1c66bd30cf8	c1	Mcv Digestive Biscuits 250gm	Biscuts	Pcs.
27d6d942-bfd6-4fab-b379-7d61393f0451	c1	Mcv Digestive Biscuits 400gm	Biscuts	Pcs.
bbf57fde-46de-4460-8fd2-0384e90187b8	c1	Mcv Digestive EW 500gm	Biscuts	Pcs.
50bac263-0eaf-4001-9925-740a0f7562a3	c1	Mcv Digestive Light 250gm	Biscuts	Pcs.
405e351a-2cf0-40f2-945a-6d47279c3089	c1	Mcv Digestive Light 400gm	Biscuts	Pcs.
bd1220cd-2c95-4b49-8c11-a19fd77813a5	c1	Mcv Digestive Light EW 500gm	Biscuts	Pcs.
f0ff1f51-2c36-4702-a1cc-cee26ce70bd2	c1	Mcv Milk Choco Hob Nobs 300 Gm	Biscuts	Pcs.
22d98ab5-5f2f-4345-9da7-b1fb894708a5	c1	Mc Vts Dig.250g.	Biscuts	Pcs.
1124ef2f-9ee9-4a07-ad13-a5bea0d6e4c6	c1	Mc Vts Dig.250g.Lite	Biscuts	Pcs.
47d150df-fe09-4912-9ebd-3899bd05e48a	c1	Mc Vts Dig.400g Lite	Biscuts	Pcs.
3679d464-ca01-44a6-ad7f-6ba8d578c44e	c1	Mc Vts Fruit Shirt Cake	Biscuts	Pcs.
355ece6b-081f-4b2a-9c36-ba933b47bc6d	c1	Mc Vts Gingernut 200g	Biscuts	Pcs.
7f6cbbbf-7115-4ebe-8a51-0b2c86fe21fe	c1	Mcy&apos;s Chock.Misfit Waffer 100g.	Biscuts	Pcs.
42e43bb5-3651-452d-afb1-003f5bf13450	c1	MCY&apos;S CHOC.PLASTIC PACK 400G.	Biscuts	Pcs.
503fedd6-b3c0-4304-80c0-3376a6b99aff	c1	Mcy&apos;s Cream Craker 300g.	Biscuts	Pcs.
731bca4c-0dcd-4b1c-80f6-d94a5fd6304a	c1	MCY&apos;S STRW.MISFIT WAFER 100G.	Biscuts	Pcs.
2642c02f-ebf9-4681-a52b-c64df3653476	c1	MCY&apos;S STRW.PLASTIC PACK 400G.	Biscuts	Pcs.
8bba5569-3b66-491a-b357-f8c00ec5d4ea	c1	MCY&apos;S SUGAR CRAKER 390G.	Biscuts	Pcs.
70a6bf8f-07d1-40eb-8775-a68059b4628b	c1	MCY&apos;S S/wich Craker 300g.	Biscuts	Pcs.
dda7f8eb-6cb3-4a43-8312-73cd5ff79b51	c1	Mcy&apos;s Tatwa 120gm.Almond	Biscuts	Pcs.
76363275-721c-4069-a922-0db11151a8ae	c1	Mcy&apos;s Tatwa 120gm.Choco Chip	Biscuts	Pcs.
4208709e-22ae-4454-b089-b25648823bc1	c1	Mcy&apos;s Tatwa 120gm.Choco Delit	Biscuts	Pcs.
29c071e3-3ae3-48b7-904c-ebcef72ae16a	c1	MCY&apos;S Tatwa 120gm.Hazelnut	Biscuts	Pcs.
c541d67a-7686-4508-86f2-73b26e18e67a	c1	Mcy&apos;s Tatwa 120gm.Strawberry	Biscuts	Pcs.
d1b04ba5-7792-4a8d-a02c-34caff1bdab1	c1	Mcy&apos;s Tatwa 600gm.Romance	Biscuts	Pcs.
6f282ab6-6d20-45ee-9f54-7177ecc3e04a	c1	Mcy&apos;s Tatwa Blueberry 120gm.	Biscuts	Pcs.
dded7557-7f1f-48ad-88c5-7714ff3d5875	c1	Mcy&apos;s Tatwa Cappauccino 120gm	Biscuts	Pcs.
44093b13-f495-4b70-a4ff-c6b482d04b9c	c1	Mcy&apos;s Tatwa Chip Plus 120gm.	Biscuts	Pcs.
ff95086f-bb3a-40af-81ff-c30896fdf459	c1	Mcy&apos;s Tatwa Sweet Masage	Biscuts	Pcs.
bfb9a59d-162f-48ca-b851-f3c4205bc90e	c1	Mcy&apos;s Tatwa Tiramisu 120gm.	Biscuts	Pcs.
01f9d2f9-9131-4d54-abca-e9951ea4df28	c1	MCY&apos;S VEG CRAKER 390G.	Biscuts	Pcs.
c4235455-fe86-4561-a406-2d6c6b2f6545	c1	MCY&apos;S WAFFER TIN PACK 400G.	Biscuts	Pcs.
6e4022a1-8c5c-4026-9f72-884514d75149	c1	Mcy CHOC.MISFIT WAFER 100G.RS.85/-	Biscuts	Pcs.
c1c7432d-01b4-420b-a609-400343007c79	c1	MCY,LEXUS CHLT.150G.RS.110/-	Biscuts	Pcs.
794c4e60-d13a-4c52-85f3-6eaa2a5c1720	c1	MCY,S FESTIVE MIX TIN PACK RS.425/-	Biscuts	Pcs.
b367d0e0-1cab-4596-a1e8-254edc6bf2d3	c1	MCY,S FUN MIX TIN PACK RS.425/-	Biscuts	Pcs.
d9ff3726-b50a-48e7-b632-99029a94c5df	c1	MCY,S HAPPY HOUR TIN PACK RS.425/-	Biscuts	Pcs.
7986c8a8-3c87-4ed2-b1d0-433cdf00db8b	c1	MCY,S LEXUS CHEESE 150GM. RS.110/-	Biscuts	Pcs.
b51bfc54-108d-4f2d-9a0f-275226174e6d	c1	MCY,S LEXUS PEANUT 150GM. RS.110/-	Biscuts	Pcs.
8351b104-6be1-4ed9-a8a0-8861d5da231a	c1	MCY,S MUZIC CHOC 90GM. RS.90/-	Biscuts	Pcs.
467876e2-cc59-4190-a784-d9902658bf3f	c1	MCY,SMUZIC HAZELNUT 90GM.	Biscuts	Pcs.
6f0aeb06-ffd8-4db9-ade6-99b038ed0d07	c1	MCY,S MUZIC VANILA 90GM.	Biscuts	Pcs.
1cbd29f3-09bd-4a64-aea4-24f652ec5aa1	c1	MCY,S SRWY MISFITS WAFER 100G. RS.85/-	Biscuts	Pcs.
416b128a-efed-4360-9c2d-ceadf299ec9b	c1	Mcy,S Tatwa Sweet Tamp.	Biscuts	Pcs.
7429c575-f3e0-4576-b3f4-ad8ed83a479a	c1	MCY,S TOP MIX TIN PACK RS.425/-	Biscuts	Pcs.
79d3fd6c-95eb-4f5d-9a98-1fa69ac9934a	c1	Meat Tenderizer 454 Gm	Food	Pcs.
d908d11b-ee6f-4a78-8a4b-af73aaa07839	c1	Mentos Candy	Food	Pcs.
df0a6386-17d6-40f0-b5cf-061eff0bbda7	c1	Mexikana Tortilla Wrap 480GM	Food	Pcs.
cdd0dcd2-7ef0-4727-94fd-771c41c7b6ab	c1	MIAOW CHEESE BALL POUCH BAG	Dairy Products	Pcs.
dcea55c4-ba8f-4a7b-a0c0-9ab20ad28328	c1	MIAOW CHEESE RING 125GM	Dairy Products	Pcs.
1504d22f-b6ec-4dd4-a6c5-01cd920ef2c0	c1	Miaow Miaow Hot Spicy Pouch 60 Gm (18%)	Food	Pcs.
575ce8da-e233-4591-8aa4-9a0eb7631979	c1	Mild Coloured Cheddar Block 2.5 KG	Dairy Products	kg.
2a1488f4-d836-4e0e-950a-60b3ad4ac2a0	c1	Milky Way Milk Shake 350ml.	Drinks	Pcs.
a049e9d8-b252-45c4-ad74-6f508ab0b280	c1	Millet Protein Shake Assortrd Mrp60	Drinks	Pcs.
9597b753-ed23-4332-9dd8-74aa28089076	c1	MISO DARK 1KG 12%	Food	Pcs.
4280db38-72b2-4ec5-9a88-f11d34c207bd	c1	Miso Light Soya Bean Paste 1 Kg	Food	Pcs.
ce2d94c0-e38f-45e7-9a12-5967d1669481	c1	Miso Paste Shiro 1 Kg	Food	Pcs.
c5c88333-9099-4a19-a6d1-2a66c62f3c1b	c1	MIXED VEG CHIPS JAR	Food	jar
f57b3c8e-6b7e-46fb-acd4-359ad8228d7d	c1	MIXED VEG CRISPIES CHIPES JAR	Food	jar
57f72c20-aa00-40c3-bc44-89cc7093952e	c1	Mix Juice	Food	Pcs.
e319eee8-e161-4af3-accc-59f5333abbfd	c1	Mizkan Kokomotsu Su Grain Flavor Vinegar 1.8ltr	Drinks	Pcs.
49aa69bd-20f5-4b78-bc2c-e95d354a6c8b	c1	M M APPLE JUICE	Food	Pcs.
02abd7b5-3e4b-4887-912c-3033a02621d8	c1	M &amp; M Choco Milk Shake 350ml.	Drinks	Pcs.
d83592ba-9dc9-4476-9a4d-dc46d8ad0142	c1	M M LITCHI JUICE	Food	Pcs.
cf09e6c1-3a30-4873-b46a-c28c71878eac	c1	M M Mango Juice	Drinks	Pcs.
a826ccd7-73d8-4b2a-b203-43cca5e96fd5	c1	M M ORANGE JUICE	Food	Pcs.
1da12156-f8c5-4afa-9dcd-710a55ec8501	c1	M M PINEAPPLE JUICE	Food	Pcs.
764b5f13-40cf-49ca-b567-813dfc2b9b55	c1	M M Strawberry Juice	Drinks	Pcs.
f48a042e-7abd-45ab-82fc-747678bd553f	c1	Mogo Mogu Grape Juice 300ml.	Drinks	Pcs.
0556fed5-d19a-48ed-a028-f8168d05ff9d	c1	Mogu Aloe Cera Apple 300ml.	Drinks	Pcs.
e9a52d93-8a68-4594-94b2-06ed741c601f	c1	Mogu Aloe Vera Grape 300ml.	Drinks	Pcs.
a7bc3e01-80e6-47e2-92db-ae4c228b3e07	c1	Mogu Aloe Vera Lychee 300ml.	Drinks	Pcs.
7e42ca7d-4a11-4f53-9f6d-820e65dd8dce	c1	Mogu Aloe Vera Peach 300ml.	Drinks	Pcs.
0051308b-df72-4604-919e-dc2abadd4d1e	c1	Mogu Mogu Apple 300ml.	Drinks	Pcs.
d0e85778-2447-4b59-bcd1-f3e8443cefbc	c1	Mogu Mogu Lychee 300ml.	Drinks	Pcs.
f6f46a28-389e-4b15-8daa-77304e34b11b	c1	Mogu Mogu Mango Juice 300ml.	Drinks	Pcs.
79573d95-9b85-479c-98d6-7c682a2d2546	c1	Mogu Mogu Orange 300ml.	Drinks	Pcs.
d8e5900d-bd99-43da-9e4c-1086b2f27097	c1	Mogu Mogu Pineapple 300ml.	Drinks	Pcs.
37fd0d3a-3e79-472b-9143-ad7d742654c0	c1	Mogu Mogu Strawberry 300ml.	Drinks	Pcs.
84408a68-7712-4b43-8054-5298b92ed2b3	c1	Mogu to Go Calamansi 180ml.	Drinks	Pcs.
d6ffa44d-320e-4a78-ac51-c99629a6bba8	c1	Mogu to Go Seasons 180ml.	Drinks	Pcs.
a17c3705-3ebe-438f-9e15-a32163dee885	c1	Mogu to Go Sweet T Organge 180ml.	Drinks	Pcs.
40759350-a9f0-4655-bd20-7eeeeeb42d35	c1	Moinin Elder Flower 700ml.	Drinks	Pcs.
c05a7532-d5a9-496b-a7c3-9b5ad8f7b3f1	c1	Moinin Ginger 700ml.	Drinks	Pcs.
b6c62fe2-49d3-4d1e-9de9-7808745de6d8	c1	Moinin Green Apple 250ml.	Drinks	Pcs.
8408f29b-b245-40e8-a55c-631394c5eb9d	c1	Moinin Grenadine 250ml.	Drinks	Pcs.
805ce57c-c1e0-44ed-bbf2-8ea51a4fedc3	c1	Moinin Loreto Small Gerkiness in Venegar 345	Food	Pcs.
67db5dde-3e52-4fb3-8f81-47cf4382a6b3	c1	Moinin Mojito Mint 1000ml.	Drinks	Pcs.
02922299-1a75-4691-955a-c0ed83837ae4	c1	Moinin Mojito Mint 250ml.	Drinks	Pcs.
27ec8a11-dd9d-4bb1-932f-b701b30cafaf	c1	Moinin Peach 250ml.	Drinks	Pcs.
e4ecc28d-d411-4a6c-bfea-253f63aaad89	c1	Moinin Strawberry 250ml.	Drinks	Pcs.
18d2e553-4d97-49b1-9aaf-5889ab92311d	c1	Molasses	Food	Pcs.
09a1248f-9354-42c6-89f1-61df27e75c90	c1	Mom&apos;s Bajara 100g.	Namkeen	Pcs.
c44120d6-9595-4a98-bf50-78bf8a3b4c6b	c1	Mom&apos;s Beej Masoor 125.	Namkeen	Pcs.
8cabf2df-7b5d-4cad-8315-e482c68add32	c1	Mom&apos;s Jawar Puff 100g.	Namkeen	Pcs.
fc988cca-5a54-4b97-b06d-c0f24caa0c55	c1	Mom&apos;s Moong Masala 125g.	Namkeen	Pcs.
08bc4edd-9210-41f5-88f8-0e6e21aa7277	c1	Mom&apos;s Mooth Masala 125.	Namkeen	Pcs.
da183f2d-87c4-47ad-ad11-f69d8d166f55	c1	Mom&apos;s Namkeen	Namkeen	Pcs.
29b6d566-216f-4235-b02c-80ba960547bd	c1	Mom&apos;s Rosted Bajara Puff Masala 125g.	Namkeen	Pcs.
9031fb0b-7272-4492-930b-19ef93f7fe2d	c1	Mom&apos;s Rosted Chanadal (Black Pepper)125g	Namkeen	Pcs.
3469992b-22ec-476c-8007-00d7c462ee4f	c1	Mom&apos;s Rosted Chana Jor Masala 125g	Namkeen	Pcs.
dbe0ea01-5026-4ebb-bce9-c8af6693d0f0	c1	Mom&apos;s Rosted Chana Masala 125g	Namkeen	Pcs.
33d44d9d-e502-4ee4-bd47-fd5a49821973	c1	Mom&apos;s Rosted Penuts Jeera 125g	Namkeen	Pcs.
003a000c-53c9-4bb1-a7db-e2cf8386003d	c1	Mom&apos;s Rosted Rice Flakes 125g.	Namkeen	Pcs.
8e5ae406-d0fa-4ab7-be4d-5e3f5eb04621	c1	Mom&apos;s Rosted Soyabean Masala 125g	Namkeen	Pcs.
a1f7aab0-6657-4cf2-9980-f62d74b73224	c1	Mom&apos;s Rosted Soyabean Salted 125g.	Namkeen	Pcs.
b155dced-d2b8-4eba-bb40-b1dc7bb8f47c	c1	Mom&apos;s Rosted Wheat Flaks 125g	Namkeen	Pcs.
d08b1295-d4fc-4a6c-b616-309927b616aa	c1	Mom&apos;s Wheat Puff 125g.	Namkeen	Pcs.
4d9df7cf-81c7-4db3-bfec-8d297e27401b	c1	Moneta Cookies &amp; Cream Rs.240-	Biscuts	Pcs.
9ca4479e-0cf6-4f24-b301-b2ef299099ed	c1	Moneta Waffers Carmel Rs.240/-	Biscuts	Pcs.
ebf854c9-bdd4-4764-ae47-9a5cd98b7d3f	c1	Moneta Waffers Chocolate Rs.240/-	Biscuts	Pcs.
0c0b124f-eca7-4adb-862a-6865f464f070	c1	Moneta Waffers Strawberry Rs.240-	Biscuts	Pcs.
dcb8c273-7c37-4889-9b59-8c0720803651	c1	MONIN 1 LTR	Drinks	Pcs.
82700b8f-8554-4307-b0e6-3cf9693f31db	c1	Monin Basil 700ml.	Drinks	btl.
172e6ede-51a0-4635-a7aa-1fbb3a2bc60e	c1	Monin Black Berry 700ml.	Drinks	Pcs.
bf137d57-974d-4573-809a-31e990b4b9a5	c1	Monin Black Currunt 700ml.	Drinks	Pcs.
39391125-b249-4070-8db9-3d5dbe0e2047	c1	Monin Blood Orange 1 Ltr.	Drinks	Pcs.
53b67326-98f6-4910-9f20-ef146543d33c	c1	Monin Blood Orange 700ml	Drinks	Pcs.
a2e6d906-d58b-4c02-8ace-fdc82f0cf767	c1	Monin Blue Berry 700ml.	Drinks	Pcs.
b9768ab0-82b3-4633-9a02-0032aecd772a	c1	Monin - Blue Curacao 1 Ltr.	Drinks	Pcs.
625216c2-ba82-4d52-b694-fa1dea40fac9	c1	MONIN BLUE CURACOA 700ML	Drinks	btl.
ae949aa5-2dc8-49ef-91db-b8d4954bef41	c1	MONIN BUBBLE GUM 1LTR	Drinks	Pcs.
a498fcc6-362a-42f6-887c-e69a093b89cf	c1	Monin - Bubble Gum 700ml.	Drinks	Pcs.
a910b136-16ec-4376-9a2c-a042d7bc870a	c1	Monin - Butter Scotch 700 Ml.	Drinks	Pcs.
5ec410f6-e3b4-4183-8a93-c8ccfc3f7ba3	c1	Monin Caramel 700ml.	Drinks	Pcs.
81c87a53-990f-46ee-b887-200bfd69c50e	c1	Monin - Caramel Sauce 1.8 Ltr.	Drinks	btl.
bd4682cf-8b4f-455d-b2ad-dfaf600b96ac	c1	Monin Caramel Sauce 500ml.	Drinks	btl.
754f68e0-57f0-40ae-837c-d455bb8cf14a	c1	Monin - Caramel Syrup 1 Ltr	Drinks	Pcs.
85b8e3ff-95f6-4dbb-9f2a-81134f2f09c7	c1	Monin Caribbean 700ml.	Drinks	btl.
d2587552-298d-4f2b-bb79-c114cabb96ba	c1	Monin Chocolate Cookies 700ml	Drinks	Pcs.
b5154aed-6e78-4593-a9e1-6875098ec9fa	c1	Monin - Chocolate Syrup 700ml.	Drinks	Pcs.
50a7ea53-7f07-4c7a-9e08-fbff8c475ae6	c1	Monin Cinnamon 1 Ltr	Drinks	Pcs.
7df210b7-527e-4dd8-af7d-e07908883ce0	c1	Monin Cinnamon 700ml.	Drinks	Pcs.
f9d1dc6f-87cd-4ff3-853a-84ef9d60e035	c1	Monin - Coconut 700ml.	Drinks	Pcs.
64dd0442-520d-4e53-a6ad-fce36c59d579	c1	Monin - Coconut Syrup 1 Ltr.	Drinks	Pcs.
bc1952c6-a57a-4cb3-afe8-01556a07173f	c1	Monin - Coffee Syrup 700ml.	Drinks	Pcs.
72c5dfd9-c93e-49e5-8be1-49669603396b	c1	Monin Cranberry 700ml.	Drinks	Pcs.
ea9e43e6-36ef-432c-82a5-c30a70fb0383	c1	MONIN CUCUMBER 1 Ltr	Drinks	btl.
5dd3c002-26fc-487c-94e5-b59402f32487	c1	MONIN DARK CHOCOLATE 1.89LTR	Drinks	Pcs.
db6727e8-33f9-43a0-a81c-678a6d857b42	c1	Monin Dark Chocolate 700ml.	Drinks	btl.
9e425fad-c975-4060-8996-4598d653b02a	c1	Monin Elderflower 1000ml.	Drinks	Pcs.
37d8ec4e-16f3-481a-8611-76551e012094	c1	Monin Elder Flower 700ml.	Drinks	Pcs.
3f44e9b9-10f6-4102-966e-5cf98706fc40	c1	Monin Ginger 1ltr	Drinks	Pcs.
2e8a6124-a04c-45c9-ad64-d1efcd023610	c1	Monin - Ginger 700 Ml.	Drinks	Pcs.
7fd60844-15b2-489b-9c3e-7a592aff19e4	c1	Monin - Green Apple Syrup 1 Ltr.	Drinks	Pcs.
4538bd65-3fc8-459f-aaa4-ad6b27a8d8c7	c1	Monin - Green Mint 1 Ltr	Drinks	Pcs.
f65d460a-4245-40f9-837c-2b97a11045b7	c1	Monin Green Mint 700ml	Drinks	Pcs.
29a0c6dc-62e1-4986-a3ca-638dde868a58	c1	Monin - Grenadine 700 Ml	Drinks	Pcs.
479416eb-a9aa-46e7-85db-925310ce5f76	c1	Monin - Grenadine Syrup 1 Ltr.	Drinks	Pcs.
e6751b79-3630-47ac-9759-926cf972d74a	c1	Monin Hazelnut 1000ml.	Drinks	Pcs.
61184070-1a0a-41f4-83b6-5cf1d58d069c	c1	Monin - Hazelnut 1 Ltr	Drinks	Pcs.
473b1c52-4bf7-4958-b056-06d3d9832fb5	c1	Monin - Hazelnut 700 Ml	Drinks	Pcs.
3110224d-c1e1-4b39-bd65-761c289d2ca4	c1	MONIN HAZELNUTS 1LTR	Drinks	Pcs.
1ac7a8f7-8fd0-4d6b-9016-573a7201e5a7	c1	Monin Irish 700 Ml	Drinks	Pcs.
9d9cb013-34dc-4c35-91bd-a1be7e39060b	c1	Monin Irish Cream 1 Ltr	Drinks	Pcs.
63b369fc-f529-41ad-b9d1-b7ba39c39600	c1	Monin - Irish Cream Syrup 1 Ltr.	Drinks	btl.
506dfdf5-c9f5-409f-858b-1fbe9f27c7a0	c1	Monin - Kiwi 700 Ml	Drinks	Pcs.
1d93b614-115b-475c-b4b2-0bbbfe090910	c1	MONIN LAVENDER 700ML	Drinks	btl.
48b7a40c-8108-4270-8579-1096a27088d8	c1	Monin Lemon Ice Tea 1000ml. Mi 147188	Drinks	Pcs.
9b7d58d4-457f-4ae3-9637-b6db4e1d714f	c1	Monin - Lemon  Tea 1 Ltr	Drinks	Pcs.
402e991e-f3e3-4948-8b47-cb3571c6468e	c1	Monin Lemon Tea 700ml.	Drinks	Pcs.
0cc65f48-71c3-4aa5-90d7-d476d7316863	c1	Monin Mojito Mint 700ml.	Drinks	Pcs.
e6c5ed5b-c40e-42f6-b018-67fdcbacd5c0	c1	Monin - Mojito Mint Syrup 1 Ltr.	Drinks	Pcs.
dfdd228d-1cfc-415b-a833-76bf4b917203	c1	Monin - Passion Fruit Syrup 1 Ltr.	Drinks	Pcs.
11466c0c-84b4-4992-a020-d2f8d7348b03	c1	Monin Peach 700ml.	Drinks	Pcs.
0db14d64-b4fc-4cda-9dbf-fbb58a73df51	c1	Monin - Peach Syrup 1 Ltr.	Drinks	Pcs.
8e8c1f91-cf73-43c4-9323-7804adf740aa	c1	Monin Pina Colada 700ml.	Drinks	Pcs.
259a90aa-71be-4ae3-8f80-dc5ad8296bd8	c1	Monin - Pina Colada (700ml) N	Drinks	Pcs.
f472e73a-22e2-4f68-b00c-0813078cae75	c1	Monin - Pomegrante 1 Ltr	Drinks	Pcs.
f21fc577-f6bc-4bfa-8917-564da7dc2cbc	c1	Monin Puree 1 Ltr	Drinks	Pcs.
4b9c3309-f04f-4644-9549-494216bb3fd8	c1	Monin Puree Banana 1ltr.	Drinks	Pcs.
6ff8a82d-8d2c-472b-ad59-fd2cfe262d3b	c1	Monin Puree Kiwi 1 Ltr.	Drinks	btl.
e3ec14e8-33ec-47e1-9930-2b251fd3a11e	c1	Monin Puree Mango 1 Ltr.	Drinks	Pcs.
50f52069-9e8e-48d3-92cc-53b033368b87	c1	Monin Puree Passion Fruit 1 Ltr.	Drinks	Pcs.
5d76f988-eaa9-41ae-985a-dd5f19f7c0ae	c1	Monin Puree Pinapple 1 Ltr.	Drinks	Pcs.
434c8942-f5ba-44be-b4ac-15dca8a81ff8	c1	Monin Puree Strawberry 1 Ltr	Drinks	Pcs.
89e00a06-96c6-4944-ae61-94f135b9bc9a	c1	MONIN ROSE 1 LTR	Drinks	Pcs.
9d29c196-973a-41ed-8829-f52c0470d662	c1	Monin Rose 700ml.	Drinks	Pcs.
319c6b32-e183-4ccc-8df0-6063b21d20af	c1	Monin Sangaria Mix 700ml.	Drinks	Pcs.
5616d0d2-1688-46d4-83ba-8e32912daf33	c1	Monin Sauce Caramel 1.89 Ltr	Drinks	Pcs.
5989a615-a48f-4824-86c5-e5c371077f3b	c1	MONIN Strawberry 1000ml.	Drinks	Pcs.
40c75fe3-d08d-47df-8b19-6dc2e3b39223	c1	Monin -Strawberry 1 Ltr	Drinks	Pcs.
e2dea04c-31c2-41f8-81c0-2267da5b57dd	c1	Monin Strawberry 700 Ml	Drinks	Pcs.
f5a28b4d-1dc1-4187-bb2f-ecbc1b2b7f77	c1	Monin - Tiramisu Syrup 700ml.	Drinks	Pcs.
5bdd102a-66ad-44bb-abfc-fe2d59a0f22b	c1	Monin - Triple Sec 1 Ltr.	Drinks	Pcs.
5d2e482f-5097-4881-8863-7e46a12eb481	c1	Monin - Triple Sec Curacao 1 Ltr.	Drinks	Pcs.
33863e7f-f043-4fef-837b-b68f70871d20	c1	Monin - Triple Sec Curacao 700 Ml	Drinks	Pcs.
5dcc5c23-eb24-4e68-88cc-fe4550f604a1	c1	Monin Vanila 1000ml.	Drinks	btl.
a42673e2-9fbd-4896-8fa9-f6fa9a2c84ec	c1	Monin - Vanilla 1 Ltr	Drinks	Pcs.
03c0d46f-695e-4719-bb83-aefcd341edbe	c1	Monin - Watermelon 1 Ltr.	Drinks	Pcs.
50a8f934-3637-465e-9009-1a44ea584b7e	c1	MONITACRISPY BAKED PRODUCT (CANAPES)	Food	Pcs.
3cfae0fd-ea63-47b2-b422-488211f96c0a	c1	MONITA CRISPY BAKED PRODUCT (CHAT BASKET)	Food	Pcs.
eaeb24ce-3359-4b22-b8f2-c7bc4242a385	c1	MONITA CRISPY BAKED PRODUCT (FAN WAFER)	Food	Pcs.
83b3ac21-37d3-45f1-93c0-036bac11600a	c1	MONITA CRISPY BAKED PRODUCT (PANIPURI)	Food	Pcs.
5c11817a-65dd-4a7b-829e-613b43a1c9a1	c1	MONITA CRISPY BAKED PRODUCTS (EDIBLE SPOON)	Food	Pcs.
baed5116-94e4-4022-916a-ced00739145c	c1	Monosodium Glutamate (MSG)	Food	kg.
769b94ff-290a-4c7b-aec1-6633fac9fb44	c1	Monster 350 Ml	Drinks	Pcs.
60ee217a-6729-4747-b1ae-c0f6192fa93a	c1	Monster Energy Drink Absolutaly Zero 475ml.	Drinks	Pcs.
9d3d1885-8e54-45a6-9fdb-2aebd6279333	c1	Monster Energy Drink Orignak Green 475ml. Free	Drinks	Pcs.
0d058c2e-5e60-4735-9b7b-3a13db206eb8	c1	Monster Energy Orignal Green 475ml.	Drinks	Pcs.
564365b0-0a3e-4f79-a460-33cdc8f7d547	c1	MORCOTE 00 FLOUR 20KG	Food	Pcs.
5a7da7af-c93e-4f66-9292-ac5e7bbfbba9	c1	Morinaga Extra Firm Tofu 349gm	Food	Pcs.
7c39dff4-bcf7-4934-8a8b-e093b6816fed	c1	Morinaga Firm Tofu	Food	Pcs.
9e38f521-78cd-4bcd-8e1c-e3df1df309e7	c1	Morinaga Firm Tofu 349gm	Food	Pcs.
0e38c893-fe09-4ad3-b9d0-a163e5c2875a	c1	Morten Corn Kernal 450	Food	Pcs.
1cddca46-5744-44fc-9f92-e5f6d50626d2	c1	Mothers Mid Blue Berrynfruit Filling 595g.	Food	Pcs.
34405787-b73b-4559-ba51-6d1ab879d5d2	c1	MOUSE	Electrical Goods	Pcs.
833b8ec5-badb-458e-aa0b-abd88237a60a	c1	Mr.Hung Tempura Floor 1 Kg. 5%	Food	Pcs.
cbd20018-609a-4c74-966e-fe526b3926a0	c1	Mr Hung Tempura Flour 1 Kg 18%	Food	Pcs.
501eef91-ae52-4524-98b1-c4a5e1dafd3d	c1	MSD M DEO 150ML.COOL 4590	Cosmatics	Pcs.
9549eb46-618a-483d-9bee-da4b98ac782d	c1	M.S G. CANEEN	Food	Pcs.
b8175a52-443f-416c-9c01-3550250222ef	c1	MT Blue Curacao 1000 Ml	Drinks	Pcs.
aec11642-7b77-4c3a-b669-38165243ee0c	c1	MT Green Apple 1000 Ml	Drinks	Pcs.
ede73853-b8ea-4ef2-b7a5-276b4c892cba	c1	MT Mojito Mint 1000 Ml	Drinks	Pcs.
da86c9e1-c31b-44f6-9115-7cb9f025ac70	c1	MT Triple Sec 1000 Ml	Drinks	Pcs.
4fef458b-2176-4757-a273-1848cd2ac5b6	c1	MUNCHY 100 GM STRAWBERRY	Food	Pcs.
021d33ba-9301-4563-a1a8-27b02337b9db	c1	MUNCHY CHOCO CRACKER	Food	Pcs.
5424bb71-0044-43e3-a559-b3ec217fd55b	c1	Munchy Cracker Veg,Sugar,Cream	Food	Pcs.
d1258ffc-8b09-4ed6-b4ee-08fdd513e4d4	c1	MUNCHY CREAM CRACKER	Food	Pcs.
2fe36ef9-8a8e-48d9-a48d-737f2af64f03	c1	Munchy Waffer Balls	Food	Pcs.
8f26772a-dde7-4eea-991b-12b6fd6c9b77	c1	Murano Sushi Vinegar 250 Ml	Food	Pcs.
b5635662-a096-4ed8-a7b3-4bb7f52c36ba	c1	Murukku Ribbon Jar	Namkeen	Pcs.
cbb8c11a-4c95-4dea-b503-da762b65ba41	c1	Mushroom Porchini Jar/nostim 500g.Jar	Food	Pcs.
a3d0aae4-0f1d-4bb5-8393-cd76f94a3683	c1	MUSHROOM SAUCE VEG.800G.	Food	Pcs.
0d440d0f-7fe8-4742-a7af-e8100efe5b50	c1	MUTLU COUS COUS 500G.	Food	Pcs.
4fbd2642-1fc2-437b-802f-f384faeb1a62	c1	MUTTI WHOLE PEELED TOMATO 2.5KG	Food	Pcs.
b54d52ca-a153-43f3-a512-947f3cd24ed6	c1	Mutti Whole Peeled Tomato Gastronomia 2.5kg	Food	Pcs.
7cf2ec70-c9ee-4c97-809a-c0502aba4ae1	c1	Namjai 50 Gm	Food	Pcs.
e2da24da-9f8c-424f-b450-942759c66d90	c1	NAMJAI BRAND GREEN CURRY PASTE 1KG	Food	Pcs.
36805064-5248-4e27-bb9c-77f238d1d2e4	c1	NAMJAI BRAND RED CURRY PASTE 1 Kg	Food	Pcs.
57e9a7df-2594-4070-8cc9-9eac7c49b1fd	c1	NAMJAI CURRY 400 GM	Food	Pcs.
1307bfce-2178-479f-8e1f-703f749d3e41	c1	namjai  Curry Paste Matsnam 1kg.	Food	Pcs.
41748003-4104-4f61-ab27-0126fe466f3a	c1	Namjai Green Curry Paste 50 Gm	Food	Pcs.
536bb9c7-c0fe-4b57-9ba8-ffb76a30fa03	c1	Namjai (Non Veg) Green Curry Paste 1kg	Food	Pcs.
3a2dc952-b31c-4bac-82dc-391aaacc51f0	c1	Namjai (Non Veg) Red Curry Paste 1 Kg	Food	Pcs.
725df2ec-6293-401b-bb2f-230a5c5944d4	c1	Namjai Panang Curry 1kg	Food	Pcs.
6edfe24e-5fb2-47ec-949d-ec978713357c	c1	Namjai Red Curry Paste 50 Gm	Food	Pcs.
c088b066-4965-4977-bb48-568c737d9f48	c1	Namjai Tom Yum Paste (5)	Food	Pcs.
16b572d6-bf46-41ad-9158-0ebd7e000ebb	c1	NAMJAI VEG  YELLOW CUURY PASTE 1KG	Food	Pcs.
22a9bfa8-7c4a-4a70-8a17-8eaa714461de	c1	Nampla Fish Sauce	Food	Pcs.
cc7fd1e7-1423-4594-bc82-08c4909ca7aa	c1	Nando&apos;s Peri Peri Hot 125gm	Food	Pcs.
0398a11b-e382-4311-b4c3-ab83ad359f5e	c1	Nando&apos;s Peri Peri Sauce Hot 250gm	Food	Pcs.
575ff0d2-de1d-4f96-b5ba-b2ee88e3ead2	c1	Nando&apos;s Peri Peri Sauce Hot 500 Gm	Food	btl.
7ed277e1-7c58-417a-b642-5dedcf4de9a9	c1	Nando&apos;s Peri Peri Sauce Medium 250gm	Food	btl.
99b0d6fb-e943-4faf-a611-2ad28d703023	c1	Nando&apos;s Peri Peri Sauce Xxhot 250gm	Food	btl.
12e95707-fa7d-491d-91b2-9c5acfe37cf5	c1	Nandos Extra Hot Sauce	Food	Pcs.
f5e3ee0d-b3f3-4ac1-a885-9e24cf93ba8f	c1	Nandos Perinaise Garlic 265 Gm	Food	Pcs.
e4316a97-e4ae-4797-8d5c-a3ecb9dfb405	c1	Nandos Perinaise Hot 265 Gm	Food	Pcs.
56758f85-61d0-42c8-b655-d5b24238d7a8	c1	Nandos Perinaise Mild 265 Gm	Food	Pcs.
f5fb9472-ae9e-481d-9287-fa6094b27582	c1	Nandos Perinaise Vegan 265 Gm	Food	Pcs.
23d81ce0-a405-460a-a192-3c2bdacd99a7	c1	Nandos Peri Peri Garlic 250 Gm	Food	Pcs.
7a292f6f-6c63-4217-bc0b-b2787afa5365	c1	Nandos Peri Peri Mild 250 Gm	Food	Pcs.
1f90994e-4ef6-45f9-8462-6a83f9427f31	c1	Nandos Peri Peri Sauce 250gm (IMP)	Food	Pcs.
bc1e1ac2-da2f-4b9e-89f6-d201aeb630fd	c1	Nandos Peri Peri Sauce Hot 250 Gm	Food	Pcs.
b2c8ad5c-be5f-4ab7-8672-2012a062a073	c1	Nandos Sauce (250)	Food	Pcs.
64307c62-c768-467a-9a79-c55850395133	c1	NANDOS SAUCE Garlic Peri Mild BT 250G	Food	Pcs.
40375289-e266-4853-ad88-33b31c408e02	c1	NANDOS SAUCE HOT PERI PERI BT 250ml.	Food	Pcs.
b072a1f6-802c-42ab-8b84-92d51f217659	c1	Nano Glass Clenor Anti Fog	Cleanor	Pcs.
da1e21a7-17fb-4292-88ba-fa6f001d03dd	c1	Nano Glass Clenr&amp;Protactor 500ml. Rs.100/	Cleanor	Pcs.
ddb70342-d5a7-496f-b009-e09a620f1ffa	c1	Nano Imitation Leather Clnr.&amp;Protactor500ml.Rs.150/	Cleanor	Pcs.
93183227-29a4-461e-8de5-2940678ae3d2	c1	Nano Leather Clnr.&amp;Protactor 500ml.Rs.150/	Cleanor	Pcs.
66c41239-9f61-4728-b97d-63979040bded	c1	Nano Luxor Mobile/gadget Cleanor	Cleanor	Pcs.
928a1cf3-ed95-427d-b439-1c53b85b1d4b	c1	Nano Luxor Stainless Steel Cleaner	Cleanor	Pcs.
0c380867-c5b6-47ac-8577-a390e0d27e3e	c1	Nano Luxour Stone Clenor Also Prottector 500ml.	Cleanor	Pcs.
e807fb08-b940-471f-a9c4-8171d6146cd6	c1	Nano Plastic Clnr.&amp;Protactor500ml.Rs.100/	Cleanor	Pcs.
549d6489-cc2b-45b5-bf63-19b3d8aa33ef	c1	Nano Toilet Clnr.&amp;Protactor 500ml.Rs.100/	Cleanor	Pcs.
c9bdf554-e632-4574-9f7b-85b5e28e7589	c1	Nano Wood Clnr.&amp;Protacter 500ml.Rs.150/	Cleanor	Pcs.
a36a28cb-0a12-4162-a615-2d4ffa5fb40d	c1	Narcissus Rice Vinegar 600 Ml (18%)	Food	Pcs.
b44f35c5-6b13-4435-bd61-f7b04ecca9af	c1	NASCAFE GOLD 95 GM.	Drinks	Pcs.
cdae7418-28dd-4c5f-a30b-12df76c7608a	c1	Natstle Coffeemate 400gm	Chocolate	Pcs.
790bb429-aaee-45db-b987-d0e6afcf410b	c1	Nature Choice Sumak Powder 1kg	Spices	Pcs.
b2317a00-e1af-4aef-aaa3-7cf8f37318ac	c1	Nature Choice Zatar Powder 1 Kg	Food	Pcs.
e3242e46-6f50-4235-b57b-0b2e1cf69f4b	c1	Nature Smith Basil Jar 125 Gm MRP.225	Food	Pcs.
096f13f7-f9e6-4a6c-b776-c1ba058eff7b	c1	Nature Smith Black Pepper Sachet	Food	Pcs.
e0118803-939b-4991-8a4a-e4b958122cb9	c1	Nature Smith Cajun Spice 500gm	Food	Pcs.
1ab0d9c3-6620-4441-83bc-8b096331d053	c1	Nature Smith Chilly Flakes Sachet	Food	Pcs.
95d7bfbd-229f-43af-9856-feaed17849b5	c1	Nature Smith Fajita Seasoning 500 Gm	Food	Pcs.
00078fb8-8af4-4fa8-8539-ebe15baee3d1	c1	Nature Smith Five Spice Powder 500 Gm	Food	Pcs.
ea9466c4-7d45-479c-baae-0992dc22d6cc	c1	Nature Smith Garlic Granules 400gm	Food	Pcs.
ff13b63d-0378-4aae-bf6a-0f5e479a559c	c1	Nature Smith Garlic Powder 400 Gm	Food	Pcs.
7fa0f95d-96c0-4299-a5f9-50a0b7c7894a	c1	Nature Smith Ginger Powder 400 Gm	Food	Pcs.
b7cb68e8-25bd-4823-b036-cb71dcceb47e	c1	Nature Smith Jamican Jerk Seasoning 500 Gm	Food	Pcs.
f1f9112b-b6e0-471b-a247-bb78d5490e39	c1	Nature Smith Onion Powder 400g	Food	Pcs.
8f0a981f-3298-4575-a426-a4c5d4095e43	c1	NATURE SMITH OREGANO SEASONING 1KG.	Spices	Pcs.
bc84b032-d6fe-438c-9e65-407d239c1e43	c1	Nature Smith Oregano Seasoning (Sachet)	Food	Pcs.
7d5921d6-655b-47b5-895c-e2453fc56768	c1	Nature Smith Paprika Powder 400gm	Food	Pcs.
4f816596-ec68-4df9-8261-b1a868e004a0	c1	Nature Smith Peri Peri Seasoning 500 Gm	Food	Pcs.
5666b1e8-8757-4084-9154-f49abed0009b	c1	Nature Smith Piri Piri Marinde Seasoning 1kg	Food	Pcs.
283b0ecb-b2ac-4b29-a2ae-f21105d71197	c1	NATURE SMITH ROSEMARRY 150gm	Food	Pcs.
09650c7c-bdd3-4325-b946-27b69daee0d8	c1	Nature Smith Salt (Sachet)	Food	Pcs.
221da848-796a-4d0b-bbeb-31b820d677f9	c1	Nature Smith Shawarma Spice 500gm	Spices	Pcs.
f34b5bb4-1c6c-4449-a498-66741324ba71	c1	Nature Smith Sumac Powder 500g	Food	Pcs.
ec0fd87e-fcb3-494d-bf28-690e52bfd8f4	c1	Nature Smith ZATAR POWDER 500G	Food	Pcs.
431a830b-3a38-4e0a-b33f-388e1dea84bb	c1	Necafe Decaff Coffee 100 Gm	Food	Pcs.
ceb6a29a-3cef-466c-a38e-bef74b772637	c1	Neha Fast Henna Black(360x25gm.)	NATURAL MEHANDI	CAR
288f4637-af38-41ea-8691-be228fa69017	c1	NEHA HENNA BLACK(250X20GM)	NATURAL MEHANDI	CAR
06c01a20-c827-4ea4-8326-2a396b4c7f6f	c1	NEHA HENNA BURGUNDY(250X20GM)	NATURAL MEHANDI	CAR
30e469b4-3cfb-4abc-b4fa-64903a9b6489	c1	Neha Herbal Heena (500x30gm.)Green	NATURAL MEHANDI	BAG
72aed5f7-69e4-4bee-b8c2-75def9899586	c1	Neha Herbal Heena Pink Burgundy(120x55gm.)	NATURAL MEHANDI	CAR
37b5ab2b-f8b7-45fe-8e7f-997f9329fb16	c1	Neha Herbal Heena Pink Burgundy(60x140gm.)	NATURAL MEHANDI	CAR
c7967199-c106-46f4-a904-de59720a02ae	c1	Neha Herbal Henna (500x30gm)	NATURAL MEHANDI	BAG
64d433e3-d865-4594-a7c5-d39e9c9f6a34	c1	Neha Herbal Henna(600x15gm)	NATURAL MEHANDI	CAR
9b6e1eaa-1489-4002-91ef-94b16bcc47ce	c1	NEHA HERBAL HENNA BLACK(500X18GM)	NATURAL MEHANDI	CAR
fdd7470b-f010-437b-ae45-bb2f1ff1ec71	c1	NEHA HERBAL HENNA PINK BURGUNDY(360X30GM)	NATURAL MEHANDI	BAG
3c90fa3b-7e5b-4efb-af0c-6aec7097c81d	c1	NEHA HERBAL MEHANDI(100%HERBAL)(120X55GM)	NATURAL MEHANDI	CAR
a8db1a3f-2e30-4c75-8be0-3fe347b2875c	c1	NEHA HERBAL MEHANDI(100%HERBAL)(24X500GM)	NATURAL MEHANDI	CAR
a9c62271-81cd-490f-b7a9-275786842d41	c1	Neha Herbal Mehandi(100% Herbal) 28gm.	NATURAL MEHANDI	BAG
747cad13-6ef2-4da9-916e-b077e4ed0684	c1	NEHA HERBAL MEHANDI (100% HERBAL)72X140GM)	NATURAL MEHANDI	CAR
a76d7838-a6f8-4161-acdb-b9bd3e5896c8	c1	NEHA KALI MEHANDI(600X6GM)	NATURAL MEHANDI	CAR
a59131f5-8c92-4c1d-b74d-c2f82ea855c9	c1	NEHA MEHANDI CONE (432X30GM)	NATURAL MEHANDI	CAR
c57c3ca8-7c8e-4056-a786-0f2c7a5ab980	c1	NEHA MEHANDI OIL144X4ML	NATURAL MEHANDI	CAR
7458fe2f-c1ad-4926-a641-1ff9af0fbe0f	c1	Neha Natural Colour Soft Black(240x15gm.)	NATURAL MEHANDI	CAR
a0c17f5a-fc5c-4986-86cc-556515b8c19e	c1	Neha Natural Hair Colour Burgundy(240x15gm.)	NATURAL MEHANDI	CAR
7d0a986b-cae3-4cc7-9c89-0cd7584593e9	c1	NEHA RACHANI MEHANDI 100% NATURAL(120X250G.)	NATURAL MEHANDI	Pcs.
55e26632-0998-4fc1-8c2f-99f714a47406	c1	Neha Rachani Mehandi 100% Natural(1500x5gm)	NATURAL MEHANDI	BAG
08697bc5-8119-4509-9b06-9d3f05b7a073	c1	Neha Rachani Mehandi 100% Natural(1x20kg.)	NATURAL MEHANDI	BAG
dc864857-5eb5-4f93-883d-9996a0dede98	c1	Neha Rachani Mehandi 100% Natural(20x1kg)	NATURAL MEHANDI	BAG
aba5f779-9ef5-4977-ab2f-b84eea4df725	c1	NEHA RACHANI MEHANDI 100%NATURAL(30X1KG)	NATURAL MEHANDI	Pcs.
12839a66-7b67-4141-8b20-339500835c78	c1	NEHA RACHANI MEHANDI(100%NATURAL)(40X500GM)	NATURAL MEHANDI	Pcs.
44e4472c-c0dc-4550-b818-25796c3e06cb	c1	Neha Rachani Mehandi 100% Natural(60x500gm)	NATURAL MEHANDI	BAG
ec3fd3e9-5017-4081-896f-65cd33626ef1	c1	Neha Rachani Mehandi 100% Natural(80x250gm)	NATURAL MEHANDI	CAR
01e6b55f-24be-4d5e-8b42-4a8a5b9de98a	c1	Neha Rachani Mehandi (500x25gm)	NATURAL MEHANDI	BAG
525a4ad7-a259-4ab1-9737-03bc83f60aef	c1	NEO BURGER CHIPS 350 Gms	Food	Pcs.
e1b7828f-6c4e-438e-aabe-8ab0e127d5b0	c1	NEO SLIDE RED PEPRIKA 180Gms	Food	Pcs.
b7508d02-145e-4eab-bcdc-3d43ac5625e8	c1	Nescafe	Food	Pcs.
f7b145f3-ae92-415c-b3d8-174a7d2bd1b1	c1	NESCAFE 3 IN 1 @18%	Drinks	Pcs.
f83a38ab-fc67-463a-8bcb-1d7f974c6f8d	c1	Nescafe 3 in 1 Original	Food	Pcs.
ca3c59f0-a125-4889-8760-bf4577c1f306	c1	NESCAFE ASSORTED 100 GM	Food	Pcs.
dc1e88bd-25ce-4acd-86f9-a3ada3f1b595	c1	Nescafe Cappucino Sticks	Food	Pcs.
d8ecf02f-4b7d-4293-907d-2963720d3f30	c1	Nescafe Classic 100 Gm (18%)	Food	Pcs.
d85b1629-93e3-4bd8-ac33-f07c10b72c65	c1	Nescafe Classic 200g 5%	Food	Pcs.
58c9a4c3-ec39-424e-ac8c-b8cc2d97132e	c1	Nescafe Classic 500gm	TEA	Pcs.
175efeca-63b3-4982-99a6-abb9870c1dc4	c1	Nescafe Classic Coffee 200gm	TEA	Pcs.
ec7bed63-8a58-4d44-aff0-d17ad44f7f54	c1	Nescafe Classic Stickpack 1.4 Gm	Food	Pcs.
fa845fa8-7c49-4a01-9fd3-402033a75a65	c1	Nescafe Coffee	TEA	Pcs.
3392d4b9-335a-4d88-80f0-1f12ef6199bf	c1	Nescafe Coffee 210 Gm	TEA	btl.
91d73cb0-e27d-48c1-9f1c-e47e44a95e1a	c1	Nescafe Coffee 230 Gm	Food	Pcs.
56de6bf5-27e7-4f3a-81b7-ed777cb5bd8c	c1	Nescafe Coffee Classic 200gm	TEA	Pcs.
c33e3eca-827f-4cf6-81f5-8fa62a5fc836	c1	Nescafe Coffee Drink RTD CAN (18%)	Drinks	Pcs.
7c4b6468-3215-41aa-b346-0b1c12d85168	c1	Nescafe Coffee Original 200gm	TEA	Pcs.
b361c6a6-20f8-48f8-898c-14962adbb194	c1	NESCAFE EXTRA FORT 200g 18%	Food	Pcs.
2476f533-1fd1-411a-8f65-48eb0e8ce75f	c1	NESCAFE EXTRA FORT 200g 5%	Food	Pcs.
99bee421-e909-4d2b-a600-8be4f6592cf7	c1	NESCAFE GOLD 100 GM	TEA	Pcs.
b87c90d9-a081-4844-9291-7eafbc861fd2	c1	Nescafe Gold 100 Gm Mrp.495	Food	Pcs.
230a2f8e-1c72-4cfe-85f0-d9eeaa6acd0f	c1	NESCAFE GOLD 190G	Food	Pcs.
a94804e4-c04d-41dd-8b5e-2255776e4a90	c1	NESCAFE GOLD 200 GM	TEA	Pcs.
59d0a728-b1e2-45be-ac83-d2b7a1b37688	c1	Nescafe Gold 47.5gm	Food	Pcs.
882da7ee-a9e5-4ae2-8d8a-8342b76f082b	c1	NESCAFE GOLD 50 GM	TEA	Pcs.
59023b56-4f90-4d3d-b0f5-7b8e54dee6e0	c1	Nescafe Gold 50 Gm (18%)	Food	Pcs.
6fe38ca9-8e59-4b41-8f8b-611bed069576	c1	Nescafe Gold 95 Gm	Food	Pcs.
fabf1477-2b09-49b9-8716-f3c8cc19090a	c1	Nescafe Gold Coffee 190 Gm (18%)	Food	Pcs.
f8dce868-75a3-4ad8-bd6f-f8250b2becc5	c1	NESCAFE Gold Espresso 100 GM	TEA	Pcs.
7817571f-daa4-40d1-9c3a-31d9fdb5994c	c1	Nescafe Intenso Coffee Beans 1 Kg	Food	Pcs.
0cc63024-d43e-493a-899a-8500f6b2e134	c1	Nescafe Original 160 Gm	Food	Pcs.
0d6bdb78-29d9-4630-b667-89643e7e03ca	c1	Nescafe Original Coffee 230 Gm (18%)	Food	Pcs.
24dd37fe-e49a-4af0-b6dd-a4f09e965c2b	c1	Nescafew Gold Decafe 100gm	TEA	Pcs.
917f64f0-0086-4a92-b841-fe6ce25eb8c3	c1	Nescaffe Classic 100 Gm	Food	Pcs.
67f46b38-9ec8-4278-9caa-8e2808b706fb	c1	Nescaffe Coffee 200 Gm	TEA	Pcs.
743a4389-c66e-4f25-ab0c-1b38cf857a81	c1	Nescaffe Gold 100gm	Food	Pcs.
11db6670-e794-4351-8276-3d00248104f5	c1	Nesquik 300gm	Food	Pcs.
8b9b7f3e-b22c-4d58-9b6b-ef6ef0e47ac2	c1	NESQUIK 500GM	Drinks	Pcs.
eb56f6c6-6097-431e-b748-cf01e3be8e0c	c1	Nestle Coffeeate	Food	Pcs.
14eb5dcd-0e32-4e93-aa16-1b653b8100fe	c1	Nestle Cream (12%)	Food	Pcs.
56a8a162-4411-4db0-9450-3fb89bdf942f	c1	Nestle Fox Fruit Tin 180 Gm	Food	Pcs.
ff54515e-72db-4645-b55e-d318654c0771	c1	Nestle Kit Kat Bytes (28*250gm)	Chocolate	Pcs.
12e0e73e-c91f-45f9-a467-96b6b400c3a9	c1	NESTLE LEMON TEA 1KG	Drinks	Pcs.
a4d34c77-a6a5-4b54-b150-083edd4c5193	c1	NESTLE MILK MAID 380G	Food	Pcs.
7d705eb5-8b4e-44ef-89e7-9db6a91e4167	c1	NGUAN SOON PALM SUGAR	Food	Pcs.
3d8196d1-261b-407c-9c0e-4e6e48980cd1	c1	Nguan Soon Pepper Corn 500 Gm (18%)	Food	Pcs.
860566b3-8892-4b73-a4d6-6545be3ac30c	c1	Nguan Soon Pepper Corn 500 Gm (IMP)	Food	Pcs.
193cbfd2-75eb-4907-bbb6-9bdff10c45ca	c1	Nguan Soon Schezwan Peppercorn 500g	Food	Pcs.
22d78584-e395-4fd7-bb7c-2a2b3e0873ef	c1	Nguan Soon Szechuan Pepper Corn 500gm	Food	Pcs.
6c6975f8-1572-4cbb-aeb2-86ca8fcf19f2	c1	NGUAN SZECHUAN PEPPER CORN	Food	Pcs.
148de593-8b2c-4f0a-9dbd-325eca251961	c1	NGUAN SZECHUAN PEPPER CORN 12%	Food	Pcs.
0713b655-4a13-4068-b21f-932c4dc05309	c1	Nilons Classic Mixed Pickle Pet 4.5 KG	Nilons	Pcs.
65eec766-af2a-4b65-9169-2550e7dc388d	c1	Nilons Ginger Garlic Paste Pet 900 Gm	Nilons	Pcs.
b2bb11a2-659a-4c3f-a51c-7094547a3e4d	c1	Nilons Ginger Paste Pet 900 Gm	Nilons	Pcs.
4d416d58-8d53-416b-8328-fad5dee225a5	c1	Nilons Green Chilly Sauce Pouch	Nilons	Pcs.
5970470a-b3d3-4699-bce7-b8021fb0e954	c1	Nilons Mix Fruit Jam Pouch	Nilons	Pcs.
1852b07f-39ba-4fef-a744-f34c670ce1a9	c1	Nilons Mix Pickle Pouch	Nilons	Pcs.
5b5fb885-5eab-4bcd-887b-5350e5cba78b	c1	Nilons Papaya Fruit Preserved Tutti Fruity	Nilons	Pcs.
b4d186ff-5cce-4c06-9d90-4f64125e5c5e	c1	Nilons Roasted Sevai Pouch 400 Gm	Nilons	Pcs.
0d457c5c-4ad8-4347-a979-31644851e2ae	c1	Nilons Snack Sauce Pouch	Nilons	Pcs.
1ca387ca-4d9d-4b69-8e90-f1adef2ec033	c1	Nitchi Chocolate Bar	Chocolate	Pcs.
75a49244-139a-447f-a8be-836e49fab2bb	c1	Nitchi Chocolate Bar 12t.30x10	Chocolate	Pcs.
953558ab-166f-4780-bf13-3bc17afc7be2	c1	NITCHI RICE CHOC.12GRMS.	Chocolate	Pcs.
53cc28f4-183f-45dc-96be-55efd9ec33cf	c1	Nitchi Tin 330g.	Chocolate	Pcs.
022336eb-9a33-4cf2-92e8-01234862129c	c1	No.1 Party Snacks 180gm	Food	Pcs.
1e052595-f536-40a3-aced-2809a2901270	c1	No.1 Salted Peanuts 110gm	Food	Pcs.
90a342ea-a460-4be6-a069-dbd5d3f1f047	c1	Nostima Ramen Noodles 300 Gm	Food	Pcs.
4e3a22c0-a6f2-4d1b-b2e7-bcd8e9c98413	c1	Nostima Udon Noodles	Food	Pcs.
9e312969-ea6e-4bfb-82a4-472408561f98	c1	Nostimo Chilli Oil Sasoning 225ml	Oil	Pcs.
38912265-c9ba-47c7-aeac-f6eac1c64ca5	c1	Nostimo Sake Vinegar 1.8 Ltr (18%)	Food	Pcs.
8887cfa2-33b9-4789-a28f-f23f154dc174	c1	NOSTIMO SUSHI NORI SHEET 140g 50sheet	Food	Pcs.
d90d7b76-336a-4b10-8f3c-db34c1a51380	c1	Nostimo Sushi Vinegar 1.8 Ltr (18%)	Food	Pcs.
647f0600-c4c4-4c1d-bd1f-9853fe7065b6	c1	Nostino Sushi Nori Sheet 10sheet 28g	Food	Pcs.
271da6c6-02f8-40d7-b6ad-16a38837a021	c1	N Soon Schezwan Pepper Corn 1 Kg	Food	Pcs.
45983899-4a1d-45d0-8834-864523b0c919	c1	NS Sachet Chilly Flex	Food	Pcs.
3eebc6ea-b0cf-4936-b485-993b20baa4e3	c1	NS Sachet Oregano Seasosning	Food	Pcs.
2cbc343d-cd1f-4ebf-b299-38aba755281f	c1	NS THYME JAR 150 GM	Food	Pcs.
30294690-4fd6-4ef1-b6c5-d42d274824ef	c1	NS Zatar Powder 400gm	Spices	Pcs.
08874f8e-9cc6-4423-a600-8ab868db3717	c1	Nurus Green Coffee Pouch2gm.Rs.225/-	Food	Pcs.
4138b969-7d20-4a0f-82a1-be6c8bb17c94	c1	Nutcandy Japanees Rice Cracker	Food	Pcs.
f06103d3-1495-41ba-8b5a-95abb945807c	c1	Nutella	Chocolate	Pcs.
2e473856-6be1-4613-953f-87a87b256e96	c1	NUTELLA 200GM	Food	Pcs.
381f14d5-1aeb-410d-b8a4-abb56364ec29	c1	NUTELLA 350	Food	Pcs.
a901bf4d-33ee-440e-acfa-bc12e9e84d66	c1	Nutella 350gm	Chocolate	Pcs.
85ef92db-f4c4-4021-b26c-9d8b27e014c2	c1	Nutella 350 Gm*15	Food	Pcs.
7a404af2-27da-4a8e-814f-c3fb599a6c46	c1	NUTELLA 350 Gm 18%	Food	Pcs.
46885d63-45c3-44a1-82a1-b6dc8061fb1c	c1	NUTELLA 750GM	Chocolate	Pcs.
21a1948c-e891-4f10-992e-a96ea47ddd62	c1	Nutella 750 GM MRP 799	Food	Pcs.
0d0e2b11-e5b8-4dcc-851e-029d73b5e050	c1	Nutella 750 Gm Spread	Chocolate	Pcs.
c6ab8c63-5dca-447a-9185-fa87afd27f02	c1	Nutella 825g	Food	Pcs.
70f8e16b-88d3-41d9-863b-96df9ef9185a	c1	NUTELLA 825 GM *12	Food	Pcs.
f59b4952-43a9-463b-bd9b-cb9caeb71721	c1	NUTELLA CHO	Food	Pcs.
1930bd49-18fb-462d-a263-7a41cf878e31	c1	Nutella Choco 350 Gm (18%)	Food	Pcs.
4ac64ae1-f057-4b68-932c-6368d1141833	c1	NUTELLA GO	Food	Pcs.
64db7432-d319-47d5-b27e-6a1d47511b0f	c1	NUTELLA SPREAD	Chocolate	Pcs.
ae45483b-9b9a-4ba8-8135-ae7782b17972	c1	Nutella Spread 750g	Chocolate	Pcs.
e06a1dd8-68e1-431f-84da-50e89606b370	c1	Nutella Spread 750 Gm	Food	Pcs.
8ffa457a-b178-4bc3-abdc-a124157883cc	c1	Nuterra Peanut Butter Creamy 1 Kg	Food	Pcs.
ed22d44a-ec8e-4db6-91e9-3993c15cee0f	c1	Nuterra Peanut Butter Crunchy 1 Kg	Food	Pcs.
42818a36-bd1c-4b67-ac5f-6c817a7ea131	c1	Nutriwrap 30g.	Packing Material	Pcs.
2ce1a139-5480-4ed8-8edf-6d4e9a52cf15	c1	Nutriwrap 50g.X300mm	Packing Material	Pcs.
803e524c-b8a5-4593-8b8b-5d3808a8204f	c1	Nutriwrap  72mtr 300mm	Packing Material	Pcs.
4d77a813-a501-4609-b5e7-053a13662067	c1	Nutriwrap 9mtr.300mm	Packing Material	Pcs.
c3e3074e-d7e1-44bd-95ff-db3bccf0a8b3	c1	NUTRO DATE ROOLS 125G.90/-	Biscuts	Pcs.
eec87542-8639-4722-8597-631ae157f825	c1	Nutro Dig.225gm.	Biscuts	Pcs.
4627bf5c-c94c-4101-bd93-8dc2eec24d3e	c1	Nutro DIG.400G.	Biscuts	Pcs.
c80c2d24-5bf6-4c51-b9cb-ce75aeb78053	c1	Nutro Teddy Bear Cookies 250g.	Biscuts	Pcs.
ca08f5a5-d41a-4dcc-9a75-48f1692001cc	c1	Nutro Wafer 150 Gm	Food	Pcs.
c7924063-1d04-4c70-a687-ccba39cb4567	c1	NUTRO WAFER CHOCOLATE 150GM	Food	Pcs.
50df75a7-ed25-465a-bd6d-f4c9d9c1cf7d	c1	Nutro Wafer Chocolate 75g.	Biscuts	Pcs.
ba72c235-813a-4ca1-8490-6a0f02a58be7	c1	Nutro Wafer Hazelnut	Food	Pcs.
1bec7f35-7a58-4b27-9149-b305fb4402d5	c1	NUTROWAFER HAZELNUT 150GM	Food	Pcs.
9d6097d9-6847-42a4-a03f-1006e69fbcff	c1	Nutro Wafer Hazelnut 75gm.	Biscuts	Pcs.
b3670ee4-6968-4ed2-8996-d76b493d19e6	c1	Nutro Wafer Orange	Food	Pcs.
969d1781-2454-4af4-9d26-1f747e2850d0	c1	NUTRO WAFER ORANGE 150GM	Food	Pcs.
c24c140c-426d-4ac0-b246-0972bc5f4d2f	c1	Nutro Waferrs Orange 75gm.	Biscuts	Pcs.
4a2d727f-79a1-4d74-b7a1-2d473f7d47ae	c1	Nutro Wafers 150 Gm	Food	Pcs.
c35efda9-4a93-4d44-adf7-c9b3213153e4	c1	NUTRO WAFER STRAWBERRY 150GM	Food	Pcs.
e458992d-8128-44d1-bb5b-f2e9a56d5633	c1	Nutro Wafer Strawberry 75gm.	Biscuts	Pcs.
88913879-84c8-4976-b4fd-fb30b8d4c3f3	c1	Nutro Wafers Vanilla 75gm.	Biscuts	Pcs.
a4bdd452-f813-42d1-b6c0-97a86632de77	c1	NUTRO WAFER VANILA 150GM	Food	Pcs.
046f4a65-8ee7-49b8-b848-e288e4aaad88	c1	Nutrus Berry Blast Sachets Rs.300/-	Food	Pcs.
06384aac-78b0-4467-85fd-7a607fc2df85	c1	Nutrus Classic Plain Gr.Tea Rs.220/-	Food	Pcs.
93659f81-95aa-475b-8935-b732db4bf8b2	c1	Nutrus Exotica 2gm Pyramid Rs.300/-	Food	Pcs.
25471596-b059-4e7b-9a05-b7dba3a1275a	c1	NUTRUS GREEN COFFEE (P) 270/-	Food	Pcs.
348da3d8-bd49-448f-bb44-ce0385fd1480	c1	NUTRUS Green Tea(Lemon) 20s Rs.165/-	Food	Pcs.
52a6bdc1-c212-469a-8bdc-c3e0a160dbb7	c1	Nutrus Jolly Jasmine Sachests Rs.300/-	Food	Pcs.
068926f3-4feb-42c8-95af-2eba2c79f665	c1	Nutrus Mustique Rose Sachets Rs.300/-	Food	Pcs.
fcbb5ee5-5778-40c5-b76b-6da4a4a06d32	c1	Nutrus Slim Tea(Lemon) Rs.185/-	Food	Pcs.
d944a00f-d8f9-42b2-831f-75464cb1f33f	c1	Nutrus Tulsi Tea 2gm.Sachet Rs.185/-	Food	Pcs.
df59a540-3412-43f4-a3f0-2a11e08b5dda	c1	Nuttela Cho	Chocolate	Pcs.
35f6de27-c434-4531-a36c-c358e88e264e	c1	Nut Wakerbutter Toffee	Namkeen	Pcs.
5d09ef19-9b2b-4c26-b94e-b593e2c57210	c1	Nut Walker Cocktail Snack 250g.	Namkeen	Pcs.
b60db2c9-add2-45c2-a9f9-69fdb1921edd	c1	Nut Walker Coktail Snack 120g.	Namkeen	Pcs.
307ecca0-4c01-49d6-a683-0580bcf67b83	c1	Nut Walker Pumkin Seeds	Namkeen	Pcs.
07a2ac3b-fbb5-498d-897c-340fa9b798b6	c1	Nut Walker Rosted Cashewnut	Namkeen	Pcs.
0708a983-e69b-415d-8546-4288bbf2f6cc	c1	Nut Walker Rosted Sltd.Honey Roast	Namkeen	Pcs.
0b2ae830-c75d-40bc-a3e2-636355193fc2	c1	Nut Walker Rosted &amp; Sltd.Pstach 130g.	Namkeen	Pcs.
76a8d5ea-0a42-495d-8892-422c7cabb3ae	c1	Nut Walker Sunflower Seeds	Namkeen	Pcs.
e28dffe0-804f-4782-96c5-57162bd73498	c1	Nut Walker Warbi Cotd Green Peas	Namkeen	Pcs.
9d01cf4e-3abf-44fe-9f53-8aa2b7b46eae	c1	NW Cheese Pepper Coated Peanuts 140gm.	Food	Pcs.
6afffc8d-332c-45c2-b52b-9057621e8bd7	c1	NW  Cheeses Pepper Coated Peanuts 24g	Food	Pcs.
f099bf7a-2e35-4343-911d-413ce6280bc2	c1	NW Chilli Sause Coted Peanuts 140g	Food	Pcs.
eed879db-723e-4966-908e-bab6acb645f5	c1	NW Chilli Souce Coated Peanuts 24g	Food	Pcs.
207e32cc-7ad3-44f7-b653-7d46b66e1bba	c1	NW Honey Vanilla Coteted Peanuts 140g	Food	Pcs.
4e342efd-14d1-42b3-81ad-aac88ddce5cf	c1	NW  Lemon Grass Wasabi Coated Peanuts 140g	Food	Pcs.
512f5270-d7b1-4ffa-b783-e204a8369ca6	c1	NW Lemon Grass Wasabi Coated Peanuts 24g	Food	Pcs.
9d244e49-bdb0-48d1-8912-f09f1c62a84e	c1	NW  Pizza Coated Peanuts 140g	Food	Pcs.
7862a4c3-43f7-4fda-858b-351ba0efe8f5	c1	NW Pizza Coated Peanuts 24g	Food	Pcs.
9f525ad5-7a6d-451d-b594-3238f7718f27	c1	NW Smokey Barbeque Coated Peanuts 140g	Food	Pcs.
19b1c681-d378-420f-bbb2-8a8385e94b6c	c1	NW  Spicy Paprika Coated Peanuts 140g	Food	Pcs.
5d5c9fe0-26d5-4e42-b581-9936c82d31b1	c1	NW Spicy Paprika Coated Peanuts 24g	Food	Pcs.
3e517412-42be-4747-a1dc-4f77238830ff	c1	NW  Sweet Seasame Coated Peanuts 140g	Food	Pcs.
d2c765ba-f138-4b81-9934-9834845d4c6d	c1	O&apos;cean Natural Energy Drink	Drinks	Pcs.
6089b090-8744-4ad9-85fb-467789e9e226	c1	O&apos;cean One8 Energy Dring 500ml	Drinks	Pcs.
0a1ee985-b143-4c37-8aef-45edbc649341	c1	OATS CHIPS JAR	GURU FOOD	jar
45cb6338-5a5a-4d90-ab82-d2cb4d28176f	c1	Oatside Oat Drink 1ltr	Food	Pcs.
137cf894-5a73-4469-84cc-a361357a7883	c1	OATS LACHHA JAR	Food	jar
d98b86d8-de0b-47a2-94bf-356e002d89b9	c1	OATS STICKS JAR	GURU FOOD	Pcs.
2381f768-9ef1-4a59-af29-1c10da05e28f	c1	Ocean Active Water Orange &amp; Lime 500ml.Mrp.Rs.50/-	Drinks	Pcs.
accd751f-1b77-4db5-ada2-2d7d07da715a	c1	Ocean Active Water Peach 500ml. Mrp.Rs.50/-	Drinks	Pcs.
f0156ec4-f699-4b89-b080-90f578efe17d	c1	Ocean Fruit Crisy Apple 500ml Mrp.50	Drinks	Pcs.
38b46f5d-f71e-41ab-a478-9d195d0d39f9	c1	Ocean Fruit Water Mango &amp; Passion 500ml Mrp.50	Drinks	Pcs.
ec91fac0-63b6-46a4-a8cf-e8f0d52fd613	c1	Ocean Fruit Water Melon 500ml.	Drinks	Pcs.
5541d192-ac6f-4ee1-959f-1035c5d3b499	c1	Ocean Fruit Water Peach &amp; Passion 500ml Mrp.50	Drinks	Pcs.
9ca45685-0985-4147-9271-a2bdd9fa6ba9	c1	Ocean Fruit Water Pink Guava 500ml Mrp.50	Drinks	Pcs.
9079a148-32bf-4d85-8d71-ebd39a787982	c1	Ocean Fruit Wave Apple Blueberry	Drinks	Pcs.
44af5723-3a6a-41e8-92a7-ce21d48e744f	c1	Ocean Fruit Wave Orange Lime	Drinks	Pcs.
b4e055d5-0113-4317-88a2-05ca04af3b94	c1	Ocean Fruit Wave Pine Straberry Rs.50/-	Drinks	Pcs.
0b7f21e3-d59c-4e4f-bf19-a17b7e004ca9	c1	Ocean Fruit Wave Straberry Respberry	Drinks	Pcs.
104308e0-45e6-4afe-a571-87cb0a74bafe	c1	Ocean One8 Active Strawberry	Drinks	Pcs.
4597f0e7-3b4c-4906-ad11-d9230edc92ed	c1	Ocean One8 Active Water Orange	Drinks	Pcs.
d6de3faa-0b1e-4b78-bb4e-348c421ec118	c1	Ocean One8 Active Water Peach	Drinks	Pcs.
9e75ec64-2a81-450c-a314-8a41410cffba	c1	Ocean Spray Cranberry 1 Ltr	Drinks	Pcs.
4ae2b979-9ddc-42e3-8e15-cb263937fc2a	c1	Ocean Spray Cranberry Apple Mrp.Rs.140/-	Drinks	Pcs.
c0ad2086-82b0-482b-ae59-e6b50acf1e8a	c1	Ocean Spray Cranberry Cane Mrp.Rs.80/-	Drinks	Pcs.
aad465f2-62b1-48c3-a27d-01712305cf06	c1	OIL	Food	Pcs.
061b2207-3aa4-4ba7-b06b-aecd05135651	c1	OIL SESAME	Oil	Pcs.
35b6a669-49af-46f0-a035-f4e37d34f699	c1	OLAY B/W 295ML.PLUS B/BUTTER	Cosmatics	Pcs.
e519941e-828d-4a11-86f1-a87cf8216a35	c1	OLAY B/W 400ML.U/MOISTURE	Cosmatics	Pcs.
32c9d4b7-550a-4518-8527-91e7c792a4ab	c1	Olay B/wash 295ml.Pure Crm.	Cosmatics	Pcs.
d564c396-e53e-4d92-a384-731f7d14967f	c1	Olay B/wash 354ml.Daily	Cosmatics	Pcs.
d76bb5bf-a1a9-4295-b2d7-dba38d6a4b89	c1	Olay B/wash354ml.Mois.	Cosmatics	Pcs.
7ffd2d99-db1c-420b-9971-63190fa817c7	c1	Olay B/wash 400ml.Quench	Cosmatics	Pcs.
adca71a2-a671-4fc0-b70e-2682f126cea6	c1	Olay B/wash.Age.Def.400ml.	Cosmatics	Pcs.
bc1df829-869a-45b1-ac10-fed059debbf4	c1	OLAY B/W PLUS CRM.RIBBIONS	Cosmatics	Pcs.
baf89849-18df-4a0b-a130-db4ef7f47e80	c1	Olay Soap 2x1 120g.Um Vanila	Cosmatics	Pcs.
19dde717-fef6-47f0-a36a-75a63ae12bf1	c1	Oleev Pomace Oil 5ltr.Tin	Oil	Pcs.
9cdfe053-d016-433c-9322-26166e8a959e	c1	Olicoop Black Pitted Olive 450gm	Food	Pcs.
17e22aa0-ae73-4e8a-98b3-e0e9a512d6d0	c1	Olicoop Black Sliced Olive 450gm.	Food	Pcs.
a98f0afa-431c-4ec4-ace1-04ed659964c2	c1	Olicoop Green Pitted Olive 450gm.	Food	Pcs.
df7be3d0-358f-40d0-879a-099e61bea613	c1	Olicoop Green Sliced Olive 450gm.	Food	Pcs.
2208e48f-bae6-42e4-a4e2-e5796a57b9aa	c1	Olive Black Pitted	Food	Pcs.
c188f325-8514-4a43-ab98-5b2d8c13bc35	c1	OLIVE OIL	Universal  STOCK	Pcs.
5713f2fb-b905-4831-b5a5-b424a9017a67	c1	OLIVE OIL  1LTR.	Oil	Pcs.
ca595695-452b-4a36-beed-41baf78afaa2	c1	Olive Oil 1 Ltr Pomace (GIOLLY)	Food	Pcs.
7bcf98dc-6c57-405a-b875-9e331beb254a	c1	Olive Oil 250ml.	Oil	Pcs.
942d8043-be60-4262-8629-3f2ce5ef2757	c1	Olive Oil 5 Ltr Caneen	Oil	Pcs.
03169963-d6fb-4a8d-8e10-53d20f19c22b	c1	OLIVE OIL 5 LTR (GIOLLY) (5%)	Oil	Pcs.
fdaa7299-32ce-482a-b28f-fc08bc9bc958	c1	Olive Oil Pomace 5 Ltr (Vittorio)	Oil	Pcs.
d1b85d49-c0e9-464f-ad04-329ebc06da6d	c1	Olive Oil Pure 500ml.Oliveta Rs.465/-	Oil	Pcs.
173cd4c0-f631-4235-b928-e35924f051b3	c1	Olive Oll Pomace 1 Ltr	Oil	Pcs.
9f1cbe1e-b35f-45f3-8144-cc9abda11d6d	c1	Olive Pomace Oil 5ltr.Tin	Oil	Pcs.
239a311a-4ae4-46cb-9604-da89bd22ddf8	c1	OLIVES 3 Kg (Black Sliced)	Food	Pcs.
4606abf0-7ce4-4e8b-ae4a-e38480e8fae1	c1	OLIVES 450 Gm (Black Pitted)	Food	Pcs.
15c12172-d15f-4da8-a812-72432f5c5c52	c1	Olives 450 GM (Green Pitted)	Food	Pcs.
4a0d37be-b159-456d-9309-7bd52b74c942	c1	OLIVES BLACK PITTED 450	Food	Pcs.
5ae94227-40ac-4a8c-9a66-4f95df0171c3	c1	Olives Black Sliced 450 Gm	Food	Pcs.
e5b7c342-14d7-4b35-bfca-374ed2990e0c	c1	OLIVES GREEN PITTED (12*450G)	Food	Pcs.
3e2a1037-be36-4283-93e8-1114f3b470f4	c1	Olives Sliced Green 230g.Disano	Food	Pcs.
dab4f359-88a7-4119-a14a-cf33856d32f2	c1	Olives Stuffed Green Disano	Food	Pcs.
c5aa2d86-6a85-40e8-adee-5cdf0fe0e3a0	c1	Oliv Oil Pure 500ml.1+1 Offer Rs.425/-	Oil	Pcs.
c169226b-dea5-4f45-8087-e4d221e2d32b	c1	Oliv Oil Pure Oliveta 1ltr 1+1 Offer Rs.650/-	Oil	Pcs.
4fe0c4ed-7acb-407c-83f0-7e839b26c0e9	c1	One8 Deo Spray Active Mrp.249	One 8 Deo	Pcs.
71b93b74-2ee5-4e98-a9c0-8e319e9f45f3	c1	One 8 Deo Spray Aqua Mrp.249	One 8 Deo	Pcs.
9bcc58cf-ad11-41bb-9ab0-1832ffff0c09	c1	One 8 Deo Spray Fresh Mrp.249	One 8 Deo	Pcs.
872d4b2e-a8ee-4a13-b8a2-714087d90872	c1	One 8 Deo Spray Intense Mrp.249	One 8 Deo	Pcs.
36bd9380-6859-4cd7-8f3c-58f5f68aa986	c1	One 8 Deo Spray Pure Mrp.249	One 8 Deo	Pcs.
1685b85b-0af7-4a8c-9300-33b0df5a8e56	c1	One 8 Deo Spray Willow Mrp.249	One 8 Deo	Pcs.
00ae1dc7-0e19-46f6-870a-74552d10e092	c1	Ongs Black Beans	Food	Pcs.
43435f45-93e2-4f05-af71-5322df06f2b1	c1	Ongs Teryaki Sauce 210 Ml	Food	Pcs.
97aaa972-1c94-44bd-bbce-49b0466d1c27	c1	Onion Silver Skin in Vinegar (A-370)	Food	Pcs.
3a8a3b56-b9fe-4f98-9b59-963c377ecdb1	c1	Only All PRPS Seasoning 40gm.Rs.129/-	Food	Pcs.
3d5ffbe0-1b3d-43f1-af0e-a73a04659116	c1	Only Basil 30gm.Rs.99/-	Food	Pcs.
12a3849e-f712-4cac-b6a4-b0108945174e	c1	Only Black Salt GR.100gm.Rs.79/-	Food	Pcs.
bb547e3b-7ec8-4724-998a-b9a1cc25fa2d	c1	Only BLK-PPR&amp;Pink Salt 80gm.Rs.129/-	Food	Pcs.
baa64aa1-a212-498d-ac6c-8edc2f9560b5	c1	Only Chilly Flakes 50gms,99/-	Food	Pcs.
1db4482f-7676-4cfd-b4de-25be2334d078	c1	Only Fruit Seasoning 60gm.Rs.119/-	Food	Pcs.
0b20c28b-ae63-483c-9c55-97dca3282c5e	c1	Only Itelian Seasoning 35gm.Rs.119/-	Food	Pcs.
bfb24ea8-4dc8-4d6e-95ee-5849fe0e2654	c1	Only Meat Supreme 45gm.Rs.139/-	Food	Pcs.
bc9559cb-fd96-464c-b9a8-3d28c6c5a947	c1	Only Mix Herbs 25gm.Rs.99/-	Food	Pcs.
0967c2fc-7d20-498b-af5f-4eb83409123e	c1	Only Origano 25gm.Rs.99/-	Food	Pcs.
f20dad98-5b7e-4b09-aedb-a90fd017f219	c1	Only Parsley 15gm.Rs.Rs.99/-	Food	Pcs.
3407d764-635b-4df6-8237-6ba0aa3047da	c1	Only Pepper Grinder 50gm. Rs.159/-	Food	Pcs.
ea7cb188-10ec-439d-a259-dfd38801aae4	c1	Only Pink Salt GR.100gm.Rs.79/-	Food	Pcs.
6f13535e-83d8-4fc9-8123-545515a39777	c1	Only Rosemerry 55gm.Rs.99/-	Food	Pcs.
62d95176-608f-4e0a-9b2e-6bf6e2071a30	c1	Only Rotd-Grlc &amp; Pink Salt Rs.109/-	Food	Pcs.
522b9f39-ce27-45ff-aedc-fc361b00d325	c1	Only Salad Seasoning 45gm.Rs.109/-	Food	Pcs.
1b91f2cf-aae6-4de7-b8f0-f630e5ab5a84	c1	ONLY SOUP SEASONING	Namkeen	Pcs.
da3aa69b-dd89-4345-9527-c2b50844c591	c1	Only Thyme 35gm.Rs.99/-	Food	Pcs.
d0d38b88-aa2f-4cd9-804c-9c5c05f6cd3f	c1	Op Oyester Fish Sauce 1ltr	Food	Pcs.
a0be344a-159a-49a4-a7d2-48fcaf75db86	c1	OPTIMA GREEN PESTO SAUCE	Food	Pcs.
5c7fbe48-e0ab-4fed-8b12-1f2e25e92199	c1	OPTIMA PAGODA FERMENTED RICE VINEGAR 500 Ml	Food	Pcs.
eee1cb78-3822-46c3-9f76-2038ff7d43d5	c1	OPTIMA SUSHI VINEGAR 1.8 LTR	Food	Pcs.
8521c240-a919-45c5-9aae-ae8a7fcc857c	c1	Orange Dates 200GM	Food	Pcs.
36d2a2dd-b8c8-4c72-9e9d-4ae826562f11	c1	Orange Mango Flav 300ml. Mrp.Rs.55/-	Drinks	btl.
36a5c253-fb33-4ada-a668-05bf824b6563	c1	Oranic Whole Wheat Atta 5kg. Rs.300/-	Organics	Pcs.
e01444ff-afbb-4fe7-b09d-57710cbc66e8	c1	Oregano	Food	Pcs.
65f053c5-602d-4cd5-a371-713df5c29804	c1	Oregano 1kg.	Food	Pcs.
c27ba011-6066-466c-83d8-8a63ddd29168	c1	Oregano Sachets	Food	Pcs.
5fa7fac8-7382-4862-96f4-5c6ca648a972	c1	Oregano Seasoning Nature Smith 400gm	Food	Pcs.
1c5f963c-a5f5-492b-9573-75e089314ab5	c1	Oreo Assorted (Imp)	Food	Pcs.
169878dc-731a-49ff-8f50-35e9558d204a	c1	Oreo Biscuits (Imp)	Food	Pcs.
77e58a72-76c9-4d65-9b2d-abc5a9e6ec65	c1	Oreo Cake	Food	Pcs.
4c16f254-3ab1-4548-97d9-f990402ade5c	c1	Oreogo Chocolate Cookies Stick	Chocolate	Pcs.
50c2befe-7ad0-417c-a1ac-6dbda2217d6e	c1	Oreo Mini Biscuit Mix Flavoured	Food	Pcs.
2db1ea4d-046f-4741-986f-23d7cf2b4624	c1	Oreo Roll (18%)	Food	Pcs.
70558579-5636-4c3f-8163-2414afac0694	c1	Oreo Soft Cake 18%	Biscuts	Pcs.
a8ae1402-3130-49fe-a9ad-1c001ab3e115	c1	Oreo Soft Cake 192gm	Food	Pcs.
8a572357-2e0b-4bd5-a3d5-cba0acfe5a55	c1	Oreo Waffer (18%)	Food	Pcs.
cf59cd0b-0989-442d-8f58-c4976042d473	c1	Organic  7 Grain Atta 1kg.	Organics	Pcs.
421ae23d-fed5-468b-84a4-142b1b7e6530	c1	ORGANIC 7 GRAIN METHI ATTA 1 KG	Organics	Pcs.
1a234f9b-da81-4a22-88ab-d0dd4aec263b	c1	Organic Ajwine 100g	Organics	Pcs.
5521d4fa-6c5b-4838-afda-cbe5fa644825	c1	ORGANIC ALMONDS 100G.	Organics	Pcs.
2473e560-f408-4233-994b-1efea1ae06cc	c1	ORGANIC APPLE BLAST 250ML.RS.49/-	Organics	Pcs.
f15d698b-0096-48fd-a14f-3c5d30553645	c1	Organic Apple Juice 1 Ltr.	Organics	Pcs.
1cc6381d-1d58-45a4-be8e-bfa653f9228a	c1	ORGANIC Assam Tea 100 Gm	Organics	Pcs.
1f620204-1b22-4caf-929d-b7c006788402	c1	Organic Assam Tea 25tb&apos;	Organics	Pcs.
818c5df7-b904-440f-9849-43451e1aff7b	c1	ORGANIC AYURVEAM ANTIFATIGUE (25BAG)	Organics	Pcs.
f0e92e28-cb8b-44c2-9d45-35acd84fd2ac	c1	ORGANIC AYURVEDAM COUGH RELIEF (25 BAG)	Organics	Pcs.
26025aec-bce2-4c49-a8b1-0095ff6059bf	c1	ORGANIC AYURVEDAM DETOXIFYING (25BAG)	Organics	Pcs.
e20711b1-d935-4eee-8461-10e1e6ac9d55	c1	ORGANIC AYURVEDAM EASYDIGEST(25BAG)	Organics	Pcs.
62876a0c-f59a-434a-9901-3eaf468f7c4c	c1	ORGANIC AYURVEDAM REVITALISING (25BAG)	Organics	Pcs.
781b3537-33e2-4b33-a35e-b7b103c3f34d	c1	ORGANIC AYURVEDAM WEIGH LESS (25BAG)	Organics	Pcs.
f98a90d5-2632-4a38-bb5e-8330846cc6b9	c1	Organic Bajra Flour 250 Gm	Organics	Pcs.
3b5515b5-f4c3-44cb-9b20-76b4aec0ca6c	c1	Organic Bajra Flour 500g.	Organics	Pcs.
47c1a7eb-93a0-4067-b8fd-6ed04364cbf0	c1	Organic Barnyard Millet 500 Gm	Organics	Pcs.
54e7b793-a0be-4563-9203-87227fa030ab	c1	Organic Basmati Brown Rice 1kg.	Organics	Pcs.
3ad93407-a5aa-4a4c-a792-2ebf25efd109	c1	Organic Basmati Rice 1kg.	Organics	Pcs.
e462bc13-b4ec-4845-807d-c9ce4ea52fb2	c1	ORGANIC BERRY BLAST 250ML.RS.49/-	Organics	Pcs.
383d2ad4-54fe-4d5b-8023-375eb8b388e7	c1	Organic Besan 500g.	Organics	Pcs.
deab653c-cce0-49fc-b399-8595f3ffb939	c1	Organic Biryani 200g	Organics	Pcs.
0a3513ab-3504-4a18-96b8-38787651c3dd	c1	Organic Black Pepper 50 Gm	Organics	Pcs.
15ce3613-b0ac-4e41-a372-dd46984d4064	c1	Organic Black Pepper Powder 100gm	Organics	Pcs.
88dd2223-61a1-478b-846a-4c316cf9e77e	c1	Organic Broken Rice 1 Kg	Organics	Pcs.
7ed8cfaa-cbeb-4a59-b444-f5d85f8652e3	c1	Organic Brown Chana 1 Kg	Organics	Pcs.
1fedc25e-8893-46a2-8045-483494f8143b	c1	Organic Brown Chana 500g.	Organics	Pcs.
cd679b93-0edd-4eaf-abcc-fa72a2f73bd9	c1	Organic Bura Sugar 500 Gm	Organics	Pcs.
113e8b50-0e14-4815-b585-adedb21b1aca	c1	Organic Chana Dal 1 Kg	Organics	Pcs.
37cbb315-e082-4747-a4a5-9664fbf60ebd	c1	Organic Chana Dal 500g.	Organics	Pcs.
86c7159f-d996-4fb7-a32c-5ce2dd4be903	c1	Organic Chat Masala 50gm.	Organics	Pcs.
3d7edaaa-c535-4ba2-9bee-ee1f86108eca	c1	Organic Chatpat Mazaa Bites 25gms	Organics	Pcs.
b8bc9b3e-c432-49c5-820b-7d116f836f3f	c1	Organic Chia Seed 350 Gm	Organics	Pcs.
e1596ee9-241b-4b9b-9615-32f400cfcf31	c1	Organic Chilly Powder 100g	Organics	Pcs.
023cee70-c5b3-44d2-b779-e523a6b2ab63	c1	Organic Chitkabra Rajma 500g	Organics	Pcs.
259858a0-599c-4d0b-b1cd-adc38ba11a1b	c1	Organic Cinneman Powder 100g	Organics	Pcs.
4dac198e-4b87-46b9-81fd-fa68607acb7e	c1	Organic Coriander Powder 100g	Organics	Pcs.
9b67b342-047e-4b66-bde2-c7152c0534c9	c1	Organic Corn Dhaliya 500g.	Organics	Pcs.
40b77fcb-21b5-4d83-a3a9-4af807f9ad17	c1	Organic Corn Flour 500g	Organics	Pcs.
b2e365b6-0b15-4328-94be-91360487b888	c1	ORGANIC CREAMY PEANUT BUTTER 150GM	Organics	Pcs.
15dd24c4-f9d7-4558-96d0-66576ecf428d	c1	Organic Cumin Powder 100g	Organics	Pcs.
4a96f14f-48a7-4a56-93c2-aa0a407066be	c1	Organic Demrara Sugar 500g	Organics	Pcs.
f5d3ca52-1be9-4903-a7a0-7d543ffad36b	c1	Organic Desi Mazaa Bites 25gms	Organics	Pcs.
a6679ff5-7684-4190-836c-947acaaf3d69	c1	Organic Dry Ginger Powder 50g	Organics	Pcs.
a3b9ee2c-3d7b-4151-be81-ae54a99b0d4c	c1	Organic Fengureek Powder 100g	Organics	Pcs.
2e351e71-6ac8-4b95-bfd0-7ef39fc07963	c1	Organic Fennel 100gm.	Organics	Pcs.
60e56106-fca2-4fc5-b4f9-d9485beed289	c1	Organic Flax Seeds 200g.	Organics	Pcs.
daf40c3e-92dd-4b43-9c58-9ffc429d84c9	c1	Organic Foxtail Millet 500gm.	Organics	Pcs.
bb036eb7-9760-44d9-a5d7-3f550f11e956	c1	Organic Fussili Pasta 400 Gm	Organics	Pcs.
f43f4c9a-ea92-45eb-a379-f5dffd2e56cf	c1	Organic Garam Masala 50gm	Organics	Pcs.
d6e61c5e-11bd-40fa-9ec7-de5cbec37ac4	c1	Organic Garlic Paste 140g	Organics	Pcs.
a31eea7c-f6e1-480a-aea8-0149a237ef58	c1	Organic Ginger Garlic Paste 140g	Organics	Pcs.
599d57a7-d129-4a69-8426-8aa76e9b48d1	c1	Organic Ginger Paste 140g.	Organics	Pcs.
9ba24412-a02d-46ba-919b-5d2a986aedcc	c1	Organic Gojji Avalakki 200g.	Organics	Pcs.
03c157f7-46dc-4c56-afe0-74b0bde4e009	c1	Organic Green Moong Dal Split 500g	Organics	Pcs.
477e5f4d-b1e8-4c41-97f0-001e576df210	c1	Organic Green Moong Dal Whole 500g.	Organics	Pcs.
07d10e92-9cbc-407b-98df-811688005b14	c1	Organic Green Moong Whole 1 Kg	Organics	Pcs.
a807d775-1d2f-484e-9559-54655771a1c5	c1	Organic Green Tea 100g	Organics	Pcs.
d123323c-94ea-4561-a939-4055a5f061d8	c1	Organic Green Tea 25tb	Organics	Pcs.
dec52121-a07a-468c-90e0-2f73e0bca9ba	c1	Organic Groundnut Cold Pressed Oil 1 Ltr.	Organics	Pcs.
666b06f3-b564-4b4c-a3b5-5aaf87ee98ef	c1	ORGANIC GUVAVA JUICE 1LTR. 1LTR. RS.109/-	Organics	Pcs.
39a17185-52c4-4b26-9909-6004a2c8b5bd	c1	Organic Himalayan Salt 1kg	Organics	Pcs.
e1c9d12d-c3c3-41b2-be4f-b2e750484169	c1	Organic Himalayan Salt Powder 1 Kg	Organics	Pcs.
55b42928-9f6f-4249-982e-f7ee8d00b710	c1	Organic Himalya Salt 1kg.	Organics	Pcs.
16a89b4e-d4bc-4d92-9df0-7587eb4445e3	c1	Organic Honey 250g	Organics	Pcs.
6eb3abd4-b91e-4df8-a165-a6024cdd1320	c1	Organic Honey 500 Gm	Organics	Pcs.
a136e09f-0934-4536-bfa6-b3400e2d836c	c1	Organic Idly Rava 500g	Organics	Pcs.
877f49de-e533-46d9-9ed9-3ca25eff677a	c1	Organic Idly Rice 1 Kg	Organics	Pcs.
9c58906f-2e6d-4d78-b48d-82647a542597	c1	Organic  Jagary Mrp.Rs.60/-	Organics	Pcs.
c8fce3c9-840f-464f-9bc5-a0bb36649a49	c1	Organic Jaggary Whole 500gm. 0%	Organics	Pcs.
01853321-d7ce-4298-bdcd-0415b8df4ee3	c1	Organic Jaggery Powder 250 Gm	Food	Pcs.
e6419e88-b53f-4c4e-ad4c-f5bd1f2fac9b	c1	Organic Jaggery Powder 500g 0%	Organics	Pcs.
f10f01cc-716a-47fe-8fdc-5ce3cac7970a	c1	Organic Jowar Flour 500g.	Organics	Pcs.
f42aadd6-c964-4340-9b03-78952c5c2287	c1	Organic Kabuli Chana 1kg	Organics	Pcs.
f84f686c-5bc1-449c-be54-bc212ece7840	c1	Organic Kabuli Chana 500g	Organics	Pcs.
73e03309-cd2f-4ab6-b366-37323dbe0281	c1	Organic Kanda Poha-Riceflakes Onoin Mix 200g.	Organics	Pcs.
5d4ad8bd-bdcb-4fc9-8562-1cf70720b08e	c1	Organic Khichadi 200g	Organics	Pcs.
05b4f3c6-5163-4f67-a25c-a4438775a5eb	c1	ORGANIC KISMIS 100G.	Organics	Pcs.
be81be35-a5d8-4e46-8e88-6d225f36e304	c1	Organic Kodo Millet 500gn.	Organics	Pcs.
aa4a3f39-7789-4ae3-9923-028b46e3e414	c1	Organic Little Millet 500gm.	Organics	Pcs.
55850842-91f7-4f7f-8b8a-93f2476f3113	c1	ORGANIC LOW GI RICE 1 KG	Food	Pcs.
54326ad0-ac04-43f9-8d0e-a5eedd646901	c1	Organic Macroni Pasta 400 Gm	Organics	Pcs.
b3326ee3-0963-4421-b585-711fe8380cac	c1	ORGANIC MANGO JUICE 1LTR.RS.109/-	Organics	Pcs.
65569681-dc91-45d7-96f9-2c911036a338	c1	Organic Mango Juice 200ml.	Organics	Pcs.
8771c21f-e712-4e1d-a2b1-ce9e2346eff2	c1	Organic Masoor Dal 1 Kg.	Organics	Pcs.
eb5137cf-e5e1-4b97-8523-63acc49045a4	c1	Organic Masoor Dal 500g	Organics	Pcs.
63f53de1-123b-4669-add5-240cb62fad52	c1	Organic Masoor Malka Dal Split 500g	Organics	Pcs.
a7dbb8e6-90d2-45da-b38a-a08e5ad651e5	c1	Organic Masoor Whole Dal 500g	Organics	Pcs.
c0d7632b-dd75-4339-a10b-54e60440224b	c1	ORGANIC MIXED FRUIT JUICE 1LTR. RS.149/-	Organics	Pcs.
7c558da1-0fc4-48f6-bab0-46cc9c95c4b7	c1	Organic Mixed Millet 500gm,	Organics	Pcs.
9d3f8c59-dce5-45ce-8310-e623bc8a91f0	c1	Organic Moong Dal 1 Kg	Organics	Pcs.
e57a23e9-2311-43ee-904a-78c5476d7b20	c1	Organic Moong Dal 500g.	Organics	Pcs.
3aae95bc-2912-402b-a6a9-4b83cfb95994	c1	Organic Multigrain Atta 500g.	Organics	Pcs.
9f98ddb4-3447-4aa5-af74-3f633b0e53ee	c1	Organic Multigrain Sattu 500g	Organics	Pcs.
2173f97b-7506-4332-b6ce-a833182a96d3	c1	Organic Mustared Cold Pressed Oil 1ltr.	Organics	Pcs.
4f4c263e-c8d2-4cae-8f77-0cbaa3562f2d	c1	ORGANIC ORANGE BLAST 250ML.RS.49/-	Organics	Pcs.
e658abeb-8b17-4b64-bdea-f31fe63bae9e	c1	ORGANIC ORANGE JUICE 1 LTR RS.149/-	Organics	Pcs.
ea2c17dd-ca37-488a-bef2-cae7cf85612a	c1	Organic  Panchratan Dal 500g.	Organics	Pcs.
b818700f-8012-4f15-8ee9-42e7cc83fa2c	c1	Organic  Peanut 1 Kg.	Organics	Pcs.
e4dfeefd-60b9-4bff-bafa-400dbdc96c9b	c1	Organic Peanut 500g.	Organics	Pcs.
6d33dd04-f892-4b76-8fb8-3bf5ef1061eb	c1	Organic Peanut Butter 450 Gm	Organics	Pcs.
05dedf4a-fb2c-4688-b21e-0052dcb5674f	c1	Organic Peanut Butter 800 Gm	Organics	Pcs.
2118bd78-8c92-4885-9693-996bc56e050b	c1	ORGANIC PEANUT CHIKKI 33GM	Organics	Pcs.
a41a57a5-5418-4db2-960e-68ef09ac54c2	c1	Organic Pepper Powder 100g	Organics	Pcs.
cd647577-cdb0-4a70-bcfb-4a1142506693	c1	Organic Pizza Mazaa Bites 25gms	Organics	Pcs.
95583220-bfb2-4e69-95d6-6476883cce8b	c1	Organic Poha 500g.	Organics	Pcs.
10d26897-644c-448c-a59e-bd7448020e8b	c1	ORGANIC PRESSED SUNFLOWER OIL 1 LTR	Organics	Pcs.
725487b5-3a7a-4203-8b61-3d67d9d2b333	c1	ORGANIC PUFFED RICE 200G. 0%	Organics	Pcs.
a80a8c86-cc18-433b-a868-59053743f087	c1	Organic QUINOA 500G.	Organics	Pcs.
cd69f322-cafa-4912-b4fc-064aa25a0e45	c1	ORGANIC RAGI FLAKS 150G.	Organics	Pcs.
fbb10823-8ee4-4d59-86bc-95d5fb2a1beb	c1	Organic Ragi Flour 250 Gm	Organics	Pcs.
1c6c0db4-b067-4225-9e79-bc673ab5a232	c1	Organic Ragi Flour 500g	Organics	Pcs.
a0f4591d-dfb4-4b37-9ff8-3aae01547089	c1	Organic Ragi Idly Mix 216 Gm	Organics	Pcs.
2235d146-0e33-4785-9644-b557dbdef0cb	c1	ORGANIC Rasam Powder 100gm	Organics	Pcs.
2fe42339-228c-4929-b7cd-47f20a70850d	c1	Organic Red Chilly 100g.	Organics	Pcs.
fad0116b-b18a-41df-a59a-72336093b92d	c1	Organic Red Poha 500g 0%	Organics	Pcs.
66cdaced-82a1-4e50-8a64-98d4c13d8cf0	c1	Organic Red Rice 1 Kg.	Organics	Pcs.
f54dd3c9-a7f5-468b-b7b3-0ea02bddcadb	c1	Organic Rice Flour 250 Gm	Organics	Pcs.
9e932385-e44c-48d7-b203-d528c4b79938	c1	Organic Rice Flour 500g	Organics	Pcs.
d40b1435-a734-4b68-a342-2419e0efa4b6	c1	Organic Roasted Bengal Gram 500g	Organics	Pcs.
6a6966db-2154-4dcf-86bb-1e2646ea219a	c1	Organic Roasted Vermicelli 400 Gm	Organics	Pcs.
a8d3f697-76ba-42be-ad5c-02e9bef70245	c1	ORGANIC SAMBHAR POWDER 100GM	Organics	Pcs.
7238001c-226f-4c54-9e5f-e51ddf734318	c1	ORGANIC SATTU 500G.	Organics	Pcs.
f015d0e3-14e7-4cb4-bcf6-3231d4a2f182	c1	ORGANIC SESAME CHIKKI 33GM	Organics	Pcs.
f6683949-b1ff-4b7d-ad1f-5a2908982434	c1	Organic Sonamasuri Brown Rice 1kg.	Organics	Pcs.
96810b9b-1116-42e6-9097-9de6e1838747	c1	Organic Sonamasuri Brown Rice 5 Kg	Organics	Pcs.
847c3966-8986-4226-b001-146fa5b5e31d	c1	Organic Sonamasuri Handpound Rice 5 Kg	Organics	Pcs.
f19f1f3a-7900-4626-9ea6-73e94a50c607	c1	Organic Sonamasuri White Rice 5 Kg	Organics	Pcs.
d5bd17fa-4330-4993-ab62-91effffb56e2	c1	Organic Sonamsuri Handpond Rice 1kg.	Organics	Pcs.
ace89a3c-dfff-4d2e-a6df-610094baca5d	c1	Organic Sonamsuri White Rice 1kg.	Organics	Pcs.
0f07a15a-c80e-4a40-9a74-bd985fddf3db	c1	ORGANIC SUGAR 1 KG.	Organics	Pcs.
e4d44606-2e5c-4b72-9ab0-2710e067e01a	c1	Organic Sugar 500g	Organics	Pcs.
989e6a42-4e9d-4e7a-80dd-6453e9c0f744	c1	Organic Sulpharless Sugar 500g.	Organics	Pcs.
02e7cdb4-162c-4ee6-a4c9-edd46be80d0d	c1	Organic Tamarind 500gm	Organics	Pcs.
7214fa4f-9a0f-4573-833e-8a940cdf27e8	c1	Organic Taramind Paste 150g.	Organics	Pcs.
92c71d8d-fe12-4ed8-8ab2-593db1883ebd	c1	Organic Tulsi Ginger Tea 50g	Organics	Pcs.
dd9a55dd-6ce1-44b7-8c9a-1e3a73da5aa8	c1	Organic Tulsi Ginger Tea Bags 25 Nos	Organics	Pcs.
15651ce6-5ed3-49d6-967a-4282829efac4	c1	Organic Tulsi Tea 50g.	Organics	Pcs.
c89ffeae-83f1-4f04-8f9d-8172fee0a5bc	c1	Organic Tulsi Tea Bags25nos.	Organics	Pcs.
79c98fd6-0d5e-4397-b47b-d74e87a3bb6d	c1	Organic Tumric Powder 100g	Organics	Pcs.
267fdea5-9393-416a-9e75-e58ee60829b8	c1	Organic Tur Dal 1kg.	Organics	Pcs.
be101fa6-bac6-4376-b129-bcfeaf76f441	c1	ORGANIC TUR DAL 500G.	Organics	Pcs.
74032320-8f46-4a27-90bb-53becd92f43c	c1	Organic Turmeric Powder 200g.	Organics	Pcs.
df4be889-a84f-4525-9344-9a2fd49d367f	c1	Organic Urad Dal Black Split 500g	Organics	Pcs.
1ea7c9fb-da1b-4515-8a22-427ec887a9d3	c1	Organic Urad Dal Black Whole 500g	Organics	Pcs.
e7fa47ce-3458-4c61-bf59-a4c615653704	c1	Organic Urad Dal White Split 500g	Organics	Pcs.
1a22df6a-97ce-495f-9386-a7db34a9cad2	c1	Organic Urad Dal White Whole 500g	Organics	Pcs.
7ef2e929-d6ab-49b1-9416-94071df5fb77	c1	Organic Vermicelli 400 Gm	Food	Pcs.
95b9e8e1-6739-48e2-8192-8a64bb22170d	c1	Organic Virgin Coconut Oil 500ml	Organics	Pcs.
2623d833-d404-4d51-9841-6c0babc9180c	c1	Organic Wheat 1 Kg	Organics	Pcs.
08517496-2622-4d70-8037-108b35aca88b	c1	Organic Wheat Bran 500g	Organics	Pcs.
1114d8a7-5422-40e4-a22c-00247dd9cffe	c1	Organic Wheat Bran 500g @0%	Organics	Pcs.
6312aee3-2100-4a7d-b924-289d0ed3dec2	c1	Organic Wheat Bran 500gm 0%	Organics	Pcs.
9eca47af-91f3-45af-b843-63e8508d1904	c1	Organic Wheat Dhalia 500g.	Organics	Pcs.
d38df17d-8edb-447c-b7bd-baa3ef0ec184	c1	Organic Wheat Dhaliya 250 Gm	Organics	Pcs.
af64ace4-92d7-40c6-8bda-6ebe16c3dd23	c1	ORGANIC WHEAT GRASS POWDER 100G	Organics	Pcs.
f4e039b1-27f9-46cb-9c47-4c4444533b8a	c1	Organic Whole Wheat Atta 10kg.	Organics	Pcs.
468d9b14-265e-4dda-9428-3aee78afddf6	c1	Organic Whole Wheat Atta 1kg	Organics	Pcs.
f24a1df4-5eec-4c03-a40a-ca63d1c11dc0	c1	ORGANIC WHOLE WHEAT ATTA 5KG.	Organics	Pcs.
a2429262-c39a-4d34-b49f-caa1e3cb3c9f	c1	Organic Whole Wheat Atta Noodels 60g	Organics	Pcs.
1d2d7b25-cc29-4777-87d0-8b2b98f0cb94	c1	Organic Wild Honey (Infused with Ginger)	Organics	Pcs.
f44d4451-f7c6-4a01-a5ee-dbabeecc7408	c1	Organic Wild Honey (Infused with Tulsi)	Organics	Pcs.
dcaa733b-c0d3-44b0-82be-a928f5ffd66b	c1	Organic Wild Honey (Infused with Turmeric)	Organics	Pcs.
1ec73f33-dc6f-452a-9046-b364e2f73ae9	c1	Orien Pie 28g.X12	Chocolate	Pcs.
4bd301de-976e-42e0-a6f3-0d97a55533cf	c1	Orika Black Pepper Whole 1kg	Spices	Pcs.
14aa4be7-7339-42e5-a04d-4bf76699838f	c1	Orika Italian Seasoning 500gm	Food	Pcs.
ba33341b-b797-4cf4-bebf-cda52acca8b3	c1	Orika Italian Seasoning 85 Gm (Sachet)	Food	Pcs.
091bc8ff-74f5-4a45-80a2-f090436862f7	c1	Orika Oregano Flakes 500gm	Food	Pcs.
94a5e40b-3d89-4ee6-a886-b1e62592e8d3	c1	Orika Peri Sprinkler 500gm	Spices	Pcs.
2069df76-2536-45f3-ac29-a7cf9222e637	c1	Orika Red Chilly Flakes 85 Gm (Sachet)	Food	Pcs.
e624a837-8e12-4297-bb1e-515c576c1a61	c1	Orika White Pepper Powder 1kg	Spices	Pcs.
ac78da65-f964-4b2d-8948-5abb52514441	c1	ORION CHOCOPIE	Biscuts	Pcs.
6aa96ac4-fb9e-4dec-bf84-297066c512cb	c1	Orion Gift Pack Rs.199/-	Biscuts	Pcs.
09eba1de-5fb4-4204-8792-10e3327fc03a	c1	Orion Gift Pack Rs.239/-	Biscuts	Pcs.
cf65029b-00aa-4621-a2e9-5b239cddedc7	c1	ORION PIE 28GM.X4 RS.50/-	Chocolate	Pcs.
7ce7650f-18a9-48e5-9439-b3b851e94538	c1	Orion Pie 28gx6	Chocolate	Pcs.
e94b75f7-5a71-4a62-828a-06d252c85a11	c1	Orion Pie New 31g.X12	Chocolate	Pcs.
4f499bfa-965a-4b3e-a274-bec9a14e8bce	c1	Orion Pie New 31g.X4 Rs.50/-	Biscuts	Pcs.
dfc39bd4-45ff-426d-b5ef-9fda63c4759a	c1	Orion Pie New 31g.X6 Rs.75/-	Biscuts	Pcs.
2a4b6b02-def0-4347-80a4-2e467a4df520	c1	OS Cranberry Juice 1ltr.Rs.175/-	Drinks	Pcs.
753ea40d-cef8-432a-b84d-fc40e777d86f	c1	O Smart Natural Mixer Ginger Ale 250ml	Drinks	Pcs.
27c1d552-df9c-4303-8512-c06d294c5ca3	c1	O Smart Natural Mixer Regular Tonic Water 250 Ml	Drinks	Pcs.
60d5b01d-a28c-424e-bea6-a7a4e1d29c26	c1	Oya Chocolate 180g.	Chocolate	Pcs.
5b48dc4e-ac2e-4388-9698-16956fe92342	c1	Oya Chocolate Waffer Stick 300g.	Biscuts	Pcs.
cd409be9-9503-4015-9b17-64fa3a832ade	c1	OYA CHOC.ROLL 330GRMS	Chocolate	Pcs.
7f5e413c-51b4-453d-8e68-aa20c54f9f69	c1	Oya Cigarku 24pcs	Biscuts	Pcs.
e59cff0a-eb70-46e5-bf0e-48a7edeb5fb7	c1	Oya Cigarku 45pcs Jar	Chocolate	Pcs.
2807b0c3-4a84-477f-83f3-6dfdf67394cd	c1	Oya Cigarku 5pcs	Chocolate	Pcs.
178a40bd-ff0f-4108-9db6-cc66c274ebb0	c1	Oya Cookies 120g.	Biscuts	Pcs.
44e9f97c-c68f-46b3-aab4-f214ddf028fe	c1	Oya Premium 100g	Chocolate	Pcs.
b5a88bc7-ffcb-42cc-b959-028bc3231e3b	c1	OYA Strawberry Waffer 675g.	Chocolate	Pcs.
6d33a934-1617-4a6e-8a8a-b81de3ad019b	c1	Oya Strawberry Waffer Stick 300g.12x1	Biscuts	Pcs.
3595c9eb-0336-42fe-8b29-ff6405e9af48	c1	Oya Waffer Stick 675g.	Biscuts	Pcs.
d2f735f6-50ec-41a9-9e0c-ba870ea0ede8	c1	Oyester Sauce 510g Smiki	Food	Pcs.
e665abbc-fcf9-4d19-b6bf-5d011a662442	c1	Oyster Sauce 700 Ml	Food	Pcs.
1d3c59c9-e72b-443c-a7f6-d27bda57f100	c1	PAAN DATES 200GM	Food	Pcs.
7d29748d-7537-43b0-af88-a535072b5d1f	c1	Pack Pizza Spice Mix 1kg	Food	Pcs.
f26ae56f-9dcd-46e2-979f-532b134a6c59	c1	Pagoda Shao Sing Hua Tua 640 Ml	Food	Pcs.
4fd93c72-047d-46a8-9fe2-379abc67185c	c1	Palm Sugar 500g (18%)	Food	Pcs.
090c3c84-2c5b-4316-956e-006503cbc163	c1	Pam Olive Oil (5%)	Food	Pcs.
10bca366-892d-4cc9-8c69-f2ac25855c51	c1	Pamp.B/wipes Baby Fresh Rs.220/-	Sanatry Napkin	Pcs.
5d66239f-53e2-4b71-950a-e6806988446c	c1	Pamp.B/wipes Clean Rs.220/-	Sanatry Napkin	Pcs.
a7452653-56d1-4d2d-9dd2-d5a04ee9f819	c1	Pamper Baby Wipes 60 Pcs	Sanatry Napkin	Pcs.
dca28e4b-985c-45f7-98cf-e1c908210db4	c1	Pamper Easy Up 6*21	Sanatry Napkin	Pcs.
5994bc70-d9ef-4f6b-aec5-603d78519acf	c1	Pamper Easy Ups 5*26	Sanatry Napkin	Pcs.
6156d136-90bb-43df-98ee-8699944673ea	c1	PAMPR BW BABY FRESH1XFITMT 8/72	Sanatry Napkin	Pcs.
7dd88cfb-5bfb-45d7-bdb6-ae4f1caba4a7	c1	PAN BESAN THELLY 500G	Food	Pcs.
749fd44d-4a1f-424e-8280-aa48fc937b5a	c1	Pancake Syrup	Food	Pcs.
2fa71c50-6790-42b8-b575-58cdcae709f5	c1	PAN Chilli Garlic Sauce 200ml.	Food	Pcs.
1ef3e2ba-12bd-4ee5-af4c-e730c9d6d164	c1	PAN DALIA THELLY 500GM	Food	Pcs.
87ed8828-8d0e-46d4-bbc7-1b87961cba73	c1	Panda Non Veg Oyester Sauce 510 Gm	Food	Pcs.
67847118-6114-40c8-9586-3304f3a64437	c1	PAN  Hot Chilli Sauce 200ml.	Food	Pcs.
e17f19ad-b015-48b4-82b3-f6672e1957c3	c1	PAN  Hot Spcy Sw Ch Sau 200ml.	Food	Pcs.
df8bbaf4-7c8a-4320-bc0f-68461a4e162e	c1	Panko Bread Cumb 1 Kg	Food	Pcs.
4f1e7d86-9e76-49f8-8d0b-1735de5fcb66	c1	PAN  Light Soya Sauce 200ml.	Food	Pcs.
a61285ee-a438-4f9b-9b54-8d7bbc2c84f6	c1	PAN MAIDA THELLY 500GM	Food	Pcs.
e61ab74f-d1e0-4b9e-9a07-43206e3a7281	c1	PAN Oyester Sauce 200ml.	Food	Pcs.
7546bd4a-9436-4b97-bc60-0581981cac04	c1	Pan Poha 500g.	Food	Pcs.
667cb2ae-a8cb-4feb-838d-a22d2a4edda3	c1	PAN Red Curry Paste 1000gm	Food	Pcs.
c37e5ab7-f856-4d2e-b2c7-335ccb24f7e3	c1	PAN SUZI THELLY 500GM.	Food	Pcs.
ff9bc11c-c28a-4e05-b08e-42120642e067	c1	PAN  Sweet Chilli (Sugar Free) 200ml.	Food	Pcs.
24edbab3-f226-44be-8fc4-f09d410aa162	c1	PAN Swt Chilli Sauce 200ml.	Food	Pcs.
0230948b-501a-4e6c-a353-462147a8f5ff	c1	Paone Pasta Artd (Farfalle) 500gm	Food	Pcs.
5f6c830c-5038-484a-bc45-07b2f429f28e	c1	Paonepasta Speghetti 500gm	Food	Pcs.
7b373302-7295-4b69-bed3-99d3c177afd7	c1	Paonepasta (Tortiglioni ) 500gm	Food	Pcs.
06d2a592-b9ca-4d44-9eb0-6b2fcf2a5294	c1	Papaya Fruit Preserved Green	Confationery	Pcs.
452ccb96-8b97-4231-8021-0ce3d325cc9a	c1	Papaya Fruit Preserved Orange	Food	Pcs.
bca0abf6-d0c4-4abb-b12a-0ca653b4dd00	c1	Papaya Fruit Preserved Red	Confationery	Pcs.
8339aa91-cd26-483c-9841-db86e80b0e66	c1	Papaya Fruit Preserved Yellow	Food	Pcs.
a597bfdc-5980-43b4-aef7-af823b1c9f50	c1	PAPER RICE (CHIDWA MIXTURE) JAR	Food	jar
05596c85-e763-4837-8494-4a7b12847045	c1	Papprika Sliced	Food	Pcs.
1bce3612-6282-44cf-84be-797f9fbff710	c1	Paprika Seasoning 500g	Food	Pcs.
211cef2c-018e-4ace-8120-b850272f84e1	c1	Party Snack 180g	Food	Pcs.
b2f8263e-ecf5-4b3e-8524-cd79d8f931d2	c1	Passata Souce 690ml	Food	Pcs.
a7bcc611-8d31-45d2-96f2-8ada1a837662	c1	PASTA 500GRM	Food	Pcs.
234b267f-f772-49eb-a0d2-5add606ae494	c1	Pasta Agnasi 500g.	Food	Pcs.
da2c8cf8-c6c3-4ba1-b43a-cf29d2369ae0	c1	Pasta Campagna 500g.	Food	Pcs.
765006b3-bc7d-417c-9096-08d013784acd	c1	PASTA  DISANO	Food	Pcs.
64319694-7fab-4e83-b250-0b4cba00a1cd	c1	Pasta Flour 1 Kg	Food	Pcs.
f823bcc0-830b-4ccd-97c0-4c23e1688e67	c1	Pasta Healthy Trio 500gm	Food	Pcs.
d25f566e-7423-4a14-9479-e9c37b08fcdf	c1	Pasta Lasgne.500g.	Food	Pcs.
d98cdbb8-6b6a-4e62-a8ce-211d7801d72d	c1	Pasta Penne Rigate 5kg	Food	Pcs.
07bdb7a4-4579-4c81-8129-32b33ab7bfae	c1	Pasta Saneramo 500gms.	Food	Pcs.
b7ada613-351e-4607-84ae-ab819d8d1ef2	c1	Pasta Zar Animal 500g.	Food	Pcs.
ad151acc-5f7e-4408-9e01-636556eb22f6	c1	Pasta Zar Farfalle 500g.	Food	Pcs.
67fffe33-c589-4934-811e-330bbed44dba	c1	Pasta Zar Fussilli Colour 500g.	Food	Pcs.
5cddcf5e-b872-4868-88ab-9123f1f94779	c1	Pasta Zar Penne 500g.	Food	Pcs.
46e5cdfd-4818-4b26-9285-be043ebfc4d4	c1	Pasta Zar Rice 500g.	Food	Pcs.
b92da5a3-d4e7-431c-9828-ec3caefffdce	c1	Paste Korean Chilli/500gm	Food	Pcs.
7b96e431-a95a-4174-827c-73a041f4c2e1	c1	Paysan Berton Pasteurised Brie 125g	Dairy Products	Pcs.
e264d656-6c68-4254-bb62-b838e43ce8a8	c1	Paysan Berton Pasteurised Camembert 125g	Dairy Products	Pcs.
47e11d55-3f0f-4951-aba8-a7ab5785afa0	c1	PC Balsamic Glazed 250 Ml	Food	Pcs.
342584c8-8681-428b-b0b3-c21fb010f904	c1	PC Balsmic Vinegar 500 Ml (18%)	Food	Pcs.
fb70ba51-75ca-402a-914c-630119956eac	c1	Pc Doritos Dips Mild Salsa 300 Gm Mrp 259	Food	Pcs.
9170cfc2-dfa6-4d4d-b387-2220936d29a0	c1	Pc Doritos Sour Cream &amp; Chives 280gm	Food	Pcs.
4f800b2f-c7b1-4a30-84cf-f9afd25fed60	c1	Pc Quaker Oats Granola Raisin&amp;Almond 400 Gm Mrp.349	Food	Pcs.
2badd120-64ce-48cb-81a9-9a831cffe1cc	c1	Pc Quakes Oats Granola Cranberry 400 Gm Mrp.349	Food	Pcs.
40bdb887-9856-4032-b251-d0b54adbcab2	c1	Peaches Halves in Syrup 840gm	Food	Pcs.
e43c7f07-b1da-4337-b8f8-977927770a38	c1	Peanut Butter	Food	Pcs.
645cafd4-1d84-408f-a441-4c1e166661d1	c1	Peanut Mix	Food	Pcs.
ef0c5e05-0e4b-4d76-b701-22b47b79821a	c1	Peanut Patti 300g	GURU FOOD	Pcs.
95c12103-e77d-4fbb-ad5a-7172cc9765f6	c1	Peprika Seasoning 500gm	Food	Pcs.
1af12c61-e098-4608-bfef-ab543a56c295	c1	Peri Peri Chilli 100g	Food	Pcs.
846fdc06-fa46-4051-aa64-6a5104fd62a3	c1	Peri Peri in Chilli 100gm.	Food	Pcs.
616f92de-c215-4a85-aeec-6d54b6320e69	c1	Peri Peri Seasoning  NS 500GM	Spices	jar
6a66f4d8-6717-4f74-9706-39bd1669f568	c1	Perrier 330ml Can Carbonated Water	Drinks	Pcs.
1d585279-689a-4e51-84dd-cd58ba6e36d5	c1	Perrier 330 Ml Carbonated Water Bottle (IMP)	Drinks	Pcs.
cb26baa0-f6dd-4248-95aa-4385c6096e6c	c1	PERRIER CARBONTED WATER (BOTTLE) 750ml	Drinks	Pcs.
c661f016-e406-4238-b356-42e05ee965e4	c1	PERRIER CARBORNED WATER(CAN)	Drinks	Pcs.
d6a45c3a-4f31-453f-b6c5-eea85a84053b	c1	Perrier Sparkling Drink 750ml.BOTTLE	Drinks	Pcs.
d4efc506-64b4-40f1-a655-6e95f3b49daf	c1	Pesto Sauce	Food	Pcs.
d13a6d87-c226-4e56-a037-b26c576f3d8d	c1	PESTO SAUCE VEG	Food	Pcs.
185a1f73-3e61-4515-b746-758449f917a4	c1	Pickled- Ginger in Vinegar (6*1500gm)	Food	Pcs.
e1b85330-3446-44b3-8d6e-1f4412149423	c1	Pinapple Filling 2.7kg.	Food	kg.
9be60d55-de6c-4d9e-a4b0-cf3c8ccdb513	c1	Pink Paper Corn 100grm	Food	Pcs.
1c1dafce-d887-47bb-aeed-825319911c09	c1	Pista Chio Milk Doubale Chocolate 1 Lt	Drinks	Pcs.
aa3f2976-0faa-4ffc-b960-758e6ebbb469	c1	Pizza Pasta Seasoning Nature Smith(Pouch) 10 Gm	Food	Pcs.
785f9efe-dcd0-4d12-80cc-52a7d6b7832c	c1	PIZZARIA FLOUR 1KG/SEMOLA	Food	Pcs.
0b1f6fab-b960-4866-8968-0ecfddca8082	c1	Pizza Spice Mix Nature Smith Sachet	Food	Pcs.
4f24f68e-8d9c-451f-8c95-ad70d5c60433	c1	Pledge Polish	Cleanor	Pcs.
b05ceb55-872b-48c2-9d4d-a9981e69934a	c1	Plum Squash	GURU FOOD	Pcs.
1c2ed829-7083-429d-ae5e-d65b1bc0ed24	c1	Pocky Banana Stick 12x10x42gm	Food	Pcs.
fb208691-5e33-4401-97fc-9c23803d96d1	c1	Pocky Chocolate Stick 12x10x47gm	Food	Pcs.
4e067242-d494-4334-813a-325a0259d44b	c1	Pocky Cookie Cream Stick 12x10x40 Gm	Food	Pcs.
26b6dcf9-899b-4b60-81b3-7ef5efd1ca82	c1	Pocky  Double Choco 12x10x47 Gm	Food	Pcs.
79e9b684-9ecf-4787-821d-1a4b1eea9ceb	c1	Pocky Matcha Stick 12x10x33 Gm	Food	Pcs.
f3b73175-3253-4156-a397-5a062462e091	c1	Pocky Strawberry Stick 12x10x45 Gm	Food	Pcs.
8b5ab075-2509-47b7-96da-c0719f1ba35a	c1	Pomace 5ltr.	Oil	Pcs.
97289d43-53ff-44cb-805a-19c080a48064	c1	Pomace Oil 1ltr.	Oil	Pcs.
f7c33141-6069-46d3-a604-9a064bfa7a97	c1	Pomace Oil 5ltr.Cotoliva	Oil	Pcs.
b974f4b6-a754-48e9-a572-531ad351091c	c1	POMACE OIL 5LTR.TIN	Oil	Pcs.
f9fe8604-aca2-414e-aa9f-bd6a27116d13	c1	Pomace Oliv Oil 1ltr.1+1 Offer Mrp.Rs.450/-	Oil	Pcs.
01f47656-c37e-456a-8d48-b83604e32697	c1	Pommery Mustard 500gm	Food	Pcs.
2bb38209-64bd-4dab-a8a8-da225f7eb586	c1	Post Banana Nut Crunch	Food	Pcs.
515b5af6-2dfb-47c0-a7ba-3ac0c4a1ae64	c1	Post Cearls	Food	Pcs.
8138bb1e-1261-496a-ba94-cbebc547906c	c1	Post Cocoa Pebbles	Food	Pcs.
51d329f0-7347-4363-bcc8-ac965e92e06d	c1	Post Cranberry Almond Crunch 14z	Food	Pcs.
74c2a0d5-9b72-48b0-897a-641615b3612d	c1	Posters-Ritebite	Chocolate	Pcs.
6a60d1dd-9da6-4cf7-a5a4-d5e7b75dd467	c1	Post Honey Bunches of Oats Peach Raspberry	Food	Pcs.
9d24d501-2efd-4986-9181-a7e6d133e08c	c1	Post Honey Bunches of Oats Raisin Medley 17z	Food	Pcs.
9b903d6b-232e-4594-a6e0-b4f54d9c751e	c1	Post Honey Bunches of Oats Strawberry	Food	Pcs.
76903c1e-998c-45c4-b867-2a5be0bbb3e1	c1	Post Natural Bran Flaks 16z	Food	Pcs.
13cf8386-dc20-4c9b-8f00-034e6d92175e	c1	Post Natural Raisin Bran	Food	Pcs.
290b135a-8731-4552-b731-47c22e64195d	c1	Post Oats Honey Roast	Food	Pcs.
e697f15f-4881-4329-a1b0-4d7a6bbae835	c1	Potato Chips Bbq 135gm	Food	Pcs.
dba4403b-0570-4b2c-a395-d4567e868d23	c1	Potato Chips Extra Cheese 135 Gm	Food	Pcs.
f0d63e64-ee7b-49ea-b534-a466666252bb	c1	Potato Chips Original 135 Gm	Food	Pcs.
4a924334-e1b4-4002-8636-9398e0db6b34	c1	Potato Chips Sour Cream &amp; Onion 135 Gm	Food	Pcs.
4c22f50b-d156-4260-8181-7700a0329695	c1	Potato Snacks Chips	Food	Pcs.
58c62a60-b51a-4b79-850a-9c532100383d	c1	Potato Starch WIND MILL 500G.	Food	Pcs.
9aaf6681-2a18-434b-9c28-1969c1891e1b	c1	Potato Stick 50g.	Food	Pcs.
75229852-5bab-42ba-a9c7-75d0bc69e8e1	c1	Pouch Mango Pickle 400g.Mrp.Rs.67/-	Food	Pcs.
a8937c93-e0e0-412a-9541-0b7f99651fc6	c1	POUCH MIXED PICKLE 400Gmrp 67	Food	Pcs.
765812a3-8e25-400c-aa63-f813103c1404	c1	Pou Chong Green Chilly Sauce 600 Gm	Food	Pcs.
cc98c254-8865-4b0e-b8dd-841eadd59305	c1	Pou Chong RED Chilly Sauce 600 Gm	Food	Pcs.
461ed538-d3be-4b2a-b9a1-845c0874cbec	c1	POUCH PICKLES 400G CHILLYmrp 105	Food	Pcs.
8eccd04e-2f06-42af-8ec0-16d23a511a17	c1	Pour Over Starter Kit Black	Electrical Goods	Pcs.
b63ada7d-88cf-44b4-af65-82ece46f59c8	c1	POWER CABLE	Electrical Goods	Pcs.
68100e5e-247c-4785-9a68-96f5c542dd76	c1	PRB Premium Oyster Sauce 510g	Food	Pcs.
cdb64cea-fd1f-4bbc-9e59-7194486d57dd	c1	PRB Superior DarKSoy Sauce 600ml.	Food	Pcs.
2d3f2785-6655-44ee-9cff-ce62269bc93b	c1	Prb SUPERIOR LIGHT SOY SAUCE(600ML.)	Food	Pcs.
52c54bdb-6bb0-4873-97d2-5f3f62e73d5f	c1	Prb Teriyaki Sauce(Marinade &amp; Sauce	Food	Pcs.
eb0e4bc2-56d2-4227-be05-330974980d45	c1	Premier Salute Peach (Blue) 750 Ml	Drinks	Pcs.
972773b8-07cc-4bd3-b9b9-d5833696ab36	c1	Premier Salute Rasp &amp; Mix (Purple) 750 Ml	Drinks	Pcs.
01d8f249-1f7b-43af-8a81-a827bdc9603e	c1	Premier Salute Rasp &amp; Peach (Pink)750ml	Drinks	Pcs.
6404eac3-ee85-4c16-aaf8-a62d3a511c2e	c1	Premier Salute Red Grape 750ml	Drinks	Pcs.
275556f2-cbe3-486a-bad8-532f44c0370c	c1	Premier Salute White Grape 750ml	Drinks	Pcs.
f0924f2e-1bb1-40fc-a513-55bff859e533	c1	Premium Basa Fish Fillet 2 Kg	Food	Pcs.
e5d04af7-e44d-4409-b4dc-89611b303abd	c1	Premium Fruit Sweet Trey 435g	Food	Pcs.
ea34e9cd-3f18-46ee-a586-38a93e58c3d8	c1	Premium Impro Grated Parmesson Chees 100gms	Food	Pcs.
dbf49f43-f3c3-4024-ac11-731847b5002b	c1	Premium Veggie Decker 1.2kg (Burger Patty)	Food	Pcs.
43622e20-0c2c-47ce-8cc8-74145f5313bf	c1	President Unsalted Butter-500gm	Dairy Products	Pcs.
534a324c-f2b8-4657-b3ca-00a6d35df368	c1	Prestige Dry Yeast 500gm	Food	Pcs.
87896178-9421-45c2-927a-9122b19e9fb0	c1	Prezioso Balsmic Vinegar Glaze 250 Ml	Food	Pcs.
bb9ccba6-2c10-4776-9823-7f0cb4be842d	c1	PRIMO GREEN PITTRD OLIVES 430g	Food	Pcs.
9d4947f9-aa5e-4c36-82c3-a140a451cb23	c1	Pringle 168 Gm 18%	Food	Pcs.
4983a661-fbd9-4b1b-a269-4366d3e10b74	c1	Pringle 181g.Bbq	Namkeen	Pcs.
63df38de-d031-400b-882e-a5c25f9d9106	c1	Pringle 181g.Jalapeno	Namkeen	Pcs.
e6737518-cca2-431f-a8e8-ea1d34324460	c1	Pringle 190g.	Namkeen	Pcs.
48a6ee77-fa65-4a58-ac9e-fb6db0d680bf	c1	Pringle 190g.Org.	Namkeen	Pcs.
d9b8243e-1026-47d6-af59-98e5e4f7cf31	c1	Pringle 190g.S C O	Namkeen	Pcs.
d39e4206-d9b0-47bf-a608-25cf33a1f282	c1	Pringle 40 Gm	Namkeen	Pcs.
a33664bc-30ac-4e37-9318-ef55da749e44	c1	Pringle 50g.	Namkeen	Pcs.
12f5db06-f2dd-42a8-ad78-5cab0a7af49d	c1	Pringle BBQ	Namkeen	Pcs.
20c1d6de-ea42-4d81-96cb-68c197d38032	c1	Pringle Cheese Chese	Namkeen	Pcs.
6d257989-16ef-4b73-86d3-f69fbadb44fa	c1	Pringle Chips 1*19 (18%)	Food	Pcs.
08c34682-4d00-4e88-b5cb-fee1c1c02667	c1	Pringle Hot &amp; Spicy	Namkeen	Pcs.
6926d4e1-ecd4-4989-95e6-4c075dc9cf4a	c1	PRINGLE MD  140G. RS.139/-	Namkeen	Pcs.
409742a6-eeeb-4df5-b8f6-fc5cfc1fd78c	c1	PRINGLE MD.150GMS.	Namkeen	Pcs.
cbdd4a5d-7ad7-4558-b72a-593c23607738	c1	PRINGLE NEW FLAVOUR 165 Gm	Food	Pcs.
c65978bb-a1ec-435b-9508-a937e93ca487	c1	Pringle New Flavours	Food	Pcs.
56b0b042-980c-4d7d-bcae-a22a7b411e67	c1	PRINGLES 165 GM PRODUCT OF BELGIUM	Food	Pcs.
405c8163-8eeb-4f68-b918-a19cc763cbeb	c1	Pringle Salt &amp; Vineger	Namkeen	Pcs.
56e72a52-9227-41f8-b17e-3d46efbf51bc	c1	PRINGLE SM 40Gms.	Namkeen	Pcs.
f8f3f467-e485-47cd-addc-85e99322af30	c1	Pringle Sour Cream Onion	Namkeen	Pcs.
69c2a2ce-87ef-43c7-b046-1156423d9ba7	c1	Pringles Potato Chips	Food	Pcs.
7499442d-69f5-4bc8-95b3-bb7df668ba1c	c1	Pro-Fit Makhana BBQ Mrp.175	Food	Pcs.
9ba5c45a-4bb0-4716-bf72-07dd2c4a9e15	c1	Pro-Fit Makhana Peri Peri Mrp.175	Food	Pcs.
06430957-7814-43c4-a9df-0f1027e6631c	c1	Pro-Fit Makhana Pudina Mrp.175	Food	Pcs.
38a1513d-92e5-4487-8850-52bb921ca548	c1	Pro-Fit Makhana Tikka Masala Mrp.175	Food	Pcs.
7100772a-b48a-4d71-95a1-90f6a954fd5b	c1	Provogue   Deo Devour 150ml.	Deo	Pcs.
ef3025c4-9c34-49f8-a965-e00ecf86e3c2	c1	Provogue Deo Mysterious Vice 150ml.	Deo	Pcs.
8e0e169d-7e3b-41b8-8940-2dc0b9b5aba7	c1	Provogue Deo Seductive Appeal 150ml.	Deo	Pcs.
0fff6a49-8e5c-44c9-9d84-db1667568317	c1	Provogue Deo Sensousgame 150ml.	Deo	Pcs.
01ef88ab-8826-45fc-8b13-ae77ffd8fbb5	c1	Provogue Deo Surreallust 150ml.	Deo	Pcs.
bd0c7318-5265-4867-a0e5-d1a964cfe5f6	c1	Provogue Deo Swagger 150ml.	Deo	Pcs.
92132a2a-3880-4114-a6d6-2493d9bc440a	c1	Provogue Deo Wild Disire 150ml.	Deo	Pcs.
5107f9e3-7a46-48f6-a9b2-e53ceaeecc5c	c1	Provouge Deo Darkaffaries 150ml.	Deo	Pcs.
ceca27f7-545b-4aa5-b097-0c9deda8ea44	c1	Provouge Deo Deep Secret	Deo	Pcs.
f66a9daa-7444-4567-bc80-e08f350d33a9	c1	Provouge Deo Power Play	Deo	Pcs.
7fa4fe3d-0912-47a7-9a9f-6b4327ecad9e	c1	Provouge S/gel Euphoric Currunt 200ml. Rs.120/-	Deo	Pcs.
72b06a83-46ea-45bc-a7ce-fb418078c69c	c1	Provouge S/gel Fresche Passion Rs.125/-	Deo	Pcs.
70ededa0-06c1-4e82-a63a-2a6e4f73d964	c1	Provouge S/gel Milk Rush 200ml. Rs.135/-	Deo	Pcs.
35c9470a-d55d-4597-b3de-d09e94c6f5ac	c1	Provouge S/gel Pristine Spirit 200ml. Rs.125/-	Deo	Pcs.
f582e7fe-5bea-4a54-8c3e-84f10d290650	c1	Provouge S/gel Urban Spa 200ml. Rs.120/-	Deo	Pcs.
ec0b36bc-a4af-4fe8-94a1-9cf4fa9c1abc	c1	ProvougSupple Delight 200ml.Rs.135/-	Deo	Pcs.
54d84256-ab68-402f-ad5e-bf7cad3c73da	c1	Pure &amp; Natural Juice 2ltr.	Drinks	Pcs.
3abce564-b922-477f-91de-b5431988df1b	c1	Q Smart Natural Mixer Ginger	Drinks	Pcs.
e4a2b14e-7231-44e2-be7a-20a28ca30bb0	c1	Q Smart Natural Reguler Troni	Drinks	Pcs.
1a8e709b-57f6-405c-9736-a12c5207035e	c1	Q Smart Natural Tonic Water	Drinks	Pcs.
b9a8531c-6084-481f-9856-c3ac4b83380a	c1	QUAKER Oats	Food	Pcs.
9eb56eb3-23c8-49ae-b2ac-a4df9826e4a0	c1	Quaker Oats 1 Kg	Food	Pcs.
a74eec25-f022-4777-a290-4ec8020a69c5	c1	Qua Natural Mineral Water 200ml. Rs.20/-	Drinks	Pcs.
da1f9690-60e7-4eed-8bf0-64aa31fcb4b1	c1	Qua Natural Water 1Ltr.Rs.100/-	Drinks	Pcs.
925c098c-81fb-4fe6-9242-93130fd474de	c1	Qua Natural Water 500ml Mrp-65/-	Drinks	Pcs.
67d1451f-51cb-46ac-8d8d-99eee5fe7458	c1	Qua Natural Water 750ml	Drinks	Pcs.
a6b128f2-9554-4799-928b-d2efcd59b6d6	c1	Queen Jelly 55 Gm.(Sweet Rainbow)	Confationery	Pcs.
f4d3a4b8-6e87-411d-a3d6-c14609924136	c1	Quinoa Black Seed 500g	Food	Pcs.
f5942ef8-fb53-4cc4-bebc-dc825e715ac3	c1	QUINOA CHIPS JAR	GURU FOOD	jar
79c484b9-a2fc-4d67-92a3-7741f9f0c607	c1	Quinoa Fingers (Masala- Munch)	GURU FOOD	jar
66747c4c-8a17-48ed-832f-4bacb7befe28	c1	QUINOA LACHHA JAR	Food	Pcs.
9154a7cd-3640-4951-9ab5-cfb398e96163	c1	Quinoa Red Seed 500g	Food	Pcs.
ef3e9527-db36-4033-b1c5-bf4ce977c8f9	c1	Quinoa Seed	Food	Pcs.
bc714536-0b85-4a0f-92be-fa7ff905e7b1	c1	QUINOA STICKS JAR	GURU FOOD	Pcs.
ab91ed62-ae03-45ff-9ab6-d3239f381f66	c1	Quinoa Strawberry	GURU FOOD	Pcs.
fc39ec50-0af0-4c32-85bf-bca6a65237c2	c1	QUINOA (WHITE) (500GX25)	Organics	Pcs.
e9a31ada-b85a-4c62-aab1-f881ca1084e6	c1	Quintet Cinnamon Ch Gum S/F 5pc-10.5gm	Food	Pcs.
a4fbb6a7-cb76-47a0-9828-8bde0b18c0a4	c1	Quintet Dynamic Ch Gum S/F 5pc-10.5gm	Food	Pcs.
1e49b7cc-ba4e-4de4-b9c7-d9e0274b5ccb	c1	Quintet Mix Fruit Chgum S/F 5pc-10.5gm	Food	Pcs.
332c3e71-fbb7-4242-96f0-1f53742bfe05	c1	Quintet Peppermint Ch Gum S/F 5pc-10.5gm	Food	Pcs.
a29049a2-bdaa-4136-a7bb-632d2867d4f1	c1	Quintet Spearmint Ch Gum S/F 5pc-10.5gm	Food	Pcs.
9eeb0817-e6db-496d-8ecd-e7c234e41a4f	c1	Quintet Watermelon Ch Gum S/F 5pc-10.5gm	Food	Pcs.
fa35eefb-1bc2-43d9-b8f5-5b412bf6bd2a	c1	Raavi Dark Soy Sauce 200ml.	Food	Pcs.
5dcc9725-2802-49df-83be-49931c9abb37	c1	Raavi Light Soy Sauce 200ml.	Food	Pcs.
05bdb405-8d14-40d0-866b-36bb69c17d67	c1	Raavi Stir Fry Sauce 200ml.	Food	Pcs.
eb39f845-f6ce-409d-98f2-b7b4aedc67ea	c1	Radish Pickle 1 Kg (12%)	Food	Pcs.
0892b496-30e0-48eb-8c36-f4c4e0c62dcf	c1	Radish Pickle(500)Gm	Food	Pcs.
e31f8e1a-b819-4089-b788-146ba67e7d9e	c1	RAGI CHIPS JAR	GURU FOOD	jar
58cc2ce1-9380-4b5d-96ab-a8ec7a6216ce	c1	RAGI CRISPS JAR	GURU FOOD	Pcs.
b3e0b1b1-9026-4849-96b3-9aa6abca5a71	c1	RAGI LACHHA JAR	Food	jar
5e4c6aa2-2a74-405a-85e0-f3fd1c2cdfb5	c1	RAGI LOOP JAR	GURU FOOD	Pcs.
3fbb4172-61c8-4eb7-9832-14b45512f858	c1	RAGI STICKS JAR	Namkeen	Pcs.
32e223ce-77ea-43ec-94ca-c11e15f5e33d	c1	Ragi Tadka Jar	Namkeen	Pcs.
0db392de-427d-4727-b494-a2bf22dad56e	c1	RAGU PASTA SAUCE CHEESE RST. GARLIC PARM.12*400 GM	Grains	btl.
2534e9f6-4627-4465-b988-3c638da99cb0	c1	Raimbow Hard Chees Block	Dairy Products	kg.
bd711482-1fe2-4045-a95d-6ac5c1fdf1a8	c1	RAINBOW HARD CHEES 4.5KG	Dairy Products	kg.
e6553aa7-8feb-4b7f-9cf2-3e3f7da9248e	c1	Ramen Noodel 300g	Food	Pcs.
0f5556c8-c729-4bd2-8169-e9558656c359	c1	RANI APPLE 200ML.GLASS BTL.	JUICE	Pcs.
b2ffefe1-f814-4b44-83d4-c0c205c020fc	c1	Rani Apple Flavour 1.5 L	JUICE	Pcs.
1ac3add3-4777-41cb-a695-95e55cc88515	c1	Rani Cocktail Flavor 240ml	Rani Can	Pcs.
6a4a07a2-58e0-4c81-87cc-51dcfa32210c	c1	RANI COCKTAIL FLAVOUR 200ML. GLASS BTL	Rani Can	Pcs.
0a8e0fb8-7ee8-448b-8c33-b08612045fb6	c1	Ranieri Blue Olive Oil 1 Lte	Oil	Pcs.
d46bb137-3b84-4d47-a624-85d0f3a0119b	c1	RANI FLOAT GUVAVA 180ML.	Drinks	Pcs.
0ecad99a-f284-432c-8843-c2aa7d915de4	c1	RANI FLOAT MANGO 180ML.	Drinks	Pcs.
0541408d-623a-4ce3-9a54-c59835ee4973	c1	RANI FLOAT ORANGE 180ML.	Drinks	Pcs.
e69a8755-bd46-4a91-94ff-c2f4f71b60b1	c1	RANI FLOAT PEACH 180ML.	Drinks	Pcs.
919ca403-f756-4c20-88af-4ef3220a228f	c1	RANI FLOAT PINAPPLE 180ML.	Drinks	Pcs.
d8e044bc-e3b8-4c3d-854e-21e1130ed388	c1	RANI FLOAT STRAWBERRY &amp; BANANA 180ML.	Drinks	Pcs.
02cc00f0-5cfb-485f-a181-51ebde799139	c1	RANI GUVAVA 240ml	Rani Can	Pcs.
2ec86580-8cbb-4e7a-ba51-88b64d440fbd	c1	RANI GUVAVA FLAVOUR 200ML. GLASS BTL.	JUICE	Pcs.
db551913-f1d6-4053-81cb-12248645740c	c1	Rani Juice 180ml	Rani 180 Ml	Pcs.
5dbf287f-7808-4262-b2ba-f20ceea4eb51	c1	RANI MANGO 200ML.GLASS BTL.	JUICE	Pcs.
efce4379-4f73-407d-b000-b49f916472cc	c1	Rani Mango Flavour 1.5 L	JUICE	Pcs.
a89918ab-6126-438b-9829-35c3bf7299bb	c1	Rani  Mango Flavour 240ml MRP.70/-	Rani Can	Pcs.
96f171ee-3989-4dda-b3b4-699267b7a0c0	c1	RANI ORANGE 200ML.GLASS BTL.	JUICE	Pcs.
536cbc0d-fc86-437c-9be8-ef72341e8d5e	c1	RANI  ORANGE 240ML.	Rani Can	Pcs.
73b3ba2c-1084-481d-bf78-10939a676389	c1	Rani Orange Flavour 1.5 L	JUICE	Pcs.
647c7062-d3cc-4029-b983-0c7f6d39c5cd	c1	RANI  PEACH 240ML. MRP	Rani Can	Pcs.
f6af6114-070e-4504-9f4a-1a755f701abf	c1	RANI PINEAPPLE 240ML.	Rani Can	Pcs.
9a620ba9-989d-4877-b8dd-2d9ff78c8866	c1	Rani Strawberry Banana 240ml	Rani Can	Pcs.
20e92555-a795-43ed-a44f-9e4460a3c810	c1	RANI STRAWBERRY &amp; BANNA 240M	Rani Can	Pcs.
eea91ef0-f192-4008-be5a-97a74c118aab	c1	Rasmalai Cake-200g	GURU FOOD	Pcs.
17b34cbd-11d4-4e94-87a6-cf6272c0a8b6	c1	Ravi Canned Coconut Milk 5-7% 400ml.	Drinks	Pcs.
aa799640-6f88-4be5-b117-f2e9fc2fce89	c1	RB Breakfast Bar Apple Box of 6 +Rs.22-Bar Free	Chocolate	Pcs.
289f5b6c-62ac-4218-ae7e-fe16635881df	c1	RB Breakfast Bar Assorted Box of 6 +Rs.22-Bar Free	Chocolate	Pcs.
79d27120-77b3-4992-8412-d97f0e9217a8	c1	Rb Breakfast Bar Blueberry Box of 6+22rs.Bar Free	Chocolate	Pcs.
467646df-4f69-48ce-b29b-52219d9e8d09	c1	RB Breakfast Bar Creamy Choco Box of 6	Chocolate	Pcs.
f88d8630-b476-4b67-b22d-dadc8e3ed605	c1	RB Breakfast Bar Rasberry Box of 6 +Rs.22-Bar Free	Chocolate	Pcs.
6debcc1c-4abb-4984-8641-1dc7ad04294e	c1	RB Breakfast Bar Strwberry Box of 6 +Rs.22-Bar Free	Chocolate	Pcs.
59912d0b-d9e8-445c-8370-486ee5762aea	c1	RBK DEO 150ML. RS.165/=	Deo	Pcs.
c67f1e40-2d9e-488c-928a-e2b9da21e033	c1	RBK DEO 150ML.RS.199/-	Deo	Pcs.
12e4be3e-c11f-4f31-aeda-de8be8f710c7	c1	RBK Deo Force India Ml.	Deo	Pcs.
14f4c387-919b-4d6b-ace0-ee3eea755c26	c1	RBK DEO MRP.185/-	Deo	Pcs.
125c87c7-60ec-4a79-b3c9-75c883f025bd	c1	RBK M Deo Cmbo 450ml.Rs.599/-	Deo	Pcs.
1cc04102-f54c-4387-a6b9-9f0c15ac9896	c1	RBK M DEO COMBO 450ML.RS.450/=	Deo	Pcs.
17fb2ae8-f363-461e-bf9b-1b95e6d42474	c1	RBK M Deoreeavange Hulk Green	Deo	Pcs.
c70c5bfe-e3ef-49e3-8e85-a2631cd6f58b	c1	RBK M Deo Reeavenge Cpt White	Deo	Pcs.
a8fb7ca5-121e-464e-a999-904e0eb56bff	c1	RBK M Deo Reeavenge Iron Red	Deo	Pcs.
6adb9d9c-e929-4396-a412-fcd277269d2b	c1	RBK M Deo Reegnite 150ml.	Deo	Pcs.
75294717-12db-4880-a3e5-5f9b2171cb3f	c1	RBK M Deo Reespark 150ml.+25ml.	Deo	Pcs.
b7835195-dc6b-4baf-a95b-73c4f2565e82	c1	RBK M DEO Reesports 150ml.	Deo	Pcs.
962d47ee-3690-414a-afa4-a07e830bb387	c1	RBK M DEO REFUSE 150ML.+25ML RS.180/-	Deo	Pcs.
857c59ff-3137-4107-94c2-54f16859413d	c1	RBK M EDT+DEO GS Regame	Deo	Pcs.
2669580e-cee5-4e87-8976-8cc23119141d	c1	RBK W DEO 150ML. RS.199/=	Deo	Pcs.
7d0d57b7-25f4-40d2-a402-70967e6a798d	c1	RBK W EDT+DEO GS Reefresh	Deo	Pcs.
139f41b3-0e50-4c1d-b4cd-f9e0d3eb040f	c1	Real Active Coconut Water (200ml) Mrp.52.00	JUICE	Pcs.
229d8402-ca52-43d3-944e-8355cc06b602	c1	Real Fruit Apple 1 Ltr Mrp.105	Drinks	Pcs.
eb188d8e-f1a6-4d69-95d2-a214dd62f374	c1	Real Fruit Apple (1ltr) Mrp.115	JUICE	Pcs.
9665ef32-7ed8-4fec-83ea-a036f0e3ab39	c1	Real Fruit Apple (200ml) Mrp.20	JUICE	Pcs.
7e32fc33-e656-452f-8201-d83e3ac704dc	c1	Real Fruit Cranberry 1 Ltr Mrp.130	Drinks	Pcs.
a0af0b0b-61dc-4c07-bf17-3c2a79c980e9	c1	Real Fruit Guava (180ml) Mrp.20	JUICE	Pcs.
433d3b09-b952-4189-8c6e-76dcffb3fbbe	c1	Real Fruit Guava (1ltr) Mrp.100	JUICE	Pcs.
57a328e4-b65b-4ae5-9851-7d03af7b5501	c1	Real Fruit Guvava 1ltr.Mrp.100/-(Free 200ml.)	JUICE	Pcs.
b6ea53ff-2044-4d5f-a6a7-720618b6f5d8	c1	Real Fruit Litchi (1ltr) Mrp.125	JUICE	Pcs.
3288f700-4bb0-478b-93c3-6b82bd97c7f6	c1	Real Fruit Litchi (200 Ml) Mrp.20	Drinks	Pcs.
563a7e9c-6607-4e5a-a822-b1734120b613	c1	Real Fruit Mango (1ltr) Mrp.115	JUICE	Pcs.
131d153c-7569-40f5-a504-07a18086cdf0	c1	Real Fruit Mango (200ml) Mrp.20	JUICE	Pcs.
ea1f26d2-fdac-4c7d-abab-0cf794af78c0	c1	Real Fruit Mix Fruit (1ltr) Mrp.128	JUICE	Pcs.
95127d73-7588-4daf-a29b-ef4e648c2e99	c1	Real Fruit Orange 1 Ltr Mrp.110	Drinks	Pcs.
f8714f5b-6a35-47d6-9a39-1931ea71e20d	c1	Real Fruit Orange (1ltr) Mrp.130	JUICE	Pcs.
4944e12d-84e8-4e11-8d35-8f073e12d5a9	c1	Real Fruit Orange (200ml) Mrp.20	JUICE	Pcs.
476c23b6-844b-45cf-a69b-ded69885a957	c1	Real Fruit Pineapple 1 Ltr Mrp.105	Drinks	Pcs.
f99e48c9-d1db-46dc-9054-5a3b988a83ed	c1	Real Fruit Pineapple (1ltr) Mrp.130	JUICE	Pcs.
5dd2c61a-d421-42a9-9c72-1fe55ebddab5	c1	Real Fruit Pineapple (200ml) Mrp.20	JUICE	Pcs.
a2bbe775-2c99-42ce-aaac-db0f2673ca31	c1	Real Fruit Pomegranate (1ltr) Mrp.110	JUICE	Pcs.
a0b94024-affa-4077-81a9-ff026d2bd68c	c1	Real Fruit Pomegranate (200ml) Mrp.20	JUICE	Pcs.
9a5379bc-cbb2-4bc4-a466-b230a930dfbc	c1	Real Lichhi 1ltr.Mrp.105/-(200ml.Free)	Drinks	Pcs.
bfe6411f-48c3-413e-85b4-db24c04079bf	c1	Real Mix Fruit (200ml) Mrp.20	JUICE	Pcs.
e6a522bf-37f9-406e-b0a5-ab2792575078	c1	Real Thai Red Qurry Paste 50gms	Food	Pcs.
cb61bf0c-7cbf-478a-ae3a-87952383bd2c	c1	Real Thai Rice Paper Round 16cm. 100gms.	Food	Pcs.
cc3c491f-4e10-4959-9f5f-4da5252a0b83	c1	Real Thai Rice Stick 3mm(375gms)	Food	Pcs.
4dd24fb6-9d66-4165-8680-dd9ee7fa2564	c1	Real Thai Rice Stick Pad Thai Noodels 375gms.	Food	Pcs.
391c9cf9-7574-4c75-9039-2f8d2a8191c3	c1	Real Thai Rice Vermicelli (375gms)	Food	Pcs.
1c78a57f-7c0b-4f08-b08b-e377ba1fd6f9	c1	Real Thai Sriracha Hot Chilli Sauce 150ml.	Food	Pcs.
bd918724-4994-43bf-af5e-c8e2e8218b5e	c1	Real Thai Yellow Qurry Paste 50gms.	Food	Pcs.
31ca9ac2-875e-40a2-bf2b-166f56439535	c1	Red Bull 250ml.	Drinks	Pcs.
48c353ec-e7e1-4e7f-b278-f0c4d7e65d10	c1	Red Bull 250ml*24	Drinks	Pcs.
95cce609-707a-46ab-9c33-37f240a7ecd6	c1	Red Bull 250ml.4 Pack Mrp Rs.380/-	Drinks	Pcs.
01a8ef2a-e2cf-41f8-bf6b-cdfc0c688756	c1	Red Bull 250ml. Rs.95/-	Drinks	Pcs.
e4dfed77-f2c0-462f-abe6-021fa0d8c281	c1	Red Bull 250ml Rs.99/-	Drinks	Pcs.
da54d8e0-ce57-4e49-9bf3-d91f4753e90c	c1	Red Bull 355ml.Rs.110/-	Drinks	Pcs.
a04ac670-7773-4a2f-b031-fcf7239ba9b1	c1	Red Bull 355ml.Rs.120/-	Drinks	Pcs.
e3035cf4-c085-4e80-94ec-fcbaa85835b2	c1	Red Bull 4 Pack(250ml.X4)Mrp.Rs.340/-	Drinks	Pcs.
35f1e993-c994-407c-92ef-f1b756fcad90	c1	Red Bull Can Pack of 4	Drinks	Pcs.
af3998f6-9065-4eac-a655-b7f8a874e77d	c1	Red Bull Energy Drink 250ml.	Drinks	Pcs.
bcab683e-c3fe-4cfa-9811-2145bd57a86e	c1	Red Bull Energy Drink 250ml Mrp.115	Drinks	Pcs.
28ba65bd-184e-4d54-8265-146c1acb6728	c1	Red Cherry Pitted in Syrup 810 Gm	Food	Pcs.
480acbda-6c5a-46e0-8b29-7374471c0c53	c1	Red Chilli 700 Ml	Food	Pcs.
f9a08437-369d-48fe-9e38-f983f4fa569c	c1	Red Curry Paste 1kg	Food	Pcs.
b031717c-3e14-495b-ac73-ed726bfab11f	c1	RED CURRY PASTE 400 GM	Food	Pcs.
5545231b-0aed-42a9-afde-0548a68ce055	c1	Red Lotus Flour 1 Kg	Food	Pcs.
868fe65e-fa77-4034-9de5-417fd563fcca	c1	Red Lotus Flours 1 Kg 18%	Food	kg.
17685117-f881-4c59-aa90-ae1237f1f853	c1	RED MARASCHIND CHERRIES WITH STEM 720 ML	Food	Pcs.
83756f57-f123-4561-b67d-1882880d1ed2	c1	RED PAPIRKA SLICED 3.1	Food	Pcs.
5152f7c8-3691-44dd-a61d-8d12bead81af	c1	Red Peprika680gm	Food	Pcs.
8269c6f9-b33c-4885-82a0-a20f8c78d996	c1	RED QUINOA 1 KG /NOURCERY(EXAMPT)	&#4; Primary	Pcs.
ad9ac0f2-9bc9-4496-a0a9-34c94a816ab8	c1	RED RICE 1KG.	Food	Pcs.
e658596a-23fe-4de3-9ce2-900550101f35	c1	Red Velvet Cake Mix Veg	Food	Pcs.
8a98df33-f008-4149-9aad-efabeaf9affa	c1	Red Velvet Waffle Mix Veg	Food	Pcs.
fac22101-4523-4b2a-a98f-7f667b241b60	c1	Red Wine Vinegar 1 Ltr(Varvello)	Food	Pcs.
e4e7cb8f-2188-4a1a-a5ee-6097e288bfbb	c1	RED WINE VINEGER 1LTR ITALIAN GARDEN	Food	btl.
d0df7e5d-38ff-421b-a779-d044dcce19bf	c1	RED WINE VINEGER PET (1 LTR)	Food	Pcs.
5a25387f-8790-4245-a11b-98e051252e5b	c1	Reggia Fettuccine Pasta 500gm	Pasta	Pcs.
4409236c-a8a3-4710-b97d-92a0b2ca2a17	c1	REGGIA LASANGE PASTA 500G	Pasta	Pcs.
95ebe913-5a07-492b-ada0-9bafa9767be5	c1	Remia Di Jon Mustard 370 Gm	Food	Pcs.
53ea45bb-bf21-4df4-9a05-4a69cd3ba5c0	c1	Remia Dressing	Food	Pcs.
a89724b8-cff1-49b0-96e4-096eb304e428	c1	Remia Mayonaise 1kg	Food	Pcs.
4991bf1c-4617-48aa-a8fd-467a4294164d	c1	Riccotta (Cremeitalia) 500 Gm	Food	Pcs.
ed80f124-7c7c-4ef6-b9f8-e74eaf1a35eb	c1	Rice Cooking Wine Vinegar 750ml.	Drinks	Pcs.
1f9d798b-3cd7-40c2-bb8c-c36951e61e15	c1	Rice Flower JAR	Food	jar
4948d4b7-e32f-4ea0-afd5-12ca1b303072	c1	Rice Paper 22cm,400gm. (18%)	Food	Pcs.
27f0305f-ce69-4f1d-bb49-5d86f54ddd02	c1	Rice Paper 400gm	Spices	Pcs.
56f6e202-234b-49fd-9d73-a0a47d7c74c4	c1	RICE PAPER FARMER 0%	Food	Pcs.
602cbc69-cf62-4eb3-abd7-35ff4f8d336b	c1	RICE PAPER FARMER 400GM (18%)	Food	Pcs.
fa805c3c-8f28-414a-9650-7920d346b9b0	c1	RICE PAPER YOKA 400GM	Food	Pcs.
cac156cf-18b5-4e05-91cf-9308bd8af88b	c1	RICE STICK(500GM) HOW HOW)	Food	Pcs.
e85ac22a-8962-4e95-97a7-5e28e1069923	c1	RICE STICK 5MM HOW HOW BRAND 500G	Food	Pcs.
4572cdcf-d545-4564-b12c-005ecbaf786a	c1	Rice Stick How How 5MM	Food	Pcs.
8d7f82fa-95bd-41a1-a195-9470ac449454	c1	Rice Vermicelli (18%)	Food	Pcs.
085e59a6-f515-4092-9598-dd8dc84a686c	c1	Rice Vermicelli 200 Gm	Food	Pcs.
8fe1f755-cdbf-4109-bd54-aeec5e19187a	c1	RICE VERMICILLI 500GM	Food	Pcs.
770e5f65-315a-4117-8f95-4f4f8c4848ee	c1	Rice Vinegar 600 Ml (18%)	Food	Pcs.
8cc0db38-2a24-4d2c-a3e8-bdfe6eaf6798	c1	Rice Wine Vinegar Mrp.500	Food	Pcs.
2accf012-5fa7-4657-8bc4-d038096e3da2	c1	Ricotta (Cremeitalia) 500GM	Dairy Products	Pcs.
21f12131-632a-4f04-91f4-8b3e06e9e41c	c1	Riscosa 500g. Eliche-48	Food	Pcs.
97564901-e236-4073-8df0-9c074fe36c2d	c1	Riscosa Cannilloni-86 500g.	Food	Pcs.
bb3521cd-88a9-42b2-94bd-8599a94d6214	c1	Riscosa Lasagne 103 500g.	Food	Pcs.
d42a6f28-847f-43bb-8dde-e30f04f5ab05	c1	Riscosa Pasta 500g.	Food	Pcs.
5e42cd40-1d55-4176-9e2e-6b0e50894c91	c1	Riscosa Taglitatelle-81 500g.	Food	Pcs.
3d1105d0-7bd6-477c-8db6-0392b477ef92	c1	Ritebite 99cal Apple Cinnamon 27g.	Chocolate	Pcs.
5e090d82-3400-4aec-95bd-9ac06fed054e	c1	Ritebite 99 Cal Apple Cin Pack of 3 81g.	Chocolate	Pcs.
e922bf4b-c650-409a-9e53-a788f1a24fbc	c1	Ritebite 99cal Apple Cin Pack of 6 162g.	Chocolate	Pcs.
d4527c69-dbc4-4b9a-af69-c5c129eee903	c1	Ritebite 99 Cal Choco Lite Pack of 3 81g.	Chocolate	Pcs.
592e8ab4-a637-4d92-84a1-728fa91f897f	c1	Ritebite 99cal Choco Lite Pack of 6 162g.	Chocolate	Pcs.
f0264726-1447-414f-97a8-2a14754d1d8e	c1	Ritebite 99cal Sugarless Chocolite 27g.	Chocolate	Pcs.
0cba7b9e-3a56-415e-8260-19c8b28f779f	c1	Rite Bite Candy Pack	Chocolate	Pcs.
8b587290-febe-4f08-824c-7b18607e9986	c1	Ritebite Choco Delite 40g.	Chocolate	Pcs.
5b4219c0-139f-41f5-874f-2e9ef4727a9a	c1	Ritebite Chocodelite Pack of 3 120g	Chocolate	Pcs.
e11479cd-d42f-4243-bbc0-fb858b7d0dcd	c1	Rite Bite Chocolate Pack of 3	Chocolate	Pcs.
5ddfb2f3-305a-43ec-9af4-e9f9c8609bba	c1	Ritebite Fruity Choco	Chocolate	Pcs.
e969dbb4-7449-4568-b4bc-8b3ca6891ad7	c1	Ritebite Gift Pack 234g.	Chocolate	Pcs.
86117f0c-93ff-4574-b9c3-a90a234e0e8e	c1	RiteBite Krunch 30gm	Chocolate	Pcs.
9b422926-2b41-4d7b-9f4c-73da4051c2ca	c1	Ritebite Max Protein Assorted Pack of 6 424g.	Chocolate	Pcs.
9918630c-2ff2-4f04-b837-8ad0e0ea54c5	c1	Ritebite Max Protein Chocofudge 75g.	Chocolate	Pcs.
7eeeadfb-4bf8-4dd0-93de-e8c708e43ee7	c1	Ritebite Max Protein Chocofudge Pack of 6 450g.	Chocolate	Pcs.
6d5c8b8f-f4a0-4800-bad6-031eaebce2e1	c1	Ritebite Max Protein Chocoslim 67g.	Chocolate	Pcs.
60b3e340-b424-495c-91c8-a34cfcd34bff	c1	Ritebite Maxprotein Choco Slim Pack of 6  402g.	Chocolate	Pcs.
0811de09-393a-43e8-8ced-55cfd76c26cd	c1	Ritebite Max Protein Honey Lemon 70g.	Chocolate	Pcs.
2bd826c6-c47b-4e55-9e24-9755f6b0f8de	c1	Ritebite Max Protein Honey Lemon Packs of 6 420g.	Chocolate	Pcs.
b9855793-a2cf-47a5-b263-164fefcdbe55	c1	Ritebite Merryberry 35g.	Chocolate	Pcs.
1554ac58-6dd6-468d-9934-427ffdc8d3ad	c1	Ritebite Merry Berry Pack of 3 105g.	Chocolate	Pcs.
9130c6f6-c6a3-411c-86e8-325c07865d89	c1	Ritebite S2K 90G.	Chocolate	Pcs.
a15a37e5-95ec-4254-b0cf-e8f3b4e1b4b8	c1	Rite Bite Smart Chocolate	Chocolate	Pcs.
8ccab8a8-cfe2-4c7e-8d88-2faa8ffad2ef	c1	Ritebite Sports Bar 40g.	Chocolate	Pcs.
b19052c7-e872-4082-a46f-276f274a530c	c1	Rite Bite Women Bar	Chocolate	Pcs.
20dadc65-d11f-4a5f-a87e-9734402417d7	c1	Ritebite Workout Gymnassium Bar 50g.	Chocolate	Pcs.
80ff7aff-141a-4ffa-9156-09ca2cd6a4cc	c1	Ritebite Work Out Pack of 3 150g.	Chocolate	Pcs.
12a19910-0840-4636-9da4-588f1282a55c	c1	Ritebite Workout Pack of 6 300g.+1 Sports Bar Free	Chocolate	Pcs.
7783edc6-5266-4612-9178-2735048934a9	c1	Ritz 300g.	Biscuts	Pcs.
8e7c1211-850b-4267-ae5a-0eabf1312814	c1	Ritz Biscuit Crackers 300 Gm	Biscuts	Pcs.
b8ed5a17-7dca-4f5c-8785-d540b481dfc1	c1	Ritz Sand Chees Crakers 118g.	Biscuts	Pcs.
56f045a8-5682-4035-b7c6-ac7da599a0db	c1	Riyorishu Cooking Seasoning (Sake) 1.8 Ltr	Italian Garden	Pcs.
5d7f57bd-f0d8-4db4-86fc-480653c92e40	c1	RIYORISHU (SAKE) COOKING SEASONING (1.8 LTR *6)	Oil	Pcs.
53d24f07-ec83-403a-98c5-af3a24e58c43	c1	RND Coated Sunflower Seeds Wasabi 125 Gm	Namkeen	Pcs.
74f0d32d-c4b5-4cbd-b251-ff24c3bfd87a	c1	RND Flaky Flaxseed Mixture 125 Gm	Namkeen	Pcs.
c7516265-a250-4855-9141-464e923daf9e	c1	RND  High Protein Mixture Plain 150 Gm	Namkeen	Pcs.
85dd9d8e-b933-48d2-9099-efef1d0177ad	c1	Rnd Roasted Chia Seeds Plain 125 Gm	Namkeen	Pcs.
95347b62-9c5e-483f-8466-9d9f03f9804d	c1	RND Roasted Flaxseeds 150gm	Namkeen	Pcs.
d1735a7e-cccf-4f9e-b83e-9bd8d2d63b38	c1	RND Roasted Mixture Lime 125 Gm	Namkeen	Pcs.
f9a5ee04-bd84-4e4d-b963-0a31aa96c69a	c1	RND Roasted Pumpkin Seeds Plain 125 Gm	Namkeen	Pcs.
15653c3f-d4ff-4592-a84a-b5931efcd1a6	c1	RND Roasted Quinoa Puff Jalapeno 60gm	Namkeen	Pcs.
77db459b-6a80-413b-b698-2bdfbbd01fb1	c1	RND Roasted Quinoa Puffs 60 Gm	Namkeen	Pcs.
57690624-0cb2-4ad8-a39f-85074a186a08	c1	RND Roasted Sunflower Seeds 125 Gm	Namkeen	Pcs.
cf06dbb1-42a4-4b95-8afe-2f17acf4cdb9	c1	RND Sprouted Roasted Mixture Plain 125 Gm	Namkeen	Pcs.
deb90388-3f96-4090-81f4-a6c9c7c57617	c1	Roasted Makhana (Peri-Peri)	GURU FOOD	Pcs.
a5345d61-6ed2-4418-b86f-77d6a511fabc	c1	Roasted Makhana (Pudina)	GURU FOOD	Pcs.
61d416c0-ab34-42a5-8f48-492200ae4a31	c1	ROASTED MILLET MIXTURE JAR	GURU FOOD	jar
4e218a5e-67aa-478d-b05b-16fac35c2bf9	c1	Roasted Namkeen Sample 100 Gm	Namkeen	Pcs.
975fca63-c5ec-4c12-85bf-e60a15606555	c1	Roasted Quinoa Finger Jar (Cheese)	GURU FOOD	Pcs.
4c62dc31-f574-4320-a568-5a2aba75bc91	c1	Roasted Quinoa Finger Jar (Peri-Peri)	GURU FOOD	Pcs.
bb6cce90-eba9-4456-84bc-2bbf8b2a2c43	c1	Roaster Makhana (Peri -Peri)	GURU FOOD	Pcs.
c450a15f-963b-494c-88aa-592352461227	c1	Roasty Tasty Bajara Puff Mixture 150gm	Namkeen	Pcs.
f251bfba-6b8d-4806-b9ac-18b6f7af5e5e	c1	Roasty Tasty Chana Jor 150 Gm	Namkeen	Pcs.
4a94ae6f-fe42-4c81-911f-bd6a9bcf070a	c1	Roasty Tasty S Garlic Masala 150 Gm	Namkeen	Pcs.
0c4e0581-ccf5-41fc-bda4-ab93110d7936	c1	Roasty Tasty Tangy Peanuts 150gm	Namkeen	Pcs.
b6909d38-b47a-4140-9284-335f92609b55	c1	Roasty Toasty Jowar Flakesmixture 150gm	Namkeen	Pcs.
f0ed29e2-0cf1-4e31-8f21-13ec9a747355	c1	Roasty Toasty S Chatpta Masala 150 Gm	Namkeen	Pcs.
ac4b1d8a-0fd2-47ad-a86f-b3711e9fff6e	c1	Roasty Toasty Sweet N Sour 150 Gm	Namkeen	Pcs.
03b1109f-8001-4ca2-941e-9e8ce025c491	c1	Rocher T 16	Chocolate	Pcs.
397fefe0-f6ac-4ab3-af60-c6a5f095a6c4	c1	Romero Cous Cous Pasta 500 Gm	Food	Pcs.
18bc913f-5b38-4aa6-b01f-905f40664d94	c1	ROOH AFZA 700 ML	Drinks	Pcs.
c259a8bc-95bc-4a4b-859e-ce793d9950e6	c1	Rortilla Chips Green Chilli 45gms.	Namkeen	Pcs.
dfafef82-44e4-43a9-a1c4-950512302d78	c1	Rosted Bajara Fivestar Mix	Namkeen	Pcs.
8f049281-0363-4da7-b4f1-34f6b6441adb	c1	Rosted Chanajor 200g.	Namkeen	Pcs.
6d7da44a-3942-488e-903b-35d57a8b1fc3	c1	Rosted Five Star 200g.	Namkeen	Pcs.
9aabf14e-933a-46ee-b714-956732316ff2	c1	Rosted Jowar Flakes Mix	Namkeen	Pcs.
c3fd916e-ef58-4f52-99cb-18e55a905f39	c1	Rosted Khata Mitha Mix	Namkeen	Pcs.
a79026a8-78c5-4c82-8323-0b1b0133b99e	c1	Rosted Makhana (Salted)	GURU FOOD	Pcs.
c3ec2e31-4147-4308-afb1-9b3300d20ae8	c1	Rosted Moong Masala 200g.	Namkeen	Pcs.
eafe42ed-5c8c-470e-a667-2b3006f0a532	c1	Rosted Navratan Mix 200g.	Namkeen	Pcs.
0212c362-f141-4db1-a9f2-34b31566f054	c1	Rosted Sadabhar Mix 200g.	Namkeen	Pcs.
4f1dee21-e7f0-4907-8075-aa4aee2fa7ac	c1	Rosted Soya Chatkara	Namkeen	Pcs.
c187f958-4c7f-45c1-98ff-f7e8fb2c62f5	c1	Rostip Chicken Seasoning Powder800gm	Food	Pcs.
95c1e3f0-c137-470a-a6a8-043914940d8d	c1	Rosty Tasty 30/-	Namkeen	Pcs.
dee5a59e-c81a-4206-b105-fcf8fe2d765e	c1	Royal Grove  Button Mushroom Tandoori  800g	ROYAL GROVE	Pcs.
0587ea63-0043-4357-9764-6b9b9ed58e00	c1	Royal Grove Coconut Milk 450gm	ROYAL GROVE	Pcs.
3f71247a-fdf5-4966-9d6a-db068356f52c	c1	Royal Grove Fruit Cocktail 850g	ROYAL GROVE	Pcs.
e329b66b-980f-4b27-99a2-4d2f065c462e	c1	Royal Grove Lime Juice 250 Ml	ROYAL GROVE	Pcs.
d1b08a67-9794-48e2-a959-1e1c839c3c1b	c1	Royal Grove Monosodium Gultamate 500g	ROYAL GROVE	Pcs.
2b96ebd1-bc77-4fe9-9ef3-4d49b20272d5	c1	Royal Grove Pineapple Slice 850g	ROYAL GROVE	Pcs.
43a39dfc-ac17-4f5c-8336-ef7fa0af45bd	c1	Royal Grove Tomato Puree 825g	ROYAL GROVE	Pcs.
d8a62b71-9d47-49d2-b364-dd41277b3fa6	c1	Royal Grove Tooti Fruiti Green 1kg	ROYAL GROVE	Pcs.
1463d107-e12f-4395-9bf5-cdd8dbaf43f7	c1	Royal Grove Tooti Fruiti Red 1kg	ROYAL GROVE	Pcs.
1659c7bd-7858-4151-8b90-729c310c964b	c1	Royal Grove Tooti Fruiti Yellow 1kg	ROYAL GROVE	Pcs.
016860f6-334a-460c-84f9-359a8a9dc1f2	c1	Royalty Sparkling Celebration Drink	Drinks	Pcs.
99da34dd-8b49-45ce-858d-5665cb65239c	c1	Rt.Bajra Puff Mixture 150g.	Namkeen	Pcs.
1edd496b-2d80-4691-9442-0bbf108323b0	c1	Rt.Beej Masoor Mix Masala 150g.	Namkeen	Pcs.
3e20b570-f227-439a-a124-929c25100043	c1	Rt.Chana J 150g.	Namkeen	Pcs.
7830d2be-d06c-4fbd-9fba-c60eeeb0ce1c	c1	Rt.Jower Flakes Mixture 150g.	Namkeen	Pcs.
cbc2b08e-18bd-4f54-a540-11e3f2c14097	c1	Rt.Roasted Papad Garlic 125g.	Namkeen	Pcs.
a63e201c-f691-4427-84d7-02f33f3c12f8	c1	Rt.Roasted Papad Podina 125g.	Namkeen	Pcs.
b8319258-08e0-43ce-a4fd-832c9fd44034	c1	Rt.Roasted Papad Red 125g	Namkeen	Pcs.
0fcdd2b9-2a2a-482e-a5e4-356aa16fa505	c1	Rt.Roasted Papad Tomato 125g.	Namkeen	Pcs.
75d9fcc3-d38a-40c1-88df-e9f4b0cfbabd	c1	Rt.S Chatpata Masala 150g.	Namkeen	Pcs.
81ae03d7-1419-4c0f-b31d-c29417b85bd5	c1	Rt.S Tomato Masala 150g.	Namkeen	Pcs.
a510d8d6-971b-4449-84b6-95ed5af6faf0	c1	Rt.Tasty Tangy Peanuts 150g.	Namkeen	Pcs.
22dbbb11-6412-4a61-8e23-b992e1c9e265	c1	Rvn.Hello Panda Chlt. 50g.	Biscuts	Pcs.
4d99d4eb-eb51-4698-9726-d5af272f8bd6	c1	Rvn.Hello Panda Strwberry	Biscuts	Pcs.
01d0b670-d063-41f6-89f7-3139076bc7a6	c1	Rvn.Jabson Danish Cookies 150g.	Biscuts	Pcs.
4747d2f3-e634-4a48-9860-9b3a73d92387	c1	Rvn.Kruger Lemon Tea 400g.	Food	Pcs.
96bdd417-a71b-4281-af44-8eb2592bad02	c1	Rvn.Lucky Stick Strwberry	Biscuts	Pcs.
d96daa33-b99e-45f1-8796-d07af3ebf227	c1	Rvn.Maralmade Fruit Juice	Biscuts	Pcs.
530ea954-04cb-4061-baf1-63d415bc03a3	c1	Rvn.Maxion Chlt.Bouitique 300g.	Biscuts	Pcs.
8ed1d5ba-4354-44a7-b475-cf7049f85cb9	c1	Rvn.Maxion Chlt.Saphir 300g.	Biscuts	Pcs.
07c7b182-920e-437c-8f2d-492f1f66e23e	c1	Rvn Nobesco Chees Boll	Biscuts	Pcs.
8ba57f8d-a903-4512-a37e-476a798c12b3	c1	Rvn.Nobesco.Chees Curles	Biscuts	Pcs.
ceb6e4d4-f4d3-464b-81d3-ad7d0ee6d725	c1	Rvn.Shigetten Bar Praline 100g.	Biscuts	Pcs.
04340de9-34bb-45bb-a638-971953d2370b	c1	Rvn.Shigetten Milk &amp;H Nut 100g.	Biscuts	Pcs.
56ff5de3-22b7-412b-a7a8-f9cac1a87777	c1	Rvn,Shogetten Dark Chlt.100g.	Biscuts	Pcs.
8ecc0de1-bf6a-47f1-8e4e-3ef5b0a32784	c1	Rvn.Shogetten Jamikrum 100g.	Biscuts	Pcs.
d5f5dc84-fde8-4756-950d-94e73c16a998	c1	Rvn.Trump Dark Chlt.100g.	Biscuts	Pcs.
5b83263b-32b3-4629-bcb3-5ca783e9382f	c1	Rvn.Yun Yun Snacks Chlt.	Biscuts	Pcs.
fb44c134-9efa-4fa7-a638-49a5f302ecab	c1	Rvn.Yun Yun Snacks Stwberry	Biscuts	Pcs.
4f645d98-790a-4b5c-832b-b3a90830fb94	c1	S0F.Strawberry &amp; Rose Jam 430gm	Sugar Free	Pcs.
a334cc2a-49b3-42e2-bb81-f551c504fbdf	c1	S 360 Wafer Stick Chocolate Cream Flv 180gm	Biscuts	Pcs.
618ced79-eebb-4bd2-8f2a-c84357edfd39	c1	S360 Wafer Stick Strawberry	Biscuts	Pcs.
d6e61d37-f5e9-48cd-9ba5-5d3e77acd48d	c1	S 360 Wafer Stick Strawberry Cream Flv 180gm	Biscuts	Pcs.
2d01b729-4622-445e-b7eb-7f1981997cfe	c1	S360 Wafer Stic Pandan Mrp 245	Biscuts	Pcs.
7d55cf85-8d0a-4170-9ebc-76e96e2bbec6	c1	Saesme Seeds	Food	Pcs.
89683162-a526-4bf5-bd7e-dface0ba653f	c1	Safa 400 Gm	Food	Pcs.
af0ae3d8-81ed-4b2b-947a-76a8a6432fe8	c1	Safa Mara Chic Pea, Kidn Pell Tomato	Food	Pcs.
3bdaeb73-52c4-419c-b4d3-08cb703d9833	c1	SAKURA COOKING SEASONING 1.8Ltr	Oil	Pcs.
fc56c973-dc98-43d7-96ad-fc8641a7d6be	c1	Sakura Edamame Without Pod 500gm	Food	Pcs.
6e4dad8f-104a-4435-b814-9f312eb6e46f	c1	Sakura Hon Mirin Seasoning 500 Ml (12%)	Food	Pcs.
5453528d-6da7-4fd1-a7b4-0dd8107a738f	c1	Sakura Noori Sheet 28 Gm	Food	Pcs.
77496cbc-4000-468e-accf-518061b0b63b	c1	Sakura Sake Cooking Seasoning 500 Ml	Food	Pcs.
fd0eee6c-4ba4-4c82-8573-919e8585ae85	c1	Sakura Sushi Rice 1kg	Food	Pcs.
0244b662-2d20-46ca-bc44-1eb53b6cafc2	c1	Sakura Sushi Vinegar 500 Ml (18%)	Food	Pcs.
71706bf7-6c4b-4d6c-8e01-90e4e8592c76	c1	Salmon Smoked -1kg	Food	kg.
d23907b9-0203-4ab2-8109-abf64ec53dd2	c1	Salsalito Nachos Jalapeno 200 Gm Mrp.120	Food	Pcs.
60523844-0045-4c1a-b31e-823f91dc395b	c1	Salsalito Taco Sheels 150gms. Mrp.180	Food	Pcs.
068d888d-a053-4a06-98e9-a92fb6cea91d	c1	Salsalito Tortilla Chips Salted-180gm.	Namkeen	Pcs.
d2505b75-5492-4ecf-a0e6-cd124300480f	c1	Salsalito Tortilla Wrap 348gms Mrp.195	Food	Pcs.
263f2c92-72a5-4786-9810-85e6e0f7c9dc	c1	SALSALITO WRAP MULTI GRAIN	Food	Pcs.
19f2681b-9bd2-4bcd-8d46-0f66f3410aea	c1	Salsa Nachos Chips Zesty Jalapeno 150gm	Namkeen	Pcs.
92aae1b5-00ec-4ed7-b7a2-34747c4d45ce	c1	SALSA Nachos Creamy Cheese 150 Gm	Food	Pcs.
b279278d-4797-4565-b5e2-49981fe2452f	c1	Salsa Nachos Mexican Chilli 150 Gm	Food	Pcs.
9e750db9-970c-412f-a403-6cabae899917	c1	Salsa Taco Seasoning Mix Mrp.120	Food	Pcs.
52b43035-d8fa-42ac-80e4-02abc649dbea	c1	Salsa Taco Shell-Mini 80gm	Namkeen	Pcs.
cc666640-5d4b-48f2-a7fc-4135d08ddd9b	c1	Salt Nature Smith Sachet	Food	Pcs.
55ca32df-29d6-4feb-8b5d-c27dadaa4bfb	c1	SAMBAL OELEK 245GM FLYING GOOSE	Food	btl.
009f1226-3986-4731-852b-cd49c7ea1f98	c1	Samosa Patti 250 Gm	Food	Pcs.
838c6b79-0e18-45d2-9341-52b9b26efa74	c1	Sample Ll Diaper Pants Extra Large 1&apos;s Mrp.15	BABY PRODUCTS	Pcs.
eef6c412-832d-434c-8e7c-c4524cbb1f21	c1	Sample Sachet Of Khajoori Guda	Food	Pcs.
07499656-c911-4eef-b425-ed4ee25da1f6	c1	Samples Ll Diaper Pants Large 1&apos;s Mrp.12	BABY PRODUCTS	Pcs.
0392b8ae-f068-4c55-997f-47e6b63fb76d	c1	Samples Ll Diaper Pants Medium 1&apos;s Mrp.12	BABY PRODUCTS	Pcs.
2e4ae05c-fcc8-49bf-ad06-f38fb33bfc55	c1	Samples Ll Diaper Pants New Born 1&apos;s Mrp.12	BABY PRODUCTS	Pcs.
92740d17-6fb6-46f4-9ff9-ce212c13b10a	c1	Samples Ll Diaper Pants Small 1&apos;s Mrp.12	BABY PRODUCTS	Pcs.
cc501e99-96ae-431a-92c9-a953504f4cb9	c1	Samudra Corn Crackers Biscuit 300 Gm	Biscuts	Pcs.
3aaa0cfd-760b-4fd9-a572-27551f583078	c1	Samudra Cream Biscuit Chees 190gm.	Biscuts	Pcs.
105e7f0e-88e5-4796-87dc-953748abe190	c1	Samudra Cream Biscuit Chocolate 190gm.	Biscuts	Pcs.
d23261db-15ed-4864-8e2d-ffdf2c58a6d3	c1	Samudra Cream Biscuit Lemon 190gm.	Biscuts	Pcs.
f67d874e-fe12-4e4e-b831-9bbb3f8f32f2	c1	Samudra Cream Crackers Biscuit 300gm	Biscuts	Pcs.
aa5903cb-c766-442f-a13b-2de2375e43a6	c1	Samudra Cream Crackers Buiscuits 100 Gm	Biscuts	Pcs.
6e35efb2-c72c-4a7a-809f-98c5a4728c76	c1	Samudra Mini Chocolate Moist 85 Gm	Chocolate	Pcs.
ec86cc80-4318-41e8-9f05-415149fccd53	c1	Samudra Sugar Crackers Biscuit 300gm	Biscuts	Pcs.
d0df049d-727e-4df5-8626-83829080f64c	c1	Samudra Vegetable Crackers 200gm	Biscuts	Pcs.
156d703a-11aa-43a6-a0f9-6469ea0cea22	c1	Samyang Noodle 3x Spicy 140g	Food	Pcs.
b735b54b-e9f4-473d-8136-6710e0877985	c1	Sandisk PD 16 GB	Electrical Goods	Pcs.
5ca3474e-f8be-4ad5-bd5f-68063602e453	c1	Sanitizer  5 LITRE	Cosmatics	Pcs.
2a0fb893-fbfb-4963-b861-9fec6e9e88dd	c1	Sanvito Cannelloni 250g	Food	Pcs.
30597ed9-c3d0-4d9a-9371-1c281261c2f1	c1	San Vito Cannelloni 250 Gm	Food	Pcs.
ef6517d5-c999-4b6e-ae94-dd18b6a39e81	c1	Sanvito Chifferi Rigati 500 Gm	Food	Pcs.
67481d97-9bf0-4093-881f-64f38a2fc537	c1	SAN VITO FARFALLE 500gm	Food	Pcs.
94d6ef8b-3ae9-4f30-8b31-2ba7d5afb77e	c1	Sanvito Fettuccine 500 Gm (IMP)	Food	Pcs.
d23ddee1-af3f-48cb-a5e8-acf5ad97e1a5	c1	SAN VITO FUSILLI 500G	Food	Pcs.
2c663ed5-d56d-4dbd-a4e0-5ac8bef6eeb3	c1	Sanvito Lasagne 500gm.	Food	Pcs.
21d1880f-be24-4f78-a514-e338941bb412	c1	SAN VITO PENNE 500G	Food	Pcs.
d376dfa9-742f-455b-bfb4-588e827c6952	c1	Sanvito Spaghetti 500 Gm	Food	Pcs.
e47da6b1-13d5-4fd6-b6ad-1c1ed048193e	c1	Sanvito Tricolour Fussili 500gm	Food	Pcs.
ec29c3a8-42b0-4059-b5e8-69a94fe15300	c1	Sanvito Tricolour Penne 500 Gm	Food	Pcs.
3d156da6-db6e-489d-8fff-389164220ad7	c1	Sanvito W W Panne Rigate 500g.	Food	Pcs.
d9d07d31-8b36-4293-9ba4-fc7578eaeb97	c1	Sapphire Coated Nuts 200 Gm	Food	Pcs.
cb6547a3-9d05-4953-b61a-3b91181745f3	c1	Sapphire Magic Roll 200gm	Food	Pcs.
5312c0d0-11ef-450d-aab6-d4e7c4fe4c48	c1	Satmola Aloo Bhujia Rs.5/-	Namkeen	Pcs. of 480 CAR
614d6b97-10f9-41dc-b7f5-17cd065518bd	c1	Satmola Bhujia Rs.5/-	Namkeen	Pcs. of 480 CAR
edf28412-2563-437c-9a09-dd089e04a28f	c1	Satmola Chana Dal Rs.5/-	Namkeen	Pcs. of 480 CAR
68e344f3-736e-470e-8746-3f7e16ac4a6a	c1	Satmola Chilli Pataka Rs.5/-	Namkeen	Pcs. of 480 CAR
8a1deaa2-b6f9-46d6-ad5a-182c01f4eafa	c1	Satmola Chilli Peanut Rs.5/-	Namkeen	Pcs. of 480 CAR
853e0297-4833-4841-9b91-7677f8cc2609	c1	Satmola Hing Jeera Rs.5/-	Namkeen	Pcs. of 480 CAR
1a603d4c-7c04-473c-a268-0bf5b866a3fc	c1	Satmola Kadai Paneer Bhujia Rs.5/-	Namkeen	Pcs. of 480 CAR
e092a9ec-7148-422c-870b-2bc74ca85f97	c1	Satmola Khatta Meetha Rs.5/-	Namkeen	Pcs. of 480 CAR
c7ef1b53-6878-4175-9638-134336f14a0e	c1	Satmola Matar Chatpati Rs.5/-	Namkeen	Pcs.
f974ff28-719d-4986-90b4-c512cfe397c5	c1	Satmola Mix Namkeen Rs.25/-	Namkeen	Pcs. of 60 CAR
fbb0027b-5794-4db2-92a8-e030667f9400	c1	Satmola Moong Dal Mix Rs.5/-	Namkeen	Pcs. of 480 CAR
8895956f-2db1-4a8d-bc9f-5d270d106d51	c1	Satmola Moong Dal Rs.5/-	Namkeen	Pcs. of 480 CAR
984fdf47-cf01-4c32-add9-60b46fa0b3ae	c1	Satmola Navratan Mix Rs.5/-	Namkeen	Pcs. of 480 CAR
0a879e13-94b0-4882-b980-89fbf0002cb7	c1	Satmola Paneer Bhujia Rs.25/-	Namkeen	Pcs. of 60 CAR
c7c7b1fc-6dc1-477b-980a-c27951533bbb	c1	Satmola Paneer Bhujia Rs.5/-	Namkeen	Pcs. of 480 CAR
70288657-a528-4966-95d7-2b1b4b185671	c1	Satmola Peanut Rs.5/-	Namkeen	Pcs. of 480 CAR
6f9f61ff-9e4c-4a08-b2a6-7b04aabc6e3a	c1	Satmola Tasty Nuts Rs.5/-	Namkeen	Pcs. of 480 CAR
5b3ff1a9-1a7f-4aed-b23e-8de58ccbaf63	c1	Sauce Green Chily 750 Gm	Food	Pcs.
ef2da8b8-4c54-4204-b0eb-2e130d9d9b2a	c1	Sauce Mix	Food	Pcs.
26915cfe-372b-41bb-9c67-74791d19358e	c1	SAUCES	Food	Pcs.
0e1b6334-b8c9-4e9b-acae-90105c613aba	c1	Saudi Wet Dates Mabroom 400g	Food	Pcs.
40752823-e468-48ca-a1ea-c1627c0a862f	c1	Saudi Wet Dates Prm Safawi 400g	Food	Pcs.
a49e7e1f-a1b5-4bfc-b5cb-42a663caa865	c1	Savoiardi Lady Finger Biscuit 400g.	Food	Pcs.
eaa7ab3b-758d-459f-93e9-662b559e6046	c1	Savoury Cheese Waffle Mix	Food	Pcs.
4d21dca7-ead7-4d04-a618-4850750b1c0e	c1	S &amp; B Assorted Chilli Pepper (Togarashi) 300gm	Food	Pcs.
cb045f9a-781a-4f83-b667-8e9546d4ed7a	c1	S &amp; B Golden Curry Hot Sauce Mix 220gm	Food	Pcs.
e5693d7e-7989-4029-92f8-ccbdb6597f2c	c1	Sb Golden Waffle Mix Veg	Food	Pcs.
57ed1f42-4115-4db3-b652-9a3c8167d6a7	c1	S &amp; B Mustard Powder-400gm	Food	Pcs.
1c5a6475-78db-40a0-b6e0-6f43b5debbc8	c1	SB PROBAKE PLUS IMPROVER	Food	Pcs.
d0abe0e4-d0f5-4ec6-b110-1ee4bb86345b	c1	Schoko Brwonie Mix Veg	Food	Pcs.
bce472d0-4630-4a43-bb4c-5368607b9376	c1	Schreiber Natural Cheddar Cheese 1kg	Dairy Products	Pcs.
d2716564-2553-4f55-b111-90da7e148c29	c1	Schweppes Bitter Lemon 300 Ml	Drinks	Pcs.
c82a08b9-5f76-471a-9766-1934a6d84c42	c1	Schweppes Carbonated Beverage 320ml	Drinks	Pcs.
dda8cb66-ad7a-411a-bd5c-b1e1f44e9370	c1	Schweppes Coca Cola Can 330 ML	Drinks	Pcs.
777f902b-0836-4b3c-9492-9b15bdfd0db9	c1	SCHWEPPES DRINK	Drinks	case
8da8e6e2-8280-4419-a148-d3ac0d48cd0e	c1	Schweppes Ginger Ale 300 Ml	Drinks	Pcs.
f9c9316f-851f-45dc-bc7a-415b989e0d7b	c1	Schweppes Ginger Ale 300ml Can 1*24	Drinks	Pcs.
f2a4bd85-906d-42f9-8928-f3d35a521d4d	c1	Schweppes Ginger Ale No Suger	Drinks	Pcs.
fbe8d191-a2df-4536-bf1a-85be5fcc3e8c	c1	Schweppes Mint Mojito 300 Ml	Drinks	Pcs.
dea78b55-af1a-4ce0-966b-ae5463ae2796	c1	Schweppes Soda Water 300 Ml	Drinks	Pcs.
bd652cc9-d568-4c83-9092-a6f466984254	c1	Schweppes Soda Water 5%	Drinks	Pcs.
df54a7f7-8c3d-43a9-83d5-91fcc611c2ae	c1	Schweppes Soda Water Can	Drinks	CAN
652a9eda-720e-41a3-8110-2a3a1bfebeb8	c1	Schweppes Soft Drink 320 Ml	Drinks	Pcs.
0118869e-3f9a-4238-be52-bf503aaa7880	c1	Schweppes Sprite Can 330 ML	Drinks	Pcs.
c9c1d509-d802-423b-b3f1-f0ef71fc21be	c1	Schweppes Thumps Can 330 Ml	Drinks	Pcs.
e197b543-40b3-4612-b228-bb9c0ed8ab14	c1	Schweppes Tonic Water 300 Ml	Drinks	Pcs.
18392b3d-98cc-499e-b086-fe981651f888	c1	SCHWEPPES TONIC WATER 300 ML CAN	Drinks	CAN
311c6d01-a08b-4498-9400-94dd80467e09	c1	Schweppes Tonic Water No Sugar	Drinks	Pcs.
7281f201-e99d-4934-a7b2-b2aff4554a5d	c1	Schweppes Tonic Water Without Sugar 18%	Drinks	Pcs.
d8a24903-6c94-4bce-bc5d-915b793191c2	c1	SCHWEPS TONIC WATER IMP	Drinks	Pcs.
1596c1e0-2cb5-4b94-8f9e-86ea89fdfdf2	c1	Scotti Arborio Rice 1 Kg	Food	Pcs.
0e8e03ee-448d-4601-bf95-66a378bb7a7b	c1	Scotti Hakumaki Sushi Rice 1kg	Food	kg.
94d1daa7-0405-41a2-bb27-fb0de3b7ea32	c1	SEA SALT  750GM COSTA	Food	Pcs.
dcd8e179-8e2c-4d8a-b776-19aef0c3dbac	c1	SEASME CHIPS JAR	Namkeen	Pcs.
6ae8362a-6efa-4d33-ba40-d29cce90a8ca	c1	Seasme Oil 630 Ml	Food	Pcs.
6fee9f94-cba4-46d8-b044-7d5684c6dda2	c1	Seasme Oil Blended 630 Ml	Food	Pcs.
7f3857fb-9c98-45bd-af9d-4cbd114ddd47	c1	SEASME OIL /JIANHUA(BLENDEN)	Oil	Pcs.
7e560dfd-747b-486c-b424-042f82173be0	c1	SEASONING SAUCE 200ML	Food	Pcs.
027f2b06-84b5-4e1a-8647-690c4933b285	c1	Seasons Greetings (Lotte)	Drinks	Pcs.
f4a5c9cf-676e-491a-a3e0-7a44f4e8fd34	c1	Sea Vegitable 500g	Food	Pcs.
31ee23dd-888a-4f95-9588-a0184c029eef	c1	Sea Wed Noori Sheets	Food	Pcs.
cd73f482-98a0-41d9-86b0-06dfb18b8261	c1	SEA WEED SHEET	Food	Pcs.
b1416801-4a5e-4305-a20f-cf45c7296f08	c1	Seaweed Sheet (Yaki Nori) 50SHEETS	Food	Pcs.
7c72e95f-7b7e-4d68-aa26-c128094e5362	c1	Seeda Mix Patti 300g	GURU FOOD	Pcs.
87cc6e19-df9b-44ee-a06f-527a1db26818	c1	SEED MIX PATTI 300g	Food	Pcs.
ee1376ee-006a-4961-ab58-a7ed1ba5b7bb	c1	Seeds Mix Patti	GURU FOOD	Pcs.
73246646-ceff-4a17-991d-6a44a0f87be0	c1	Select Brie 125gms	Dairy Products	Pcs.
30921816-00a8-452b-ae55-9e5d84776c50	c1	Select Camembert 125gm	Dairy Products	Pcs.
137630fa-2271-4400-b27c-1a75cbc1317a	c1	SEMOLA RIMACINATA 5KG	Food	kg.
e6e70423-e6f0-4716-9e76-2348c3e239fb	c1	Sepoy Classic Lemonade Tonic Water 200ml	SEPOY DRINK	Pcs.
8902a4a9-ed96-494c-ac4e-aefb48cf0a22	c1	Sepoy Cucumber Tonic Water 200ml	SEPOY DRINK	Pcs.
8732c79d-4ae2-4121-8d64-b1df9ba89253	c1	Sepoy Elder Flower Tonic Water 200ml	SEPOY DRINK	Pcs.
728c7a50-94ad-4bc5-8425-c6da9335b9b8	c1	Sepoy Hibiscus Tonic Water 200ml	SEPOY DRINK	Pcs.
d21ceefc-65a4-4053-957d-5b7546495dc4	c1	Sepoy Indian Tonic Water	SEPOY DRINK	Pcs.
4196ee48-e006-49d6-bdad-6e7a69ce4fea	c1	Sepoy Mint Tonic Water 200ml	SEPOY DRINK	Pcs.
577f1539-6146-44c0-9689-6c1b27932a8b	c1	Sepoy Mixed Berry Lemonade 200ml	SEPOY DRINK	Pcs.
3e55cef4-5fa0-473c-a197-ce4a5f2ea074	c1	Sepoy Original Ginger Ale 200ml	SEPOY DRINK	Pcs.
f961ad22-9d90-4746-8e41-2c9a0ad83fcc	c1	Sepoy Peach Lemonade Tonic Water 200ml	SEPOY DRINK	Pcs.
fcf73803-fa83-4e16-97c6-3ce80893e6eb	c1	Sepoy Pink Grapefruit Soda 200ml	SEPOY DRINK	Pcs.
034dd11f-3eb7-40bc-8660-35efb263bb46	c1	Sepoy Pink Rose Lemonade 200ml	SEPOY DRINK	Pcs.
db4f1469-5e1c-4813-9656-a717dfcb2c6f	c1	Sepoy Premium Ginger Beer 200ml	SEPOY DRINK	Pcs.
db63407b-513c-47cd-a65a-124d48584f7e	c1	Sepoy Premium Soda Water 200ml	SEPOY DRINK	Pcs.
4ffd9530-012e-4558-ad51-027dbf71dca2	c1	Sepoy Pure Sparkling Mineral Water 200ml	SEPOY DRINK	Pcs.
b0ce4a9c-d74d-4649-9f7f-80dd2782e296	c1	Sepoy Spiced Grape Fruit Tonic Water 200ml	SEPOY DRINK	Pcs.
7d695451-0ef7-40c6-a941-bc1b05eec67c	c1	Sepoy Tropical Lemonade Tonic Water 200ml	SEPOY DRINK	Pcs.
9233db5d-6946-4114-83c7-f4671ea39e40	c1	Sesame Oil 207ml.L.K.K	Oil	Pcs.
c440f235-ac67-4892-bafc-cd3c86375597	c1	SESAME-OLI 630ML.	Oil	Pcs.
b79d7748-8d21-4697-a11e-277f3b9c6ac9	c1	SESAME SEED OIL 500ML.YOKA BRAND TOASTED	Oil	Pcs.
9eec505a-457d-43af-be00-39c98efae4f0	c1	SEWAI 900GM H	Food	Pcs.
4903aded-7402-4f07-ac3f-f8f1c1e2586a	c1	S.F.Almond Rock Chlt.100g.	Sugar Free	Pcs.
e7c11408-a09f-45a1-917a-4ec1a54c2823	c1	S.F.Classic Chlt.100g.	Sugar Free	Pcs.
50c2de34-70cc-4855-8a0b-c792128ad7af	c1	S.F.Cokies 132g.Blalck Currnt Rs.91/-	Sugar Free	Pcs.
54b4a713-734f-4b6a-a3df-98551630e07c	c1	S.F.Cokies 132g.Fig Rs.91/-	Sugar Free	Pcs.
a4833249-64a0-43ef-a1c5-12c038aa3034	c1	S.F.Cokies 132g Gngr.Cinnaman Rs.91/-	Sugar Free	Pcs.
39617c99-34f7-468e-9ad8-4b439c695838	c1	S.F.Cokies 132g.Vanilla Butter Rs.91/-	Sugar Free	Pcs.
b0b6f7de-424b-43fb-810c-e493e02ff56b	c1	S.F.Cookies 133g	Sugar Free	Pcs.
7b79e6b1-909b-4462-a5ec-b7ccd8acc2b9	c1	S.F.Cookies 13Grains &amp; Seeds 200g.Rs.175/-	Sugar Free	Pcs.
8f5220ee-eb58-43cf-9e6c-0be8ef59b0c5	c1	S.F.Cookies 200g.	Biscuts	Pcs.
71bba9d1-50cb-4cff-8645-f13fa7b64710	c1	S.F.Cookies 65g.	Biscuts	Pcs.
fea7bc06-117a-486f-b7b9-70513c9bdf04	c1	S.F. Cookies Black Current 100g	Sugar Free	Pcs.
32673a7f-da8c-46ae-bd78-bc36b0c9261c	c1	S.F.Cookies Black Currunt 200g.	Sugar Free	Pcs.
a4a22d98-e419-48d3-90bb-54c88e8e1545	c1	S.F.Cookies Blk.Crrunt 65g.	Sugar Free	Pcs.
5229790f-fec1-4e7a-bbbd-7c6a3e29a406	c1	S.F.Cookies Chocolate 100gms.	Sugar Free	Pcs.
5d6e3a28-6069-46d7-b3a6-537e4a33d627	c1	S.F Cookies Fig 100g	Biscuts	Pcs.
45304983-ee36-4fbf-9a51-319bd97439b1	c1	S.F.Cookies Fig 100gms.	Sugar Free	Pcs.
274a4c83-11a7-45b4-adc8-8a4db33b3cbe	c1	S.F.Cookies Fig 200g.	Sugar Free	Pcs.
43a47091-da9c-4b65-b398-defe54bf0830	c1	S.F.Cookies Fig 65g.	Sugar Free	Pcs.
5e142647-a159-4c12-96f3-c46cd15b4124	c1	S.F.Cookies Ginger 100gms.	Sugar Free	Pcs.
01c05be3-5521-4f19-bf78-c346d776fc23	c1	S.F.Cookies Gngr.Cinamon 65g.	Sugar Free	Pcs.
36f285da-5972-4dc6-a361-ffc6846b0f7f	c1	S.F.Cookies Gngr. Cinnamam 100gm	Food	Pcs.
70dfc5c6-1e72-4d51-9452-52460374f9be	c1	S.F.Cookies Gngr.Cinnamam 200g.	Sugar Free	Pcs.
d7442415-1a0c-4282-870a-a7480b26553a	c1	S.F.Cookies Peanut Crunchy Butter 100g.	Sugar Free	Pcs.
aaabd251-984a-4d03-94b7-b2872ed78270	c1	S.F.Cookies Peanut Crunchy Butter 200g.	Sugar Free	Pcs.
2ae23671-9f03-4353-b530-1170d98b704c	c1	S.F.Cookies Vanila 100gms.	Sugar Free	Pcs.
6f89a8a9-5c40-425f-b3f3-d3d4b3c6b55f	c1	S.F.Cookies Vanila Butter200g.	Sugar Free	Pcs.
c8fccc7d-62d2-41a3-ae4c-756ab56694a8	c1	S.F.Cookies Vanila Butter 65g.	Sugar Free	Pcs.
d8b01342-c4fe-45ac-beab-a2356a6ab849	c1	S.F Crunchy Peanut Butter Cookies 100g	Sugar Free	Pcs.
e47e0094-f59a-4458-b31c-a52e8ddb128f	c1	S.F. Crunchy Peanut Butter Cookies 200g	Biscuts	Pcs.
3f09f588-bd4c-4fcb-8293-b3a2df1bc488	c1	S.F.Cup Cake  Banana &amp; Walnut 160g.	Sugar Free	Pcs.
8aebddf9-8d10-4194-a771-a60fc8a748f0	c1	S.F.Cup Cake Banana&amp;Walnut 80g.	Sugar Free	Pcs.
d68db479-f083-49a1-b98c-b98ec8018a12	c1	S.F.Cup Cake Chocolate 160g.	Sugar Free	Pcs.
df73a9a3-846c-437d-92a2-02f9bfa7d94e	c1	S.F.Cup Cake Chocolate 80g.	Sugar Free	Pcs.
8288dd6d-7e4c-4acb-a5d0-4c9383c10d2b	c1	S.F.Cup Cake Date &amp; Walnut 160g.	Sugar Free	Pcs.
08a58726-975d-419f-88cf-5a86ff57b6b6	c1	S.F.Cup Cake Date&amp;Walnut 80g.	Sugar Free	Pcs.
5eef2961-fa3c-4dd3-9287-ae4e62215ce4	c1	S.F.Cup Cake Vanila 160g.	Sugar Free	Pcs.
a275e183-e4a9-4bdc-a813-05f55f71cebb	c1	S.F.Cup Cake Vanila 80g.	Sugar Free	Pcs.
6e29afca-c46c-47ad-8c6c-30d383612161	c1	S.F.Fig &amp; Saffron Jam 300g.Rs.210/-	Sugar Free	Pcs.
e4fd15f0-cdc0-4387-9e0b-85c560168a37	c1	S.F.Ginger Honey 200g.	Biscuts	Pcs.
4cdcbfba-4b75-485a-b9cb-def5f8b60e26	c1	S.F.Gulabjamun 250gms.	Biscuts	Pcs.
b84a64de-9caa-4628-a3a2-6e5decf765fc	c1	S.F.Gulab Jamun 500g.	Sugar Free	Pcs.
81dffad4-8348-4426-b3a4-d2453ba0566b	c1	S.F.Hazelnut Chlt.100g.	Sugar Free	Pcs.
48a2df7f-d9b5-446b-8b0b-2c8a57b0d6e2	c1	S.F.Kala Jamun 300g.Rs.250/-	Biscuts	Pcs.
353d4cea-95cc-48e6-935f-2fb68fd050e2	c1	S.F. Lychee Sharbat 300gm	Biscuts	btl.
f8fe3be3-4345-4721-9640-1ae1ad98d791	c1	S.F.Mint Chlt.100g.	Sugar Free	Pcs.
3494d474-92c8-480a-b935-7aa030ae2fae	c1	S.F.Mixed Fruit Jam 300g.Rs.210/-	Biscuts	Pcs.
faff2426-b05f-43cd-9345-1acf89abd0b4	c1	S.F. Mix Fruit Jam 300 Gm	Food	Pcs.
3f48ee9f-0281-43ee-a3cd-4d1d317b4545	c1	S.F.Natural Honey 200g.	Biscuts	Pcs.
0cfd9c02-df74-411c-972c-bd050f18f87f	c1	S.F.Oat Kiwi&amp;Len.Cookis 150g.	Biscuts	Pcs.
2d291100-e5bd-4a97-9301-1052e1362215	c1	S.F.Oatmeal Kiwi &amp; Lemon 200g.Rs.245/-	Biscuts	Pcs.
6d509557-d342-4eda-a378-df7b41bd1c53	c1	S.F.Oatmeal Rasberry 200g.Rs.245/-	Biscuts	Pcs.
7b980ea8-46a7-4c85-96ff-2632e0e31ac6	c1	S.F.Oatmeal Sour Cherry 200g.Rs.245/-	Biscuts	Pcs.
0bdbe36a-a4d2-4c66-91f8-4cb6bf9442c2	c1	S.F.Oatmeal Strawberry 200g.Rs.245/-	Biscuts	Pcs.
56e24249-cdb6-42db-b2c7-3ea753bea451	c1	S.F.Oat Rasbery Crm,Cookis 150g.	Biscuts	Pcs.
96e27120-c62e-48f7-a907-c209597b66c2	c1	S.F.Oat Sour&amp;Cherry Crm.Cookis 150g.	Sugar Free	Pcs.
0c8d3575-194b-4e3c-ac88-b330d809a531	c1	S.F.Oat Strwberry Crm. Cookis 150g.	Sugar Free	Pcs.
28dabdd4-f9b6-406c-81e9-064f1d955910	c1	S.F.Orange Marmalade Jam 300g.	Sugar Free	Pcs.
de88c335-b893-4fe3-adef-1c0e9edb2019	c1	S.F. Orange Sharbat 300gms.	Sugar Free	btl.
f9b67021-2fd2-4bae-b0f7-9e29a13d208c	c1	S.F.Orenge Chlt. 100g.	Sugar Free	Pcs.
54459837-e9e8-423e-812d-8050bb15cd33	c1	S.F.Pineapple Jam 300g. Rs.210/-	Sugar Free	Pcs.
d4788d77-fbe3-4c31-ade0-fdd859b5981d	c1	S.F.Raso Gulla 250g.	Sugar Free	Pcs.
26bd89de-fcb6-4b94-a78f-2e47904a71ff	c1	S.F.Rasogulla 500g	Biscuts	Pcs.
27453ac3-4f03-49a5-b7c7-33e78517f18e	c1	S.F. Raspberry Sharbat 300gm	Sugar Free	btl.
0079b783-fa84-4ddb-abf7-50f98f587d55	c1	S.F.Rose Sharbat 300gms	Sugar Free	btl.
c73e0c60-da68-4b77-a88d-083863075960	c1	S.F.Saffron Honey 200g.	Biscuts	Pcs.
58f7578b-f1d1-4440-b122-9cc989458e15	c1	S.F.Sultana &amp; Hazelnut Chlt.	Sugar Free	Pcs.
61003cf0-d09e-4c31-80b6-964977fe331e	c1	Shan Seekh Kabab BBQ Mix 60gms	Spices	Pcs.
65470fa8-0d71-47a5-9150-0fdb50d4ef37	c1	Shan Spice Mix for Chicken Masala 50gms	Spices	Pcs.
7c3a3755-4107-419e-8418-700eb0f88c2c	c1	Shan Spice Mix for Chicken Tikka BBQ 50gms	Spices	Pcs.
7a95b6c0-3349-47cf-b60a-206ea077d86c	c1	Shan Spice Mix for Korma 50gms	Spices	Pcs.
baa89745-667d-4eca-af7e-596eac06a1cb	c1	Shan Zafrani Garam Masala 50gms	Spices	Pcs.
660a0bbd-38ea-404f-888a-5843b6db7f3a	c1	Shi Pap Wrap (21 Mtr Roll)	Food	Pcs.
323f4569-00d9-4572-8694-76d26288de02	c1	Ship Madras Curry Powder 500gm	Spices	Pcs.
0df09af4-b30c-42a8-9d76-e22dbc809f88	c1	Shitake Mushroom 3 Kg	Food	Pcs.
4ceb0d78-720b-4219-9f3d-064fa4be89ed	c1	SHITAKE MUSHROOM 500 Gm (12 %)	Food	Pcs.
7c240105-485d-4a05-9eb8-f30538d9d6b7	c1	Shitake Mushroom Fungus Nostimo 1 Kg.	Food	Pcs.
5ea53ce1-3996-4b14-89e1-30e992f103ee	c1	Shitake Mushroom in Kg	Food	kg.
b8bffccb-b56b-4e87-9321-70c6f02615dd	c1	Shrimp Paste (TRACHANG)	Food	Pcs.
30db1e72-534a-4231-ba8f-1688a7083bae	c1	Shuddhi Cow Ghee Jar 100ml	Ghee	Pcs.
919d4317-d1c2-4b5b-b92c-339b85a421b4	c1	Shuddhi Cow Ghee Jar 500ml	Ghee	Pcs.
35bd2cd2-78c9-4a26-93a0-9e83e5b0a31c	c1	Siliken Soymilk Tofu Extra Firm 349 Gm	Food	Pcs.
81d2e9cc-61bb-4708-b5a9-6eec72b2b626	c1	Silk Almond Asep Unswweetned (18%)	Dairy Products	Pcs.
d38b0d02-df0e-4783-ada8-b3964e2e9e86	c1	Silk Asep Oat 0g Sug 18%	Dairy Products	Pcs.
5227a247-3d4b-4dbc-905b-aed1f8fe6c46	c1	Silken Soymilk Tofu 349 Gm (18%)	Food	Pcs.
7618e626-0278-4ab5-848a-e9b92dd3711f	c1	Silk Org Soy Asep Vanilla (12%)	Dairy Products	Pcs.
db19d1b6-9999-470a-aa82-d5de5b921a21	c1	Silver Skin Onions in Vinegar (12%)	Food	Pcs.
b2132398-a9d5-418b-bff4-487b14687040	c1	Skippy P.B. Creamy 340g.	Food	Pcs.
6a31dfe2-dca8-44a2-bcb0-e9622826f6c3	c1	Skippy P.B. Crunchy 462g.	Food	Pcs.
e28c7e74-b4ca-45b1-8610-a235fb0d176d	c1	Skippy Peanut Butter	Food	Pcs.
9969c6eb-e9e3-436c-a372-b5c1fc76ccae	c1	Sliced Black Olives 1.560 Kg	Food	Pcs.
826b57ad-33c3-447e-a809-8b8a24f6567b	c1	Sliced Jalapeno in Cans (A-10)	Food	Pcs.
a94c0328-d848-4b21-b757-d33b178d7bb6	c1	SMIKI BLACK BEAN SAUCE 330 GM	Food	Pcs.
57ef0069-0da7-4cc3-a5e4-4c77a1b2f430	c1	Smiki Rice Vinegar620ml	Food	Pcs.
a8c4b55f-999d-4b1e-a7a2-9cbcb09e451e	c1	Smiki Seasme Oil 610ml	Food	Pcs.
71e89cc8-d0f3-4122-86ee-f0596fd6a23a	c1	Smoked Chesse	Dairy Products	Pcs.
e4fe530f-f9db-4a4d-8521-5f501e5cea97	c1	SMOKED NATURAL(WZ)-200GM	Dairy Products	Pcs.
198db5f5-9476-49db-8943-c72b625008c9	c1	Snackar Almond Salt &amp; Pepper Rs.230/-	Namkeen	Pcs.
18f5ebc5-df78-433d-9276-1f3476e82049	c1	Snackar Cashew Roasted &amp; Salted Rs.165/-	Namkeen	Pcs.
4b838e40-ebd3-4146-b394-f9c88cc71d61	c1	Snackar Cashew Salt &amp; Pepper Rs.170/-	Namkeen	Pcs.
c2d42c8c-3b4a-4f01-beb0-497ebb111147	c1	Snackar Chana Lime &amp; Chilly Rs.5/-	Namkeen	Pcs.
e19ca525-b236-4ccd-aaac-aec48ed5979d	c1	Snackar Chana Magic Masala Rs.40/-	Namkeen	Pcs.
d2c7ce4f-40ed-4bad-9b46-513f9554d1fd	c1	Snackar Chana Magic Masala Rs.5/-	Namkeen	Pcs.
4d3191bb-963d-4fe6-be20-6d94554eb636	c1	Snackar King Choice Mix D&apos;fruit Rs.55/-	Namkeen	Pcs.
aa478b57-1806-469c-90d6-cf06b8a3387e	c1	Snackar King Choice Mixed Dryfruit Rs.195/-	Namkeen	Pcs.
31b8ad07-8b34-4adf-a8f8-7d23fa4b40c0	c1	Snackar Peanut Classic Salted Rs.5/-	Namkeen	Pcs.
af3daf79-0744-40ad-90c3-a8249993e6d2	c1	Snackar Peanut Crunchy Rs.5/-	Namkeen	Pcs.
726f25b1-7846-4cf2-be27-98c67cdf79ab	c1	Snackar Peanut Hing Jeera Rs.40/-	Namkeen	Pcs.
79c72180-4108-444e-9c04-a81167cbe901	c1	Snackar Peanut Kolhapuri Chilly Rs.5/-	Namkeen	Pcs.
d1769bea-86e4-4be3-b96f-212387b13891	c1	Snacker Chikki Rs.5/-	Namkeen	Pcs.
a650137c-8211-4479-bd12-876c30ac4f20	c1	Veeba Sauces	Food	Pcs.
12c1ad72-1548-4f41-b19e-5da7e361434a	c1	Snacker Peanut Black Pepper Rs.40/-	Namkeen	Pcs.
9507aeab-6e5d-47c7-9b51-8e1c45fa370b	c1	Snacker Peanut Chatmasala Rs.10/-	Namkeen	Pcs.
32b33c91-dba0-4fcd-8d8d-6a4e2cd505fe	c1	Snacker Peanut Chatmasala Rs.40/-	Namkeen	Pcs.
f5832f65-b8cf-4bf8-836b-7a61c9baedeb	c1	Snacker Peanut Chikki Rs.10/-	Namkeen	Pcs.
3bbce7be-a908-4a00-b2fa-f0e012b8a1a4	c1	Snacker Peanut Classic Salted Rs.40/-	Namkeen	Pcs.
cbd00bb8-5f9d-4f69-ac36-32e7a8a1a7d1	c1	Snacker Peanut Crunchy Rs.10/-	Namkeen	Pcs.
844a43ed-8f92-462f-a665-7bc63d905e55	c1	Snacker Peanut Crunchy Rs.40/-	Namkeen	Pcs.
788f9131-a86f-4338-bb05-a5c89285bd28	c1	Snacker Peanut Hing Jeera Rs.10/-	Namkeen	Pcs.
38e0f8d3-ea9d-41cf-8226-c2466c219d7c	c1	Snacker Peanut Kolhapuri Chilly Rs.40/-	Namkeen	Pcs.
e39b5541-5cfd-464c-ba8b-6ff2e54d83f5	c1	Snickers Milk Shake 350ml.	Drinks	Pcs.
fa0f45c9-1238-4d62-9d68-26e5465f8943	c1	Snowlan 100% Arabica Green Coffee Beans 150gm	Food	Pcs.
c90933c8-351e-4270-99d6-8336b1955e1e	c1	Snowlan 100% Arabica Roasted Coffee Beans 120gm	Food	Pcs.
70e168fc-24d8-4d21-883e-bea035037cb4	c1	Snowlan 50% Sweet Dark Chocolate 50gm	Food	Pcs.
acd9c4a0-4ab4-421f-a069-926043378901	c1	Snowlan 75% Intense Dark Chocolate 50gm	Food	Pcs.
38b19efa-1cf9-4c3a-a691-024abec1acea	c1	Snowlan 85% Wicked Dark Chocolate 50gm	Food	Pcs.
1481a0b5-6940-4d7b-b49a-e8751597aa18	c1	Snowlan Almond Dark Chocolate 50gm	Food	Pcs.
4ffc9634-9f36-4d06-bb6a-5e8d334c1264	c1	Snowlan Assorted Instant Coffee 80gm	Food	Pcs.
34a49cbe-3cef-4cea-a8e6-531a11d593be	c1	Snowlan Assorted Mocha Box 80gm	Food	Pcs.
3ddc8f88-68e9-4326-98db-8615255040b9	c1	Snowlan Calm - 10 Tea Bag Sticks	Food	Pcs.
3340778b-b75b-4dc4-9ce7-d54c0d53c25c	c1	Snowlan Coffee Dark Chocolate 50gm	Food	Pcs.
6561fd89-efbb-4fda-bab9-2f90f20bba80	c1	Snowlan Detox - 10 Tea Bag Sticks	Food	Pcs.
e46b5fdd-ac49-49c9-a8be-f9301af7cced	c1	Snowlan Double Chocolate Mocha 1.3g.	Food	Pcs.
045b02d0-a90f-469d-a878-49e970fd55e0	c1	Snowlan Double Chocolate Mocha 50gm	Food	Pcs.
dcd91c38-6895-4b7a-ba2d-e4416f974769	c1	Snowlan Drinking Cocoa 100gm	Food	Pcs.
9a394ec1-5638-4ac5-92de-d483697de996	c1	Snowlan Elaichi Chai 100gm	Food	Pcs.
0cab1a37-a1ef-45f8-b59f-087db02c676d	c1	Snowlan Espresso Filter Coffee 100gm	Food	Pcs.
8670fd8d-3005-4913-a82b-7fb566c29ba6	c1	Snowlan Green Coffee 10 Stick	Food	Pcs.
5c478a99-ab47-4d1c-be83-8ef32570f3f0	c1	Snowlan Green Coffee - 10 Sticks	Food	Pcs.
052e40f6-44f3-412a-bae0-a6950491b0fc	c1	Snowlan Hazelnut Dark Chocolate 50gm	Food	Pcs.
b6566460-5a29-4aa4-ba8f-b56875e4990f	c1	Snowlan Hazelnut Instant Coffee 50gm	Food	Pcs.
6d9c2a61-7547-42c3-a10d-fe25b2f35f42	c1	Snowlan Instant Coffee 1.4gm	Food	Pcs.
ef020feb-7ebd-442e-9862-d22b71f7bb42	c1	Snowlan Instant Coffee 50gm	Food	Pcs.
17827130-ea5b-4907-bdd4-0889d1922702	c1	Snowlan Masala Chai 100gm	Food	Pcs.
4489f241-5341-449a-b4b4-c809f6ab983d	c1	Snowlan Mix - 9 Tea Bag Sticks	Food	Pcs.
abd8aa36-87b0-4580-af80-0b83b4e01184	c1	Snowlan Peppermint Dark Chocolate 50 Gm	Food	Pcs.
bfde6501-3762-49e0-8046-9315f4722c73	c1	Snowlan Slim - 10 Tea Bag Sticks	Food	Pcs.
05e73b5f-be9f-4bb8-8b0d-f2589eff3d4a	c1	Snowlan Spa- 10tea Bag Sticks	Food	Pcs.
b86b7d9e-a6bb-4a9a-a0e6-b1a236e474df	c1	Snowlan Vanilla Instant Coffee 1.4gm	Food	Pcs.
24f3355b-4972-403f-a46c-2371c5b9ca68	c1	Snowlan Vanilla Instant Coffee 50gm	Food	Pcs.
81c3b645-6af8-4898-a9fb-2938f9ce628e	c1	Snowlan Wild Orange Dark Chocolate 50gm	Food	Pcs.
845dce6b-113e-46be-ae2d-34d734a98105	c1	Soba Noodle 300gm	Food	Pcs.
bc974e37-cef3-4543-b195-0a0b9c3724d5	c1	Soda Biocarbonate 100 Gm (18%)	Food	Pcs.
4042c3d4-3b5c-49be-a0ba-198fd84ee85b	c1	Sodium Hypo  Chloride 5 LITRE	Cosmatics	Pcs.
346f35d9-03d4-4e50-8cc8-c6e3ec4e6bec	c1	Sofit Van 1 Ltr	Drinks	Pcs.
29b5eebf-7120-4f1f-9915-8c973aae99b8	c1	Soft Cake Chocolate 16 Gm	Food	Pcs.
39ac1bc0-f644-4c78-9d4c-58145c75dea1	c1	Soft Cake Kaju/cheese 16 Gm	Food	Pcs.
1e81e904-138d-47a8-90cb-21a10c3ee905	c1	Soft Drink Assorted 320ml.	Drinks	Pcs.
95a1730d-36b1-4a5f-8b60-d11c03fea939	c1	Soft Wheat Flour Type Pizza Flour 1 Kg	Food	Pcs.
7ee7852e-d5cc-4f4d-85f3-6ffd4a4d7213	c1	SOLASE EXTRA VIRGIN OLIVE OIL 1ltr	Universal  STOCK	Pcs.
949f0e68-d565-429d-90c6-58a9b54a99ae	c1	Solemio Green Olive Pitted 450 Gm	Food	Pcs.
cfd14738-7888-4523-8bf1-d8c18e24bd71	c1	Soon Rice Paper	Food	Pcs.
0ad239a3-8113-4057-aa40-d7899891c6af	c1	SORGHUMA CHIPS JAR	Food	Pcs.
efd71c3b-f698-4f44-b930-62edfaac7859	c1	SORGHUMA CHIPS (JOWAR) JAR	Food	Pcs.
9d295edd-7937-430e-9c46-5cfc7a7a5e7f	c1	SORGHUM CHIPS (JOWAR) JAR	GURU FOOD	Pcs.
620200e3-8f04-4b69-a843-5664f76ddc99	c1	Sour Punk 40 Gm	Food	Pcs.
3480591d-78c3-43ed-adfc-11719e241d1e	c1	SOYA CHIPS JAR	GURU FOOD	Pcs.
ccceb3d5-7bb6-44af-88b3-e6121339754f	c1	SOYA CHIPS (PERI-PERI)	GURU FOOD	Pcs.
f18b12f5-9f81-49e9-a413-88f4f99c0ae8	c1	SOYA KATORI JAR	Food	Pcs.
901188eb-7123-498e-932e-9ac5147944b6	c1	Soya Sauce 800ml	Food	Pcs.
3f1f2156-c414-43b1-af6b-e8a43c1f5068	c1	SOYA STICS JAR	GURU FOOD	jar
818db103-3218-40de-bb7b-078c813dfbea	c1	Soybean Curd (TOFU FIRM) MORINU BARAND 349G	Food	Pcs.
72d65840-cfc7-4a93-8b9d-e2732f8f53b8	c1	SOY MILK NATURAL 200G.	Drinks	Pcs.
ed0755bd-23c9-4573-a08f-db9f99573925	c1	Speghetti Pasta 500 Gm	Food	Pcs.
7f93fedf-5b65-444e-8ed0-ef981c6715b6	c1	S.Pellegcrino Minral Water 250 ML	Drinks	Pcs.
7f4bb21d-c2c1-4335-aad9-684dc3be6c27	c1	S.Pellegcrino Minral Water 750ml	Drinks	Pcs.
6aaa516c-9b1a-419c-a5e6-2c8f5f054350	c1	Spices(PICKLE)	Food	Pcs.
7b23cec0-0b3e-45d3-bfc6-144e0f249adf	c1	Splenda Box	Food	Pcs.
60fdc033-d1f2-4d00-9b70-cb1820461eca	c1	Splenda Sachet 100	Sugar Free	Pcs.
41b37269-486e-4c64-9341-e509f30de6fa	c1	Splenda Sachet 200	Sugar Free	Pcs.
2c54c75f-0a57-45e0-8621-74a18d47958c	c1	Splenda Sachet 50	Sugar Free	Pcs.
b6750bfb-0df4-4ca0-ba8a-e1a646bfc9cc	c1	Splenda Sucralose 2000 Ct. Sachets	Food	Pcs.
02a7a642-66f1-4f2b-98ae-cb3f4d1d8e33	c1	Splenda Sugar 4.5 Gm	Food	Pcs.
a4cc744c-5646-4fcc-b3e7-d67b65d76079	c1	Splenda Sugar Sachet 2000pc	Food	Pcs.
2c5e1e86-a3e9-4ea0-8c59-7b0a148e9f47	c1	Splenda Sugar Sachet 2000 Pcs	Food	Pcs.
9a31acde-49d0-4ecd-bab3-697b66d64340	c1	SPLENDA SUGAR TAB /100 MINI	Sugar Free	Pcs.
d08e93d9-d204-4d3b-982f-490fd57aa4fb	c1	Splenda Tablet 500 (18%)	Food	Pcs.
688711ae-ebb6-4278-9dd5-5ee37d85bdcd	c1	Splenda Tablets 100	Sugar Free	Pcs.
24285986-db7d-47a3-9fcc-4941c1726676	c1	Splenda Tablets 300	Sugar Free	Pcs.
e6525177-07f2-402b-ad4a-bc091a3e34a2	c1	Splenda Tablets 500	Sugar Free	Pcs.
2d0f8e0b-3be0-4945-8843-5e60200d2c43	c1	SPLENDA ZERO CALORIE SWEETENER 7.5g 300MINIS	Food	Pcs.
f31dab69-0bf1-429f-b082-e376db94bbf6	c1	SPLENDA ZERO CALORIE SWEETENER 7.5g 500MINIS	Food	Pcs.
82533a9b-cf0e-466a-ac01-f27f80d99822	c1	Sprinkler Can-Chilli Flaks-40g.	Food	Pcs.
0def3c7c-451c-4a41-8392-9091c146d178	c1	Sprite 1.25 Ltr Pet	Drinks	Pcs.
30e51209-d241-4278-bdde-f9dba9a5e7a3	c1	Sprite 2.25 Ltr Pet	Drinks	Pcs.
64bd7092-2459-4a2f-8b2f-f42a98ef26b1	c1	Sriracha Brand Chilli Sauce 570ml.	Food	Pcs.
c9a29fed-6849-4fc5-a9a7-fda7b51e5f19	c1	Sriracha Chilli Sauce 455 Ml	Food	Pcs.
346d2fb1-2068-48c9-8e92-0243777f8133	c1	Sriracha Chilli Sauce 570 Ml	Food	Pcs.
f748426a-6dcd-4cde-a976-4dc67c40561a	c1	Sriracha Chilli Sauce 730 Ml	Food	Pcs.
76c35895-951b-45d8-832b-0636ab7cc480	c1	Sriracha Hot Chilli 340g	Food	Pcs.
bf0e81d8-433d-4141-93dd-d9a45d8c3435	c1	Sriracha Hot Chilli Sauce 540gm	Food	Pcs.
53c98863-14be-424b-9912-0fde40798670	c1	Sriracha Hot Chilli Sauce 770gm	Food	Pcs.
076e28c9-449b-40f2-8966-1062425c6ad3	c1	Sriracha Mayo Sauce 200 Ml Mrp.295	Food	Pcs.
58c35c5b-10bd-4fa2-a2a2-f141f6550963	c1	Sriracha Mayo Sauce 455 Ml	Food	Pcs.
af6e6f09-0912-45c1-ab0e-ebc88da2fd6e	c1	Sriraja Brand Chilli Sauce 570gm (Imp)	Food	Pcs.
302fb861-6949-4efe-bd46-9d326f563b0e	c1	Sr,S Honey 15gm	Food	Pcs.
cd54a8a9-afff-4b7d-8cb3-58fda763c631	c1	Sr,S Mixed Fruit Jam 15gm	Food	Pcs.
c9f3e5a1-423a-4687-95c2-e442e604a0e9	c1	SR,S Mixed Pickle    125X15g.	Food	Pcs.
8381fc13-6adb-43f0-affb-412203651930	c1	Starbucks Coffee	Food	Pcs.
8e32c5d2-998a-4d13-82e7-4375e9c6a4b5	c1	Starbucks Coffee Flavour	TEA	Pcs.
98cb3210-77fb-4919-915f-d88afbd85cfd	c1	Starbucks Kings Coffee Latte 280 Ml	Food	Pcs.
51857e44-4b65-46a1-92ca-e2c55947a461	c1	Starbucks Mocha Coffee	Drinks	Pcs.
872b5986-18d9-4832-a2cc-c8c217904e78	c1	Starch Potato / 1 Kg	Food	kg.
ffc89b4a-1eec-4406-b608-ff9b48851daf	c1	Star Lion Vermicelli 200gm.	Food	Pcs.
c29b7d6d-6664-4bff-91e0-2cc319760204	c1	Star Lion Vermicelli 500gm.	Food	Pcs.
506ee5b8-6d9d-469e-b067-e0f3eb4a4d67	c1	Sticky Rice	Grains	kg.
89b796b7-6759-4fa8-b10f-72d6f07472dd	c1	Sticky Rice 2kg.-Japnese (Gultinous)MBK	Food	Pcs.
9ad2c04c-24bb-4e7c-997a-ca5207e90919	c1	Storia Coconut Water 200ml.TP	Drinks	Pcs.
d3eeb091-011f-4581-a839-3816a8feb5f5	c1	STORIA COCONUT WATER 200ML TP FREE	Drinks	Pcs.
68627d96-87d7-47f8-9c4e-a1ac9e9a6e81	c1	STORIA WHITE MAGIC 1 KG	Drinks	Pcs.
1c2fb950-99fa-479f-b072-1ad939fdcee8	c1	STORIA WHITE MAGIC 1KG(INST &amp; TS)	Drinks	Pcs.
495b5e2f-e994-4bd0-b7d9-b7dc86255a38	c1	STORIA WHITE MAGIC 25G	Drinks	Pcs.
607f352b-6e42-4487-88fb-ec80792788bb	c1	STORIA WHITE MAGIC 400G	Drinks	Pcs.
ec7d5aec-b10c-49ca-94dd-46ca8393cd26	c1	STUTE JAM	Food	Pcs.
7937917e-74fc-4553-ab59-2d06c6f9c218	c1	Suddhi Buffalo  Ghee Jar 1000ml	Food	Pcs.
061294ac-3d06-4d8b-a8d6-ee9e15e742fb	c1	Suddhi Buffalo  Ghee Jar 200mL	Food	Pcs.
75d6830f-5674-4a31-8bba-ee15a36275d6	c1	Suddhi Buffalo  Ghee Jar 500mL	Food	Pcs.
9fe0984f-bb44-4a4a-958c-104317b99d4f	c1	Suddhi Cow Ghee Jar 1000ml	Ghee	Pcs.
cfad8c1d-ee9d-41ef-9a0c-b452afc7ae72	c1	Suddhi Cow Ghee Jar 200ml	Ghee	Pcs.
11eb863e-2a14-43b7-8985-547819707a45	c1	Sugar Boil Cofectionery Assorted Candy	Food	Pcs.
8b192b04-dc3f-4bee-97f6-f1c13714908f	c1	SUGAR BOILED CONF.B ANIMAL JAR	Food	CAR
c96787a6-f960-4c99-bff3-ad56dcd5fe65	c1	Sugar Boiled Confectionery 55 Gm	Food	Pcs.
1f2a48a7-ddcc-4f33-9fc7-8e17c4f87f50	c1	Sugar Boiled Confectionery Candy	Food	Pcs.
741a3acc-707a-4538-bbf0-107b4a5d03a7	c1	Sugar Boiled Confectionery in Box	Food	Pcs.
d6b9e8a0-f8ba-4a2a-a6ca-43c824536862	c1	SUGAR BOILED CONFE(DATES)G/Pockey Stick	Confationery	Pcs.
faf6528d-3948-4cb3-b2b7-ff2c48ea875c	c1	Sugar Cane Vinegar 500ml.	Drinks	btl.
091d7167-1cb2-4edd-8303-662d0dd67a8b	c1	Sugarfree CandyX	Food	Pcs.
9fb3b771-65bd-4368-8d64-c6c6eb715d59	c1	Sugar Free Energy Gum	Food	Pcs.
287cd33b-6ad6-4322-9815-ee61b6505767	c1	Sugarless Shortbread Expresso 100g.	Sugar Free	Pcs.
e5dcbc2e-bc2b-49b5-be3a-1e3f84ff4220	c1	Sugarless Shortbread Roasted Almond 100g.	Sugar Free	Pcs.
e0e7e932-a15b-4e24-a506-4ec4fe212bf9	c1	Suger Less Shortbread Netural Btr.200g.	Biscuts	Pcs.
0ed4d5cf-9c8a-49e7-ab19-8b84171b74ba	c1	Sugerless Shortbread RaspberryJelly 200g.	Sugar Free	Pcs.
b3e3db0c-b2b1-4082-8d5b-2c1ba754f1ac	c1	SUnbay Jalapeno Slices 3 Kg Mrp.350	Food	Pcs.
c3e17a38-e83f-449f-bf8e-b924451cc7dd	c1	SUNDRIED TOMATOES IN OIL 285G	Food	Pcs.
a3e1b935-cc72-4290-9013-1457eb50c397	c1	SUN DRIED TOMATOES PAPER DR 1000G.(ACE)	Food	Pcs.
2dd2752e-b28a-49a4-bc6b-2aa78400d0b1	c1	Sundried Tomato in Oil 280gm	Food	Pcs.
8bd10769-c77b-4963-a7f0-e7626d920c17	c1	Sunsweet Pitted Prunes 200gm	Food	Pcs.
e143da58-0b5b-4bf8-880a-1c6f14469338	c1	Super Gummy Pack Pouch 5s Rs.10/-	Chocolate	Pcs.
75885336-c367-42f8-80bc-1d61485323d5	c1	Sushe Bamboo Mat (12%)	Food	Pcs.
49463629-9a0e-4108-b716-a011a9c5f4e8	c1	SUSHE RICE 1. K.G	Food	Pcs.
90a80f9e-103d-4582-aad3-688e7b99389b	c1	Sushi Bamboo Mat (18%)	Food	Pcs.
3c2f45a6-8206-48f1-b0a9-38d16e1042b3	c1	SUSHI GINGER Pickle 1.5 KG (Jar) (12%)	Food	Pcs.
8b3628eb-1828-49f8-b1ec-dce3596c6012	c1	Sushi Ginger Pink 1kg (12%)	Food	Pcs.
fab9291f-4e65-4062-9e87-2fb4cc5c62f6	c1	Sushi Mat White	Food	Pcs.
94de5db7-defa-4089-aed3-a777a7cc9410	c1	SUSHI NOORI GOLD A GRAD 50SHEETS	Food	Pcs.
865f802f-abc2-4f82-9d81-9057fa7093d8	c1	Sushi Noori Sheet / 50 Sheets	Food	Pcs.
0b13f60d-9175-47cf-bf5d-ea6e1a01faf7	c1	Sushi Radish Takuwan 500gm	Food	Pcs.
c0bfebfb-1e2d-48a4-a15b-9752fc926cb4	c1	SUSHI RICE	Food	kg.
b242aee5-acac-4db8-8f56-530fad1f7b2e	c1	Sushi Rice 1 Kg	Food	Pcs.
22be58f5-4747-420b-9324-f3bb9239957e	c1	Sushi Rice (22.68 Kg)1 Bag	Food	Pcs.
82573fbf-3ffc-44ac-b242-bc0354acf81a	c1	SUSHI RICE KOKU FOR YELLOW 10KG	Food	Pcs.
0256c5db-0cfd-4232-9406-e9834e8ce825	c1	SUSHI TAKUN 1KG	Food	Pcs.
50ce1222-bc9d-4ddb-8b40-71c51165bc71	c1	Sushi Vinegar 1.8 Ltr	Food	Pcs.
68dfa368-7b04-400a-a641-82dc15470896	c1	SUSHI VINEGAR 500ML. (IMP)	Drinks	Pcs.
241ccfc7-71ba-42d1-984b-6c8c7f128963	c1	Sushi Vinegar 500ml*  NOSTIMO	Food	Pcs.
47b11953-1223-418d-ab50-625f00918ad4	c1	Swasa Mask N95 (1pcs)	Cosmatics	Pcs.
e68c7fe5-f911-4f02-abb2-8f9c3f725142	c1	SWEET CORN (ACE)	Food	Pcs.
170f65a0-ea41-4b89-aa4a-b33885f6f305	c1	Sweet Corn E	Food	Pcs.
84994477-2205-47e0-9cf2-fb318d778044	c1	Sweet Corn Kernel  (Prom Plus) 410gm	Food	Pcs.
9ae1671f-401d-495b-a214-4979f0006b3b	c1	Sweet Heart Chocolate Paan	PAAN	Pcs.
709fb452-a1bb-427d-9606-db4aca0fb5ca	c1	Sweet Heart Dryfruit Paan	PAAN	Pcs.
18e1bb4e-4837-4601-ba8e-92380ed9a1fb	c1	Sweet Heart Kesar Paan	PAAN	Pcs.
250eb732-9efd-436d-9c3b-fe3a6c455540	c1	Sweet Heart Meetha Paan	PAAN	Pcs.
e785fc55-c872-46f6-88a4-f54558820e28	c1	Sweet Mango Pickle 1kg	Food	Pcs.
cc2ee423-44e0-4dd6-9c4f-8043ce597b16	c1	Sweet Mango Pickle 500g	Food	Pcs.
ded7bddd-19a5-4d3c-ab62-5c09c83889b9	c1	SWEET PEPRIKA POWDER500G	Food	PKT
82e4fc66-a72b-43b2-b034-326f5a3da68c	c1	Switz Spring Roli Patty	Food	kg.
59376b62-c4e9-44ce-98bd-af9cbe0f0a9c	c1	Switz Spring Roll Dough Sheet 10*10	Food	Pcs.
01d54c47-705e-4598-99b9-60593fad0856	c1	Switz-Spring Roll Patti-6 *6-275gm	Food	Pcs.
c54aba52-4104-4e26-b413-b86f3aca28ee	c1	Switz-Spring Roll Patti-8*8-275gm.	Food	Pcs.
355c3f9a-e34b-4339-b489-536d7f3d2c71	c1	Switz Spring Roll Patty 10*10 550 Gm	Food	Pcs.
7f2ad0bc-c650-4503-9733-87e532b07c20	c1	Switz Spring Roll Patty 550g.	Food	Pcs.
69f52114-91b7-48d0-92d1-3e1ff7665ce5	c1	Switz Spring Roll Patty 6*6	Food	Pcs.
03b09e5d-28d8-4cb2-806b-175a879fabdc	c1	Switz Spring Roll Patty 8*8	Food	Pcs.
fd7d83f5-4793-49c6-a061-b23ab242595d	c1	Switz Spring Roll Sheet 7.5*7.5	Food	Pcs.
f89abbe6-5eb5-4492-900a-bba9d1f59ad3	c1	SWIZZO JOY GIFT PACK	Chocolate	Pcs.
7e217b28-f7ad-4014-b00e-88425962306e	c1	T16 FERRERO ROCHER	Food	Pcs.
0913cdb2-bc2b-462e-a18c-ad5867e02eaf	c1	T3 Rafaello (18%)	Food	Pcs.
8b90426f-b3c2-46d7-9fe0-cb5dba944800	c1	Tabasco 60ml	Food	Pcs.
a80dea05-4244-4e41-8b78-c0c4ee29e4f3	c1	Tabasco Green Pepper Sauce 60 Ml	Food	Pcs.
9c9098dc-e4d7-4184-b208-c63e626591b1	c1	Tabasco Red Pepper Sauce 60ml.	United Distributor	Pcs.
1e90806d-8379-45e4-972c-89ef8008e00c	c1	Taco Shell 80 Gm	Food	Pcs.
9294bca1-e201-4645-ba55-06941abcec44	c1	TACO SHELL OLD EL PASO	Food	Pcs.
ebcb7e34-eb79-47e6-b5ab-0cedc59f2c98	c1	Tahina 500ml	Food	Pcs.
39a02a06-67c4-484e-a7e9-355f6162cb35	c1	Tahina 650gm	Food	Pcs.
ec60fe45-dd9e-46d6-846c-41e2efdee7d8	c1	Tahina 650 Gm 18%	Food	Pcs.
dfabec72-4126-4932-ab9b-5bd68587e9c9	c1	Tahina Ameera 600gm.	Food	Pcs.
b5a4f948-8ea7-431b-9b4e-9384965f0723	c1	Tahina Paste 400g.-Al Ameera	Food	Pcs.
adb60546-1be3-4aee-b2d5-8730973d9b30	c1	Tahina Paste R.C. 600g	Food	Pcs.
68a116d5-a0e0-4254-a31b-28aa5c32d059	c1	Take A Bite Assorted Biscuits Tin 600 Gm Mrp 395	Food	Pcs.
e7a1cc6b-c2c3-4208-b65a-790a6ddbb312	c1	Tally Software Services Silver (TSS)	Electrical Goods	Pcs.
c931a0bc-1e52-445c-a242-bee130bae575	c1	Tamarind Candy 120gm	Food	Pcs.
386b6138-b681-4f85-a755-ccb13d58d41e	c1	Tamarind Chewy Spicy Lime Candy 25gms.	Chocolate	Pcs.
5d9dc4ee-8f9e-4a3c-ae65-f0ef1a1dd17c	c1	Tamarind Chewy Spicy Santol Candy 25gms.	Chocolate	Pcs.
069e801f-4310-4e90-ac31-e8582bb772aa	c1	Tamarind Mango Soft Candy 25gms.	Chocolate	Pcs.
b4a04697-a048-4b35-a70e-e0d6c9b789f6	c1	Tamarind Orignal Candy 25gms.	Chocolate	Pcs.
2c542801-f215-45ce-84b1-33507e123865	c1	TAMARIND PAST	Food	Pcs.
aea244e2-3a57-4973-a81c-bd33d84b551b	c1	Tamarind Paste 250 Gm (12%)	Food	Pcs.
b1ee828b-a738-4886-93eb-8a935a456308	c1	Tamarind Soft Candy 25gms.	Chocolate	Pcs.
3ff04c94-9a51-43d8-aecb-f9e3a789595b	c1	Tamarind Spicy Soft Candy 25gms.	Chocolate	Pcs.
60a92961-ea38-4425-b127-677101730483	c1	Tang 200g.Mango	Drinks	Pcs.
6fab0037-6fa2-4876-85b7-b53f0df0ac1d	c1	Tang 500g	Drinks	Pcs.
96aa748d-8a54-4877-9d8d-1f13b0e7ee61	c1	Tang 500g.Lemon	Drinks	Pcs.
f86e5470-996f-4b1b-924c-296cd1d971cb	c1	Tang 500g.Mango	Drinks	Pcs.
c4cfab2a-d1ff-4e5f-9d69-fd92141cb294	c1	Tang 500g.Pinapple	Drinks	Pcs.
8bf433a0-c190-45d3-80fa-cffa2883878a	c1	Tang 750g.Orenge Rs.115/-	Drinks	Pcs.
39b055e1-405d-4b22-a912-b648e37eb859	c1	TANG INSTANT DRINKING	Drinks	Pcs.
aacf1737-7c7c-4ae0-86c1-7ff03fc35878	c1	Tang Orange 500gm	Drinks	Pcs.
2bbda53a-6ae2-499a-befd-86d56852c3a2	c1	Tang Tropical 500gm	Drinks	Pcs.
c32b419c-c3a7-4b7c-912c-8b701d19af31	c1	Tapioca Starch 500gm	Food	Pcs.
69c24700-d71b-4c15-88bd-d38ef963b53c	c1	TARMAIND PASTE	Food	Pcs.
5ce6674e-6be4-43c4-b44c-09a3be7c2005	c1	Tata Gold 500 Gm	Food	Pcs.
e1a9cd93-9171-4ee7-bf41-00171b785e05	c1	TEABRO ADRAK (GINGER) BOTTEL 150ML	TEA FLAVOURED	Pcs.
49ee76ef-07b3-4a08-bb2d-8976c558618b	c1	TEABRO ADRAK(GINGER ) TEA	TEA FLAVOURED	Pcs.
4db79370-d4ac-4899-8e6c-a00367623e6e	c1	TEABRO ELAICHI(CARDAMOM)BOTTEL 150ML	TEA FLAVOURED	Pcs.
d82b5a9b-af36-481a-a508-4c5df87770f2	c1	TEABRO ELAICHI (CARDAMOM) TEA	TEA FLAVOURED	Pcs.
76f27918-fc36-4f8e-b65f-948ebd50b205	c1	TEABRO MASALA TEA	TEA FLAVOURED	Pcs.
5eee4ed7-c03d-4bff-97aa-38ff1542228a	c1	TEABRO MASALA TEA BOTTEL 150ML	TEA FLAVOURED	Pcs.
2680d290-bb4c-4140-9e4e-622050de3131	c1	TEABRO TEAKIT ADRAK(GINGER)	TEA FLAVOURED	Pcs.
6d43ec06-66c2-49d2-abde-1e7f580b3847	c1	TEABRO TEAKIT ELAICHI(CARDAMOM) TEA	TEA FLAVOURED	Pcs.
d92ba1b1-cc3b-4908-95c6-30b8f282f9a2	c1	TEABRO TEAKIT MASALA TEA	TEA FLAVOURED	Pcs.
9d2c0d81-39a9-4e2e-8e94-e52426554c06	c1	TEABRO TEAKIT UN-FLAVOUR TEA	TEA FLAVOURED	Pcs.
409ab337-7c56-434a-bdb2-b6fdc4519468	c1	TEABRO UN-FLAVOUR	TEA FLAVOURED	Pcs.
8f1b1fbb-cfd0-40fd-a122-6d1e95b788d4	c1	TEABRO UN-FLAVOUR BOTTLE 150ML	TEA FLAVOURED	Pcs.
6609a600-6574-4acd-b7d6-da155b7ad022	c1	Tea Premix	Drinks	Pcs.
8b3c2b49-fcca-4598-b51d-5ef33e5ae900	c1	Tea Time Cranberry &amp; Rasberry 1 Ltr.@200	Drinks	Pcs.
2c664b97-f56f-4f43-ac1b-d65b58432104	c1	Tea Time Peach 1 Ltr @200	Drinks	Pcs.
9cb7d904-3e71-4f4b-93ff-a0e1eb7b95ef	c1	Teddy Pop 36 Pc	Food	Pcs.
1435b8a0-8f4f-4293-8999-747cca1d2f39	c1	TEMPURA BATTER 1KG	Food	Pcs.
6a353baa-c633-4129-accd-3f0520e45a83	c1	Tempura Batter Mix Floor 1 Kg.Mr.Hung Brand	Food	Pcs.
6228f740-51af-4fce-bb44-abc1d17760d5	c1	Tendo Almond Milk (1000 Ml) Mrp.295	Dairy Products	Pcs.
76bc8434-fa20-4e07-bc2e-08db2a0ad104	c1	Tendo Almond Milk 330 Ml Mrp.120	Drinks	Pcs.
f16a4d6c-c280-4b00-811b-37099c12e40c	c1	Tendo Almond Milk 330 Ml Mrp.120(18%)	Dairy Products	Pcs.
8acae76c-e1b7-485a-9ce7-f1656db3e91c	c1	Tendo Almond Milk Coconut 180 Ml Mrp.40	Drinks	Pcs.
2b7dd5e3-9b80-4a6b-926d-3d31c2893d75	c1	Tendo Coconut Milk Mrp.70	Dairy Products	Pcs.
8c8fadad-c261-478f-b0ec-0481a2437120	c1	TENDO COCONUT MILK SHAKE	Drinks	Pcs.
ebe75b53-79af-4269-894d-76c8238db9cd	c1	Tendo Coconut Milk Shake (Almond) Mrp.35	Drinks	Pcs.
4bc6fdf8-3eed-49f5-943f-930cb9f3cc37	c1	TENDO COCONUT WATER 200ML Mrp.40	Drinks	Pcs.
9f1402a5-2d57-4fc0-9b14-c2d1a0502d8d	c1	TENDO COCONUT WATER 200ML MRP.40 (30x1)	Drinks	Pcs.
07b4bf7f-909b-4dab-9751-ea918c17bbfe	c1	Tendo Milk Shake 180 Ml (Choclate) Mrp.30	Drinks	Pcs.
bebbabd9-17df-481b-80dc-3fe19e226cbf	c1	Tendo Milk Shake 180 Ml (Pineapple) Mrp.30	Drinks	Pcs.
f9426a2a-65c9-45e2-bb1a-9ddd75e30ab3	c1	Tendo Milk Shake 180 Ml (Vanilla) Mrp.30	Drinks	Pcs.
601f0452-cfdd-4c84-84e0-204df96f1bd3	c1	Tendo Milk Shake Assorted Mrp45	Drinks	Pcs.
855686a8-2d8a-41e1-adb7-97d44fa3fdf6	c1	Tendo Walnut Milk (1000 Ml) Mrp.345	Drinks	Pcs.
3c9be94f-cafd-4009-884b-3c601577863d	c1	Tendo Walnut Milk 330ml Mrp.125	Dairy Products	Pcs.
7553b001-5ba6-4ced-8093-91d553497ad4	c1	Teriyaki Sauce	Food	Pcs.
f8703d1b-4bc4-4120-8e13-22fac8bc45fd	c1	TG Garlic Peanuts 70 Gm	Food	Pcs.
a28048af-6660-4628-85fe-fb9ba70ec9d6	c1	TG Mexican Style Peanuts 70 Gm	Food	Pcs.
7ad0a452-fffb-42de-977f-41ea53d036d7	c1	Tg Paprika Pumpkin 30 Gm	Food	Pcs.
5f9fb77a-ce53-4b2a-9e7f-82bc2468bc3b	c1	Tg Party Snack 180 Gm	Food	Pcs.
09e0cb97-15bf-4c8e-86af-87137ab5a510	c1	Tg Party Snack 35gr	Food	Pcs.
5a461bf8-d98d-4455-af55-1009340ebd2b	c1	TG Party Snack 40 Gm	Namkeen	Pcs.
ae3fa6ce-5d28-4223-80b3-6ffd5899e3d9	c1	Tg Party Snack 450g	Party Snacks	Pcs.
52bba466-09c5-4726-839f-ef5217c26b27	c1	TG Party Snack 500 Gm	Namkeen	Pcs.
41c119cc-60d3-4136-b33a-91d3faf2baca	c1	TG Party Snacks 160g	Party Snacks	Pcs.
47248393-87c7-42f3-a267-64c40c1f0903	c1	Tg Salted Almond 140g	Party Snacks	Pcs.
9174e2b0-ce7b-4b6f-8a66-50eb654a6bef	c1	TG Salted Almonds 35 Gm Mrp.70	Food	Pcs.
c54a4de9-0dba-483f-a033-29fce89cd9f6	c1	Tg Salted Almonds 400 Gm	Food	Pcs.
afadecc3-d4b5-4a02-a967-997cd2eb9e80	c1	Tg Salted Cashew Nuts 400 Gm	Food	Pcs.
395ba838-0d70-47f4-b3ee-035b293903e8	c1	TG Salted Cocktail Nuts 160 Gm	Namkeen	Pcs.
046712d2-7828-4734-872f-84b88b64e40e	c1	TG Salted Cocktail Nuts 400 Gm	Food	Pcs.
ceedf8ed-ef5b-4b37-a941-dd9061deca4b	c1	Tg Salted Peanut Pouch 150g	Party Snacks	Pcs.
c87e95cb-612f-443d-8187-36b4b9b52026	c1	TG Salted Peanuts 160 Gm	Food	Pcs.
a4e6c692-d796-4889-8096-419f81b54267	c1	TG Salted Peanuts 32 Gm	Namkeen	Pcs.
d2b00caa-3831-4872-8d46-e66e300a7da6	c1	Tg Salted Peanuts 370g	Party Snacks	Pcs.
4a5ab4da-9970-49b1-8535-cba4637d4482	c1	TG Salted Peanuts 37 Gm	Food	Pcs.
6ae4be6d-15a5-42ed-953a-459c2dd7797f	c1	TG Salted Peanuts 400 Gm	Namkeen	Pcs.
31c18635-0047-45a6-ba30-1935d7d538d9	c1	TG Salted Pumpkin 30 Gm	Namkeen	Pcs.
0e61cdac-e83e-483f-9083-a0c1937db02c	c1	TG Salted Sunflower 30 Gm	Namkeen	Pcs.
8a728c43-3761-423f-80c0-7c75a9c84e34	c1	TG Tropical Nuts Fruits Mixed 180 Gm	Food	Pcs.
5d8331d7-24a4-400e-9472-2eba2296e571	c1	Tg Wasabi Coated Green Peas180gr	&#4; Primary	PKT
a45b9ff6-6dfa-47d9-b93c-3064aeed687e	c1	Tg Wasabi Coated Green Peas 85gr	Food	Pcs.
4e0be790-4732-4b8c-8897-5c07db6d5aca	c1	Thai Ad Water Chesnut in Syrup 565gm	Food	Pcs.
2284f328-1526-4a3d-8aec-8c3926eae5b0	c1	Thai Coco Coconut Juice with Pulp 330ml.	Drinks	Pcs.
3ae47031-9a42-4e96-8c3a-0c770ae81678	c1	Thai Coconut Milk Beverage Chocolate Flavour 280ml.	Drinks	Pcs.
6490d97c-74ae-407b-9be7-87228250a49c	c1	Thai Coconut Milk Beverage Coffee Flavour	Drinks	Pcs.
5f6038d2-b82f-43b3-84ac-df94bff80d1a	c1	Thai Coconut Milk Beverage Mango Flavour 280ml	Drinks	Pcs.
9a4b6c4c-ed93-4372-acd7-abff16033e60	c1	Thai Coconutmilk Beverage Melon Flavour 280ml	Drinks	Pcs.
bf020360-ccbc-4552-ab79-58ca61c5b096	c1	Thai Coconut Milk Beverage Orignal Flavour 280ml.	Drinks	Pcs.
5b97ec9c-9e3f-427e-9e80-404c43aaa5e7	c1	Thai Coconut Milk Beverage Strawberry Flavour 280ml	Drinks	Pcs.
458b5248-8f35-48e8-9016-3b383c57c900	c1	Thai Coconut with Pump 520 Ml	Drinks	Pcs.
682fd1ec-876a-4ac5-86f9-58ca4b86c6f3	c1	THAI GLUTINOUS RICE 2KG	Food	PKT
d4b6a60f-4577-4af2-825a-9684ab4cb197	c1	Thai Glutinous Rice 2 Kg (5%)	Food	Pcs.
b8e4eef5-8d10-4519-b90a-2d1a470efe9c	c1	THAI JASMINE RICE GOLD 2KG	&#4; Primary	Pcs.
ce59e153-734f-427a-82ec-b7fc53c0ffcf	c1	Thai Jasmine Rice Silver 2 Kg	Food	Pcs.
a1fd0553-08d3-461c-93df-4b6ce5154dae	c1	Thaina Paste	Food	Pcs.
8d31df57-09fa-4811-ac9a-f1881c0acaaf	c1	Thai Seasoning Powder 800gm.	Spices	Pcs.
272445d5-b6c1-4797-9a5a-858365b27c3b	c1	Thasia Black Pepper Sauce 170 Gm	Food	Pcs.
521a24cc-df35-4ce9-84be-fccc8f681a92	c1	Thasia Hot Chilli Sauce 170 Gm	Food	Pcs.
9ddb18c7-efd8-4669-bdfd-bea3dbd06408	c1	Thasia Rice Vermicelli 200 Gm	Food	Pcs.
4cfdd621-7f81-4231-b647-8357ca0be830	c1	Thasia Sriracha Chilli Sauce 170 Gm	Food	Pcs.
f46debb9-b410-4d1d-9114-3f1b3ee0c327	c1	Thasia Sweet &amp; Sour Sauce 180 Gm	Food	Pcs.
61e1ad14-005d-45bb-b882-198b64ee000e	c1	Thasia Thai Sweet Chilli Sauce 180 Gm	Food	Pcs.
1fe9d953-849a-41fd-bb11-5e4fd43eaacf	c1	Thermocol Box Large	Box	Pcs.
1778ee7f-fc99-4a4c-a129-9af5b9d92d10	c1	THERMOMETER DIKING IFRARED	Electrical Goods	Pcs.
07bca5d4-cf05-47ba-9eca-82d9c34296c7	c1	Thumps Up 1.25 Ltr Pet	Drinks	Pcs.
6ac8084a-5748-4bdb-a2ad-a012fe6ee038	c1	Thumps Up 2.25ltr	Drinks	Pcs.
d7f93e2d-2cc4-4077-8200-960daf92c59e	c1	Tiffany Toffee	Food	Pcs.
9393b586-9b7f-4e76-a05a-a199e282986c	c1	Tiffany Wafer Biscuits 150gm	Biscuts	Pcs.
41a7ed10-faca-4af7-b1ac-7039a473104d	c1	Tim Tam Gift Box 270gm.	Biscuts	Pcs.
18f49318-cd03-46bc-8b71-709c151461dd	c1	TIPAROS DIPPING Fish SAUCE 700ML.	Food	Pcs.
f7092609-7d9a-40cf-97ab-e9b4adeb0c5e	c1	TJ ANDALINI PASTA LASAGN 500G	Food	Pcs.
34f61f2f-5ab6-4cce-86c6-e99e7bc3c9cd	c1	Tj Andalini Pasta Tagila 500g.	Food	Pcs.
d2b63a64-ebe7-49bd-8186-b926de86f7a6	c1	Tj Andalini Whole Wheat  500g	Food	Pcs.
d536b577-d396-4032-8656-b2af52a34325	c1	TJ BD HR ALMOND 150GM	Namkeen	Pcs.
b61faf5a-6577-4b24-bf27-9a7925a7a9ad	c1	TJ BD RS ALMOND 150GM	Namkeen	Pcs.
94bd80fe-4165-454c-ac94-ed8220b4fc85	c1	TJ BD SH ALMOND 150GM	Namkeen	Pcs.
4dca6c6b-9850-4e41-8f08-b4b03cc14adf	c1	Tj Castilo Red	Drinks	Pcs.
cf100bf4-b79b-4a6c-9784-01ef7fd4bb56	c1	Tj Castilo White	Drinks	Pcs.
850d2060-d203-4902-9c18-a49254eaa422	c1	TJ COCONUT MILK 17% 400ML	Drinks	Pcs.
0025b051-9c9a-473a-8573-99f582655b14	c1	Tj Habit Olives Black Sliced 3kg.	Food	Pcs.
380d718b-8e4a-4edf-85e7-b693ccfe57ec	c1	Tj Habit Red Pepirika Sliced 2.9kg.	Food	Pcs.
18129a89-a3a0-4d9d-85eb-9e9d837e97d7	c1	Tj Habit Red Peprika Sliced 680g.	Food	Pcs.
9527cee9-24d6-45c0-816c-14cd05a7dd0c	c1	TJ HBT BBQ SAUCE ORG 510GM.	Food	Pcs.
565de1f6-7062-4b03-9406-3e6bd108b2d7	c1	TJ HBT BLACK PITTED 430G	Food	Pcs.
b2a73608-21c6-4aed-9007-614d10ad2297	c1	TJ HBT BREDCRUMS K005	Food	Pcs.
6f8b8fd7-a73c-4c53-b54f-d14f0911bd90	c1	TJ HBT COCONUT CRM POWDER 1K	Food	Pcs.
8afe4665-8df4-467b-adcb-bb31458327d7	c1	TJ HBT COCONUT MILK 12% 400M	Drinks	Pcs.
31c46265-42e5-46ed-89cd-d92a96227715	c1	TJ Hbt Jalapeno Slices 2.9KG	Food	Pcs.
e696d27c-c408-40ce-a773-e4f81e899b1a	c1	TJ HBT  OLIVES GREEN PITTED 430G	Food	Pcs.
d20b0265-8542-4ec4-9a0d-fd371b183646	c1	Tj Hbt Olives Green Sliced 3kg.	Food	Pcs.
87637c18-9c33-4d56-921b-00a9f7f4f91b	c1	Tj HBT Pasta  Farfille 500gm	Food	Pcs.
d2377c1b-75e5-42b0-8ab7-0d87507342d5	c1	Tj HBT Pasta Fussili 500g	Food	Pcs.
d6458d3b-a782-4ae7-b43c-9cf6079d0251	c1	TJ HBT PASTA PANNE 500GM	Food	Pcs.
da645fc2-86a5-4d22-a969-bad49254c485	c1	TJ HBT SILVER SKIN ONIONS 350G	Food	Pcs.
0653ada6-e029-4428-8131-abab98e00598	c1	TJ KARA COCONUT WATER 250ML.	Drinks	Pcs.
c7c5ad0e-5fb7-4fb9-b06c-01bf1e309ea5	c1	Tj LXP Olive Green Slice 450g	Food	Pcs.
d9044d57-8465-4426-9b5b-52e25ec301f8	c1	Tj LXP OLIVES BLACK SLICE 450G	Food	Pcs.
22b9eb6b-2736-4de5-952c-20f1f3e823c7	c1	TJ LXP OLIV GREEN PITTED 450	Food	Pcs.
e01a8003-c11c-4d3a-9763-111fea0a936b	c1	TJ MAEPRANOM SCS 390GM	Food	Pcs.
8bdae980-79ec-416f-944c-f24499313bdf	c1	TJ MAEPRANOM SWEET CHILLI 980G	Food	Pcs.
575c3bfa-3a81-4e8d-8c7d-1619eb56efa1	c1	Tj Maepronam Sweet Chilly 390 Gm (IMP)	Food	Pcs.
f1e9ed1d-0c4d-4085-9c0c-daa4d214ee86	c1	Tj Maepronam Sweet Chilly 980 Gm (Imp)	&#4; Primary	Pcs.
56fc9116-d412-4a0e-a9b7-3a2e6e968fff	c1	TJ MM BLUEBERRY FFILING 595	Food	Pcs.
34d618b1-fb87-4556-83a7-aa7b55cc5a0a	c1	TJ MM BLUEBERRY FILLING 3 KG	Food	Pcs.
0035e1c2-5bb4-4c9e-9949-0f85df9c262d	c1	TJ MM CHERRY FFILING 595	Food	Pcs.
656026ad-71ca-40cd-9e62-87043fe7cdf2	c1	TJ MM Strwaberry Fruit Filling 595g.	Food	Pcs.
4a86a5fc-a2df-445a-86f3-0bdfc1136829	c1	TJ SWEET KERNEL 410	Food	Pcs.
446c72be-3b5b-4429-8fe9-d1052a067235	c1	TJ WH PLUM SAUCE 400G	Food	Pcs.
e534e2f6-e960-47d0-9219-dab515393423	c1	TLC Light 8p	Dairy Products	Pcs.
b6f0cd23-0c17-4d31-bb24-ef1239c04cb6	c1	TLC Plain 8p	Dairy Products	Pcs.
44ffe6f0-33e4-4eac-8fda-719828165758	c1	TLC Selection 8p	Dairy Products	Pcs.
a87db7af-e47d-451d-86e5-0b34740c149a	c1	T&amp;L Sugar 500 Gm	Food	Pcs.
aa784ac9-7eef-48b4-b6dd-523b0ea3fa7d	c1	TOFU FIRM 307g	Food	Pcs.
dc29400e-6cc6-408f-9a23-9ed02566b6b2	c1	Tofu Siliken Extra Firm 349gm	Food	Pcs.
a76ce0b4-ad73-4a98-b208-79caf34c7e1a	c1	Tofu Silikon	Food	Pcs.
b35873cb-b9ae-40a5-af6f-0dae34a96b18	c1	Tomato Cremica 8*100pcs (Sachet)	Food	Pcs.
d338413b-e23f-4f1b-a341-cbe996e37b43	c1	TOM YUM400	Food	Pcs.
115d1054-edb8-4f55-961d-a175f40e56da	c1	Tongarashi(Assorted Chilli Pepper)300gm-S&amp;B	Food	Pcs.
19d8fd2b-9815-4870-a622-8646b2a4580a	c1	Tonic Water 24x1	Drinks	Pcs.
5de21c6d-9d26-42a7-afa3-9b6df0628c36	c1	TONIC WATER IMP 250 ML(28%)	Drinks	Pcs.
56f3eb92-0b93-48c9-940e-0c4704211ab3	c1	Tonkatsu Sauce 1.8 Ltr	Food	Pcs.
fa6a6e52-2c4b-4c27-9b06-2e42f5b92488	c1	Tortilla Wrap Mexikana	Food	Pcs.
5b19fc40-2386-4002-8598-f75fa722a18a	c1	TOSHI BALSAMIC GLAZE	Food	Pcs.
0f6a2d3c-9aea-46df-81d5-aab8a18d8d85	c1	Triple Elephant Black Bean Preserve 500g.	Food	Pcs.
c2f0cb04-dbe5-4077-b9ad-a54c4476fa59	c1	Triple Elephant Jasmine Rice (Brown) 2 Kg (5%)	Food	Pcs.
d2d6fd94-a861-4e06-b148-9a9701e6df93	c1	Tropical Citrus Flav 300ml.Mro.Rs.55/-	Drinks	btl.
fa482378-0cbb-4c0a-9f65-9ff24e333702	c1	Tropolite Whip Topping 1kg	Dairy Products	Pcs.
4b1745c0-57d3-4cf0-8d96-652c02c58cd4	c1	Trotilla Mexikana 8 inch	Food	PKT
83392a41-639c-4e1f-a925-a633c07e9540	c1	TRUFFLE OIL (URBANI)	Food	Pcs.
57f1ddc0-57d0-4323-9af1-308f4478e39e	c1	Truffolate Dark Choco	Food	Pcs.
a3f130aa-a307-4f50-8037-297acb24ebf2	c1	Trust Sugar Sachet White	Food	Pcs.
f2a70892-534b-4d1f-91e7-caa4de0f8046	c1	Tru Taste Bajra Mix 200g	Tru Taste	Pcs.
362c8857-675d-4089-9740-84f1cc45c1ee	c1	Tru Taste Chilly Garlic Chana 30g	Tru Taste	Pcs.
76dde0dc-19e2-47cc-ab13-84e0317ac309	c1	Tru Taste Chilly Garlic Peanut 30g	Tru Taste	Pcs.
6e7fefcd-5f72-48a0-a3bb-b661f57fb437	c1	Tru Taste Crunch Mix 200g	Tru Taste	Pcs.
f689ba6f-dc36-41a7-9979-ce9aa2d74fe1	c1	Tru Taste Desi Mix 200g	Tru Taste	Pcs.
6f1192d4-3bc1-43dc-ac02-16f3acec3f90	c1	Tru Taste Healthy Mix Black Piper 200g	Tru Taste	Pcs.
15b64dc0-282e-41cc-9eda-69dc3d63240d	c1	Tru Taste Healthy Mix Classice 200g	Tru Taste	Pcs.
f5dab7c5-eb5c-407c-8ea2-5a4b747f8cba	c1	Tru Taste Hing Jeera Chana 30g	Tru Taste	Pcs.
f18038c0-749f-4729-bc84-9b036fb2f68d	c1	Tru Taste Hing Jeera Peanut 30g	Tru Taste	Pcs.
8bd23dc5-5022-4ea3-a02b-177724e579b0	c1	Tru Taste Masala Chana 30g	Tru Taste	Pcs.
58d49523-496a-4d5c-a716-6fa41e526425	c1	Tru Taste Millet Bhel 200g	Tru Taste	Pcs.
069f3d35-cb73-4a27-a997-36b91cdaa907	c1	Tru Taste Millet Delight 200g	Tru Taste	Pcs.
2155403f-7d1b-4f43-9e0d-ec3c9c2186d4	c1	Tru Taste Millet Mix 200g	Tru Taste	Pcs.
9dc877d9-3c69-454f-a612-d974ce6185b2	c1	Tru Taste Multigrain Mix 200g	Tru Taste	Pcs.
b950b659-70bc-4484-94c3-b274789a3792	c1	Tru Taste Nimbu Pudina Chana 30g	Tru Taste	Pcs.
5e8e2dfd-d6ec-4b83-a409-91eb80975463	c1	Tru Taste Nimbu Pudina Peanut 30g	Tru Taste	Pcs.
134df573-754a-46e0-bfb6-a3da7f301ca7	c1	Tru Taste Red Current 30g	Tru Taste	Pcs.
fa09b626-07b3-497e-a82a-7af7133d6303	c1	Tru Taste Sabudana 200g	Tru Taste	Pcs.
2e3381c7-767d-47e6-97b8-7e185b4915c6	c1	Tru Taste Salted Peanut 30g	Tru Taste	Pcs.
420abda0-9ee9-4a50-956c-4cf0a06dfc32	c1	Tru Taste Teekha Meetha Mix 200g	Tru Taste	Pcs.
4a321cb0-3f4f-4540-88e8-288e8f1e802e	c1	Tulip Luncheon Meat (Pork Meat) 340 Gm	Food	Pcs.
91da422f-6060-4397-a659-e64140314231	c1	TUNA CHUNK	Food	Pcs.
7f4a0f2c-ff88-421b-ade4-519911a63801	c1	Tuna Chunk (185gm)	Food	Pcs.
614343e7-1c6d-4b17-afa9-eec205ac5ebd	c1	TUNA CHUNK IN BRINE	Food	Pcs.
6fd2945e-fc7f-4cbc-938a-5d0d1abb39f6	c1	TUNA CHUNK IN SOYABEAN OIL	Oil	Pcs.
ad13899f-397f-4b2b-9621-68e2801177e8	c1	Tuna Chunk in Spring Water	Food	Pcs.
7fea062f-66f9-4dd5-bcec-e5c3244ab077	c1	Tuna Slakes in Brine	Food	Pcs.
a53f6bb6-d5b9-41a2-bd14-56ec4646581e	c1	Tutti Frutti 1 Kg	Food	Pcs.
2f786903-19e1-4357-9da0-28a7206d5048	c1	TW CAMOMILE TB 025S	TEA	Pcs.
81594ed6-af79-4507-8828-5d03cbd468be	c1	TW Classic Assam TB HS025S	TEA	Pcs.
c20aae32-d38f-426d-a294-10f9ccb5382f	c1	TW CLASSIC ASSAM TB HS 100S Mrp.699	TEA	Pcs.
dc1236d1-cd00-4e68-af24-a318c5c46126	c1	Tw Classic Assam TB HS 200S	TEA	Pcs.
a3e0b405-8222-4aff-875d-2d9e65e64f23	c1	TW DARJEELING TB HS 025S	TEA	Pcs.
b9d688bb-7551-4fbc-a777-49099cca4908	c1	TW DARJEELING TB HS 100S	TEA	Pcs.
60cd76e0-3b75-4550-8d33-ab02a5fdc35a	c1	TW DARJEELING TB HS 200S	TEA	Pcs.
f681c9d9-66cd-4803-b2d7-d43445f3c7a4	c1	Tw Earlgreay 200tb.Rs.1200/-	TEA	Pcs.
fe3578a7-62e6-4677-bc19-b612f2b78ed9	c1	TW EARL GREY TB HS 025S	TEA	Pcs.
eb78e530-c657-469c-b204-261303f95e6e	c1	TW EARLGREY TB HS 100S	TEA	Pcs.
d4c3cf29-6a09-4ba7-96f3-045c9e82172f	c1	Tw Elichie TB-25	TEA	Pcs.
0981f7dd-b9e0-4694-b3a4-eccdeb800046	c1	Tw English Afternoon Tb-25	TEA	Pcs.
b4d02ddc-7c5a-407c-ab6b-3e8675a47175	c1	TW ENGLISH BREAK FAST TB HS 025S	TEA	Pcs.
a797f755-961f-4ce0-9d68-68da629dd30f	c1	TW ENGLISH BREAKFAST TB HS 100S Mrp.899	TEA	Pcs.
e539e932-b892-4257-abe8-120cfa503177	c1	Tw English Break Fast TB HS 200s	TEA	Pcs.
255e6b80-01b0-4b2f-b2db-6e33054d19da	c1	Tw Green Tea 025s+Lemon 05S	TEA	Pcs.
37c228ce-698d-4e8d-87a7-79eadb12ee55	c1	TW Green Tea    200 S	TEA	Pcs.
90fe0a7f-2149-400f-b66c-1f043cdc8fa4	c1	Tw Green Tea Canberry Tb 25	TEA	Pcs.
a907619b-d099-4cd9-8150-23af8412e832	c1	TW Green Tea Earlgrey TB HS 025s	TEA	Pcs.
81b86596-76ff-4f27-a381-192cef5b75fd	c1	Tw Green Tea Green Apple Tb-25	TEA	Pcs.
56a6659b-d393-4aa1-b292-a6dde97fe60d	c1	Tw Green Tea Jasmin 025s+Lemons 05s	TEA	Pcs.
0509e35e-96c9-4a49-ba7a-e39f499af163	c1	TW GREEN TEA JASMIN TB HS 025S	TEA	Pcs.
b8dba836-0232-4f25-83af-fb63352f68fa	c1	Tw Green Tea Lemon Honey025+Lemon 05s	TEA	Pcs.
3547cca1-a4bc-42f9-8050-7b305d39052b	c1	Tw Green Tea Lemon  &amp; Honey 100TB	TEA	Pcs.
16d0a879-5db0-45f9-a894-5f37d12cf64a	c1	TW GREEN TEA LEMON &amp; HONEY 25TB	TEA	Pcs.
d7e9ecd6-d4e8-4f41-bc79-64a3b99afa43	c1	Tw Green Tea Lemon+ Lemon 05s	TEA	Pcs.
cb53162e-93bd-4e9f-81a6-b5c63ecfab53	c1	TW GREEN TEA LEMON TB HS 025S	TEA	Pcs.
26797f0d-f86e-4e4d-9b3e-710ae4d05516	c1	TW Green Tea Lemon TB HS 100	TEA	Pcs.
3901a3ef-8880-49a5-8061-bb25b36515e6	c1	Tw Green Tea Mint 025s+Lemon 05S	TEA	Pcs.
3fb60155-a0b6-4722-a9fd-d76ad9ab3c9b	c1	TW Green Tea Mint TB HS 025S	TEA	Pcs.
edd70ca0-3dcd-478d-b3f8-916cd396c281	c1	Tw Green Tea Pomogrnatetb25	TEA	Pcs.
ba8143f8-484c-47a3-9ec1-0f5a648593ea	c1	Tw Green Tea Strawberry Tb 25	TEA	Pcs.
0eb241d6-8cd7-4e28-9eab-f5546443a26c	c1	TW GREEN TEA TB HS 025S	TEA	Pcs.
2aef8d4d-e160-469b-828c-69b704629028	c1	TW Green Tea TB HS 100s Mrp.999	TEA	Pcs.
cda1adab-b394-4528-8957-12f987632dc9	c1	Twining Green Tea	Food	Pcs.
6231bbd5-78e1-479e-aed5-98a75acbb623	c1	Twining Infusion Flavour Tea Bag(1x20 Bag)(18%)	TEA	Pcs.
ac2beacd-2490-499a-ae18-30bffafaba32	c1	Twisst Irish Cream (235 Ml) Mrp.250	All Items	Pcs.
200a3d80-3ba1-45ca-b10c-21d47cdf43fd	c1	Twisst Virgin Mary (135 ML) Mrp.250	All Items	Pcs.
673912af-45a7-49b3-89f7-44ee224c9be8	c1	Twix Milk Shake 350ml.	Drinks	Pcs.
93a5e7fe-a1c6-44c8-b41c-4d7b0c908cb4	c1	TW LEMON &amp; GINGER 025S	TEA	Pcs.
c3b31c94-09ac-4b3e-a47e-8b713f2d4cd9	c1	TW LEMON TB HS 025S	TEA	Pcs.
df2cbb09-eae0-48aa-9041-062da65161c5	c1	TW LEMON TB HS 100S	TEA	Pcs.
00c96fdd-3708-481e-93f0-59c5d26003d3	c1	Tw Lemon TB HS 200S	TEA	Pcs.
c69b5d7d-e572-4c8f-b805-b41f929d539e	c1	TW PEPERMINT TB 25	TEA	Pcs.
7863cdc0-e401-4a14-9695-264483c913cf	c1	Tyj Happy Belly Gyoza Skin 300gm Mrp 250	Food	Pcs.
5db41ce3-c119-4f46-949c-85ba6de28e66	c1	TYJ HAPPY BELLY LOTUS LEAF BUN 12*400 GM	Food	Pcs.
754df102-e8c9-437c-87d9-7d6e51211d07	c1	Tyj Happy Belly Wonton Skin 300 Gm Mrp.250	Food	Pcs.
da648b1d-9abc-450e-a5ae-8f20f8e05dac	c1	Tyj Spring Home Paratha Plain 325 Gm Mrp.199	Food	Pcs.
a94c84af-1773-4686-b6b9-5cb5b9eed185	c1	Tyj Spring Home Samosa Pastry 180 Gm Mrp.145	Food	Pcs.
3b744a41-79a2-4592-b83d-bbc9b9a65443	c1	Tyj Spring Home Spring Roll Pastry 400 Gm Mrp.290	Food	Pcs.
e40af2b7-d88d-4219-a16c-0b8dd63d5214	c1	Tyj Spring Home Spring Roll Pastry 550 Gm	Food	Pcs.
be0e505f-a909-4ccc-a7c6-b5f4784f21fe	c1	TYJ Spring Roll Pastry 7.5/7.5	Food	Pcs.
428b6d19-e09f-4c6e-9671-180514d8c573	c1	TYJ Spring Roll Pastry 8.5in 20*550gm	Food	Pcs.
24c10f50-b579-4f87-93de-6175cd7688e6	c1	Tyre	Electrical Goods	Pcs.
87ebb905-8c27-4c3f-a568-fc5f1337839d	c1	Udon Noodle 300g.	Food	Pcs.
a0161608-a76f-44c3-92a7-4d9e56982341	c1	Udon Noodle 300gm	Food	Pcs.
d5e16e84-5b34-4be5-aba9-639e5ca38d8b	c1	Udoon Noodle 180gm-Miyakoichi	Food	Pcs.
807a832d-9f04-4b85-8bab-62a75c77005a	c1	UFM ROYAL FAN CAKE FLOUR 1KG	Food	Pcs.
660bfa53-f883-4736-9dda-22e1aee29c3c	c1	Uncle Joes 270g.	Chocolate	Pcs.
0bf66da8-075d-4209-bf7a-ae6b958d6f22	c1	Unibic Almond Butter 67g.Rs.15/-	Biscuts	Pcs.
14e5a1df-8f2a-488b-828b-6641fb3e55da	c1	Uni Bic Almond Butter Cookies 135g Rs.34/-	Biscuts	Pcs.
03d14213-4ef6-4a19-a9e6-718849ef3c42	c1	Uni Bic ANZAC Oatmeal 135g.(P.P)	Biscuts	Pcs.
7a851984-c336-4490-8e20-691942829b52	c1	Uni Bic ANZAC Oatmeal Cookeis 135g Rs.26/-	Biscuts	Pcs.
ae774c55-e95a-4658-a45a-a899920e074e	c1	Uni Bic ANZAC Oatmeal Cookies.67g Rs.13/-	Biscuts	Pcs.
1792b1cb-98a5-49c6-be02-7593d038d589	c1	Unibic Anzec Oatmeal 30g.	Biscuts	Pcs.
31e450c9-88d2-4d2f-abb6-c37a1dfb3a4f	c1	Unibic Assortded Cookies Rs.145/	Biscuts	Pcs.
5b312f7e-1e26-45a1-9887-4f449ccbe9b7	c1	Unibic Assorted Cookies 155/	Biscuts	Pcs.
784c4a02-42c2-4661-a200-a76bdb00f2db	c1	Unibic Assorted Cookies Rs.175/	Biscuts	Pcs.
06397302-6dbf-41c6-8d6b-5a71db06ac88	c1	Unibic Assorted Cookies Rs.225/	Biscuts	Pcs.
c2afdd41-776c-43d7-a430-f0ff6be0014b	c1	Unibic Assorted Cookies Rs.60/	Biscuts	Pcs.
e6e69759-645b-4837-b68d-aa5bd5226233	c1	UniBic Butter Cookies 135g.Rs.25/-	Biscuts	Pcs.
f6d2662a-3a79-4d07-b6a8-bc35b0586d4e	c1	Unibic Butter Cookies 150g.	Biscuts	Pcs.
03c99072-79fa-4d9f-8d3f-04006bc909db	c1	Uni Bic Butter Cookies 67g. Rs.12/-	Biscuts	Pcs.
7ce1a044-68ec-44ee-9209-48917bb0da52	c1	Uni Bic Cashew Butter Cookies135g(P.P)	Biscuts	Pcs.
7ec7c354-24c5-4924-9b10-f0ecd05bbbf8	c1	Uni Bic Cashew Butter Cookies 135g. Rs.30/-	Biscuts	Pcs.
9d658fe1-75f1-4fc1-925f-1badf79e2875	c1	Uni Bic Cashew Butter Cookies 67g.Rs.15/-	Biscuts	Pcs.
991fe8bc-cad7-4644-aa2b-7529cf4d3607	c1	Unibic Chilli Butter 67g.Rs.10/-	Biscuts	Pcs.
bc504b3a-377b-4c79-8af0-b67a2b722177	c1	Uni Bic Chlt Chips Cookies 135g.	Biscuts	Pcs.
2e636096-72de-4705-8a43-bbe683724ded	c1	Unibic Chocokiss 150g.	Biscuts	Pcs.
c9ff79de-e382-4181-8405-1d89940a25d6	c1	Unibic Choco Kiss 150g.Rs.50/-	Biscuts	Pcs.
2ad73fea-5abe-4752-99c6-f3f369eabcde	c1	Uni Bic Choco Kiss 15g.Rs.5/-	Biscuts	Pcs.
d0bbc21b-024a-424e-93bd-30dd7708f178	c1	Uni Bic Choco Kiss 90g.	Biscuts	Pcs.
5e8161b6-47dc-4553-98b3-181f9328c58b	c1	Uni Bic Chocolate Chips 67g.Rs.18/-	Biscuts	Pcs.
b1c0c31b-e81e-4901-bc8b-d878a50db558	c1	Unibic Choconut 150g.	Biscuts	Pcs.
042c94e7-21c9-448f-9dab-a2f9dc0e9394	c1	Uni Bic Choconut Cokies 67g.Rs.19/-	Biscuts	Pcs.
45886bd6-04ac-46bc-b108-c297eec9693f	c1	Uni Bic Choconut Cookies 135g.	Biscuts	Pcs.
48b597f0-3c82-4bd3-90e4-50701e1e2aca	c1	Uni Bic Choconut Cookies 135g.(P.P)	Biscuts	Pcs.
b0cfe34f-c1ae-4186-a480-3ed799215571	c1	Unibic Chywanprash Cookies Rs.30/-	Biscuts	Pcs.
4b177d72-7840-454c-999b-85671d6d1924	c1	Uni Bic Double Chlt.Chips 150g.Rs.45/-	Biscuts	Pcs.
b28015b2-239f-452e-b33d-34055f05bb8d	c1	Unibic Fruit N Nut 150g.	Biscuts	Pcs.
42c51e0d-c3ae-4d27-926f-5817a3ad9fc6	c1	Uni Bic Fruit Nut 135g.	Biscuts	Pcs.
30600aab-4b6b-46cd-8e70-8f279bfc2308	c1	Uni Bic Fruit &amp; Nut Cookies 67g.Rs.15/-	Biscuts	Pcs.
364bb4d4-017b-448f-9aff-2cf4ce4f4c26	c1	Unibic Ginger Nut Cookies 135g.Rs.24/-	Biscuts	Pcs.
0f6fabc0-d5ab-4e1f-9936-c9739b652f1e	c1	Unibic Gingernut Cookies 67g.	Biscuts	Pcs.
533cc9e1-7d6f-4e63-bc1c-16f05f10b8ab	c1	Uni Bic Honey &amp; Oatmeal 150g.	Biscuts	Pcs.
c83545a2-963f-4169-beb9-0698b2114307	c1	Uni Bic Jam 150g.Rs.28/-	Biscuts	Pcs.
e932e6e5-ebc6-485e-b871-96222c72bf80	c1	Uni Bic Jam 75g.Rs.14/-	Biscuts	Pcs.
7158bc4c-ce96-4640-a739-0cddd08b1c79	c1	Unibic Jeera Butter Doosra 67g.	Biscuts	Pcs.
1038d4a4-fb97-4389-a50e-3f824d74f27a	c1	Uni Bic Milk Cookies 110g.Rs.12/-	Biscuts	Pcs.
a1906311-475c-4604-a956-a596d732a225	c1	Uni Bic Milk Cookies 225g.Rs.25/-	Biscuts	Pcs.
2fc186d5-621a-451a-a326-f19b7c68770f	c1	Unibic Milk Cookies 98g.Rs.10/-	Biscuts	Pcs.
cf77cfb6-6333-495b-adfd-e8455bcc829d	c1	Unibic Milk Cookies Rs.5/-	Biscuts	Pcs.
0ac41c5c-a1a0-49b9-993c-df79e907b1ab	c1	UNIBIC MULTIGRAIN BREAKFAST	Biscuts	Pcs.
e873ce76-038d-44f1-b1ea-d76b3327679b	c1	Unibic Multi Grain Cookies 67g.	Biscuts	Pcs.
7c50bdf2-2a19-49a0-a173-8f573373585e	c1	Uni Bic Oatmeal Dig.Cookies 100g.Rs.15/-	Biscuts	Pcs.
7f086d2d-e6f4-47bf-9291-88ada668d3fb	c1	Uni Bic Oatmeal Dig.Cookies 200g.	Biscuts	Pcs.
2d6c341d-a870-4a25-a533-03b0568dfe1f	c1	Unibic Oatmeal Digestive 75g. Rs.10/-	Biscuts	Pcs.
4e0616a1-2e8f-43c0-bfd3-002deeecae2b	c1	Unibic Pista Badam Cookies 150g.	Biscuts	Pcs.
27d22f91-81f8-428f-829b-9ec685a51da4	c1	Unibic Pista Badam Cookies 67g.	Biscuts	Pcs.
a491173a-8858-400c-bba2-0b25ad9fb9a1	c1	Uni Bic S.F. Butter 67g.Rs.25/-	Biscuts	Pcs.
44b7c4df-d38d-4f5e-8424-4fb109afd54c	c1	Unibic S.F.Butter Cookies 75g.	Biscuts	Pcs.
83b9888d-e4f1-44e9-8d26-5e1e5079cf4e	c1	Unibic S.F.Cas.Butter Cookies 75g.	Biscuts	Pcs.
4f0c66df-016c-45fc-955b-370e3a6c026b	c1	Uni Bic S.F. Cashew Butter 67g.Rs.25/-	Biscuts	Pcs.
a4c5bc49-d110-4216-8e84-59a2efd7cafc	c1	Unibic S.F.Oatmeal Cookies 75g.	Biscuts	Pcs.
23c2bec5-2ba7-403d-aa58-d68bf65f2b68	c1	Uni Bic S.F.Oatmeal Cookies Rs.25/-	Biscuts	Pcs.
b871dc4f-933c-469b-89d7-e12b69c0fd5a	c1	Unibic S.F.Orenge Cream 75g.Rs.30/-	Biscuts	Pcs.
77ca0afb-a7af-45ae-8453-cc8902a11e48	c1	Unibic S.F.Pinapple Cream 75g.Rs.30/-	Biscuts	Pcs.
38c43e02-dbfe-4a3f-910f-b7b61516647a	c1	Unibic S/free Butter 135g.Rs.50/-	Biscuts	Pcs.
e4718729-7ee5-4ef2-be0b-957ae9930f02	c1	Unibic S/free Cashew 135g.Rs.50/-	Biscuts	Pcs.
dd01ab69-8e1b-42df-b689-57d79853d53b	c1	Unibic S/free Oatmeal 135g.Rs.50/-	Biscuts	Pcs.
8b10412b-8aa5-498a-bd02-4659cfefca5e	c1	Unibic S.F.Vanila Crm.Cookies	Biscuts	Pcs.
6f62d018-6afc-4312-9b9c-b5214b0f812f	c1	Unibic Spice Butter Cookies 135g.Rs.22/-	Biscuts	Pcs.
d0088006-a5ea-471a-9fd7-b6798ae81d3d	c1	Uni Bic Spice Butter Cookies 67g.	Biscuts	Pcs.
37e939e1-3502-4d91-8834-961af1d229e9	c1	Ups Zebronic U-725	Electrical Goods	Pcs.
23e8053a-3677-4787-83a6-fdf49cde2743	c1	Uttam 1KG SUGAR MRP.60/	Food	Pcs.
50cf05fc-48da-40ed-9d25-51448581f365	c1	Uttam Breakfast Suger Super Fine 1 Kg Mrp.90	Food	Pcs.
e343ebd3-740f-44d1-8aed-e1cf2616cd57	c1	Uttam Brown Sugar 1 Kg	Food	Pcs.
f0bb17e6-8038-4691-ac76-3a9ccbd088f9	c1	Uttam Brown Sugar Sachet	Food	Pcs.
4344b129-cc8c-40b9-b05a-b1ea7b33add0	c1	UTTAM SUGAR CASTER SUGAR 1kg	Food	Pcs.
17adaf20-8ec3-4e20-b36b-b9716e43309f	c1	Uttam Sugar Cube White 500gm	Food	Pcs.
a539abd7-ce7f-4795-a187-bbedea936984	c1	Uttam Sugar Icing Sugar 1 Kg Mrp.100	Food	Pcs.
25a63c11-2571-44ba-ae26-9598f63132d7	c1	Uttam Sugar Sachet White 5gm*200*pkt	Food	Pcs.
0afeb650-f706-4849-b86b-c4b13cca541a	c1	Vatika Amla Mango Baar 15/-	Food	Pcs.
f4736f43-773b-4599-9dba-29454e412a1a	c1	Vatika Amla Pickle 200gm	Vatika Pickel	Pcs.
cad5c19a-b7fa-463c-8723-92c100753cc9	c1	Vatika Amla Pickle 250 Gm	Food	Pcs.
0261ee3e-b59b-461e-9b35-5dcf39a4d7e0	c1	Vatika Amla Pickle-500g	Food	Pcs.
4f8402a6-81e7-4c4b-884b-aef8eff28c2b	c1	Vatika Garlic Pickle 200g	Vatika Pickel	Pcs.
c0320288-57ad-4f42-95c9-0e70f9121ee1	c1	Vatika Garlic Pickle 200 Gm Mrp.130	Food	Pcs.
b8d34682-ec6b-4841-86a2-4ec153af143a	c1	Vatika Garlic Pickle-400g	Vatika Pickel	Pcs.
66f0b3b3-e791-4e28-a53d-d59dda475664	c1	Vatika Garlic Pickle-500g	Food	Pcs.
93316d57-e728-4562-bd8b-d4ecb37005cc	c1	Vatika Ginger Pickle 200 Gm	Vatika Pickel	Pcs.
4bfe0f38-6a3f-4b88-9264-5c8a14444e3c	c1	Vatika Ginger Pickle 250gm RS.112/-	Food	Pcs.
1e34b34a-6a6d-4e08-9a42-cb13c9639ad3	c1	Vatika Ginger Pickle-500g	Food	Pcs.
01a6b482-36d9-4c58-8298-be745397be0b	c1	VATIKA GREEN CHILL PICKLE 400G	Food	Pcs.
976ba47f-36fe-4154-9bb5-3fc65268c82b	c1	Vatika Green Chilly Pickle 200g	Vatika Pickel	Pcs.
c5c735ef-e802-46f7-a857-8879412dd420	c1	Vatika Green Chilly Pickle 200 Gm Mrp.70	Food	Pcs.
5c110c18-8154-4a0b-b6c3-29756b33b32d	c1	Vatika Green Chilly Pickle-400g	Vatika Pickel	Pcs.
a0aa6b6a-9e67-4be7-bfdf-ec8870e0151e	c1	Vatika Green Chilly Pickle-500g	Food	Pcs.
f074b5b7-2232-43fe-9aed-70e01af67baa	c1	Vatika Karonda Pickle 250gm	Food	Pcs.
1fca8aa7-780d-4a59-af0e-7379b1ec973d	c1	Vatika Karonda Pickle-500g	Food	Pcs.
26e7488c-dd2d-40be-8004-d0957e3047e1	c1	Vatika Kathal Pickle 200gm	Food	Pcs.
d503b434-2e4e-4b24-b9c7-2047fd619fc3	c1	Vatika Kathal Pickle 200 Gm Mrp.80	Vatika Pickel	Pcs.
407bf859-824e-4804-85a7-8076b12c8de2	c1	Vatika Kathal Pickle-500g	Food	Pcs.
2ecaf05e-e9e3-4b99-add6-b32580680952	c1	Vatika Lemon Pickle 200 Gm	Vatika Pickel	Pcs.
b50942c1-8d01-4609-91c7-28e694029043	c1	Vatika Lemon Pickle-500g	Food	Pcs.
627259eb-851c-4b7d-ba4e-ea336053ebd3	c1	Vatika Mango Pickle 200 Gm	Vatika Pickel	Pcs.
85a9dbdb-1809-49f9-8a70-24ee93ca8414	c1	Vatika Mango Pickle-400g	Vatika Pickel	Pcs.
52872407-dfef-4c4e-adf5-f664383beb19	c1	Vatika Mango Pickle-500g	Food	Pcs.
7a191c37-15a8-44cc-a4c5-fb17d98ac539	c1	Vatika Mixed Pickle 200g	Vatika Pickel	Pcs.
706b81fa-a0f9-453f-861c-53e4ccc8711a	c1	Vatika Mixed Pickle 250gmRS,63/-	Food	Pcs.
368703ad-eb45-4cc3-b039-b04504b16220	c1	Vatika Mixed Pickle-400g	Vatika Pickel	Pcs.
20c65f65-26a6-40a7-a0fc-fe040c0d141c	c1	Vatika Mixed Pickle-400g 190 Mrp	Food	Pcs.
afb9c976-4f16-4c9f-b0f7-cc8ea761d455	c1	Vatika Mixed Pickles -400g	Food	Pcs.
fbdb1f81-1e04-4db7-8eab-605ec438ddbf	c1	Vatika Mix Fruit Trey 110g	Food	Pcs.
4a424cee-cb57-4a3c-8742-66b87cff519e	c1	Vatika Pickle Mini Tray-180g.	Food	Pcs.
643b1430-178d-4d22-b75a-6a680954347a	c1	Vatika Red Chilly Pickle 200gm	Vatika Pickel	Pcs.
eefaa13f-d2ee-46e2-970d-5fa0081111fd	c1	Vatika Red Chilly Pickle 200 Gm Mrp.100	Food	Pcs.
a578975c-854a-44f5-ad20-dad610a1f0a8	c1	Vatika Red Chilly Pickle -400G	Vatika Pickel	Pcs.
c18f868f-5e8d-4449-a399-915f82bc677d	c1	Vatika Sweet Mango Pickle 200gm	Vatika Pickel	Pcs.
6fbcc172-d5c6-4abf-9660-c69565b06cff	c1	Vatika Zimikand Pickle 200 Gm Mrp.100	Food	Pcs.
8f9e7e0a-b718-446c-9979-2be59d951909	c1	Vatika Zimikand Pickle 250 Gm	Food	Pcs.
a70182b2-5046-4a79-8772-c2cebeae2599	c1	Vatika Zimikand Pickle-500g	Food	Pcs.
18cca9e7-97a3-42aa-bd4b-216cda9892da	c1	VB-Professional Chocolate Topping 1.3 Kg	Chocolate	Pcs.
eb808649-7ddf-4621-903d-ec45872c5b2b	c1	Vb Srirach Sauce	Food	kg.
ab5d3315-ca93-4db8-a34c-a72072fa891d	c1	VB White Cheese Drassing 1kg.	Dairy Products	Pcs.
9d5b2d31-a152-41d4-8966-0114c28c902a	c1	Veeba Amrican Mustard Souce 310gm.Rs,99/-	Food	Pcs.
df07bb92-c5db-4dfc-ad96-1ef7b2672a64	c1	Veeba Barbeque Sauce 330gm.Rs.119/-	Food	Pcs.
bcfe3f24-5cee-455c-863f-055e73f73dd8	c1	Veeba Caesar Dressing 300gm. Rs.119/-	Food	Pcs.
32635a7c-92aa-46a3-91f5-b7e0394e9d4c	c1	Veeba Chipotle Southwest Dressing Rs.139/-	Food	Pcs.
f2196e02-cf72-4c10-884e-9550749e0b0d	c1	Veeba Eggless Mayo 1kg	Food	Pcs.
89322ab6-fb9b-45d4-b205-e7c0616eede7	c1	VEEBA EGGLESS MAYONNIES PROFESSIONAL	Food	Pcs.
08e0b35c-4610-4971-ad2e-da45e588e77e	c1	VEEBA EGGLESS MAYO PROFESSIONAL 1KG	Food	Pcs.
6fffdde8-9174-4e84-a367-52cb4d1ba888	c1	Veeba Garlic Chilli Spread &amp; Dip	Food	Pcs.
30f12cf5-494c-4ac5-af6f-faf8eb90eff3	c1	VEEBA GREEN CHILI SAUCE SACHET (8G)	Food	Pcs.
6a294449-cdd7-42e3-9a47-7d6fc2c73695	c1	Veeba Honey Mustard Dressing.300gm. Rs.139/-	Food	Pcs.
59034981-0a95-4408-b125-ea95176488b8	c1	Veeba Mint Mayinnaise 300gm. Rs.139/-	Food	Pcs.
50e220a9-bf88-4e79-ab46-022f87494b05	c1	Veeba Olive Oil Mayonnaise 300gm. Rs.139/-	Food	Pcs.
e91cdaf0-3f32-461b-883c-ccb4b82bc09a	c1	Veeba Pasta and Pizza Sauce	Food	Pcs.
fc527ffa-9760-4451-9f8a-10d72c71082e	c1	Veeba Peanut Butter 925 Gm	Food	Pcs.
8bc82983-541e-48a6-8910-f280891a8e78	c1	Veeba Ranch Dressing 300gm. Rs.139/-	Food	Pcs.
48f17d5c-46ba-4fd5-927f-38680b97a6a0	c1	Veeba Sweet Onion Souce Rs.119/-	Food	Pcs.
77afb075-669c-4295-899e-c2fa39ab925b	c1	Veeba Thousand Island Dressing 300gm. Rs.119/-	Food	Pcs.
2ee23a8c-8044-4803-9a2e-764b621da26a	c1	Veeba Tomato Ketchup Sachet 1*10	Food	Pcs.
09756962-b00d-46f5-a8ec-834828241dca	c1	VEEBA TOMATO KETCHUP SACHET-8 GM	Food	PKT
33d8c110-a144-49e0-b01a-951a4740fb2d	c1	VEEBA TOMATO KETCHUP TASTY PIXEL 1.2KG	Food	Pcs.
e71d5616-49cf-4cdd-a106-d23e806e7072	c1	Veeba Vinaigrette Dressing 320gm.Rs.99/-	Food	Pcs.
3c8dbb61-cd36-4e46-b12b-47b04c2cd9e1	c1	Veeba White Chees Dressing	Food	Pcs.
f77d0da2-119c-4325-93c4-5fa2eed81fe8	c1	Vegetable Cream Cracker 570g Tin	Biscuts	Pcs.
a5c1ec4d-3e14-4b45-91e5-fca7e7c3e373	c1	Veg Green Curry Paste 1 Kg	Food	Pcs.
03d90def-4cbd-4a61-af87-f07daf066fb9	c1	VEG MARSHMELLOW	Food	Pcs.
23f6f827-8147-456d-840c-a54e5c1f0d28	c1	Viander Peel Tomato 2.5 Kg	Food	Pcs.
70350264-08e1-44cd-af74-95f7c13400fc	c1	Vicks Digital Tharmameter V901in	Cosmatics	Pcs.
bbf24a20-bf44-46c3-87f8-40540bf6fed4	c1	Vidal Sass Premium Base Care Cn.190g.	Cosmatics	Pcs.
ef1e1b8f-4620-4af7-bb49-a1dc0412eb00	c1	Vidal Sass Premium Base Care Sh.500ml.Rs.675/-	Cosmatics	Pcs.
131623e9-8ea1-447e-a5d2-00167fec3e3e	c1	VIMTO CARBONATED CAN 250ML.	JUICE	Pcs.
9b520cc8-e2cc-4a8b-a0d0-2fcfdbc8de6b	c1	VIMTO FRUIT DRINK PET 250ML.	JUICE	Pcs.
8034c9cc-7dd6-4f23-b5df-d04eff828776	c1	VINEGAR APPLE CIDER16604-AG 473 ML.	Drinks	Pcs.
53b6305e-eea5-43fc-851f-c03ca5924bf5	c1	VINEGER	Drinks	Pcs.
4ab2fb62-98ea-4004-9374-fc64aea76037	c1	Viva Basil 500gm	Food	Pcs.
f757604a-f72d-4d22-96e4-6f4b4fca191c	c1	Viva Chilly Flakes Jar 70gm	Food	Pcs.
526ea642-0170-4bc0-805f-2cb8f572f5cd	c1	Viva Italia Chilly Flakes 1kg	Food	Pcs.
ed488adb-2e4d-4257-975e-68a6ca4f80ec	c1	VIVA ITALIAN OREGANO REGULAR 1KG	Food	Pcs.
000b9465-d9de-4bc6-9615-705c84d4e118	c1	Viva Oregano Jar 40gm	Food	Pcs.
3b03ea1d-c954-4f14-8ac2-a5725a3d777a	c1	VIVA OREGANO PREMIUM HERB 1KG	Food	Pcs.
0803bc61-d9a1-44ff-bb63-4c862b5d88e7	c1	Viva Oregano Seasoning 1kg	Food	Pcs.
e274e7dc-8b56-4ba7-b827-0cd43fe6a1ce	c1	Viva Oregano Seasoning 75 Gm Jar	Food	Pcs.
391f1a37-9aa8-490b-adc2-a3d0ddebff93	c1	Viva Oregano Seasoning Jar 75gm	Food	Pcs.
b029ca96-9813-4a8f-b016-1bd849b3fc5d	c1	Viva Thyme 1 Kg	Food	Pcs.
7ba737b7-bbec-4721-bc6d-b23d3dcdf84c	c1	VKL Peri Peri Marinade 1*10 Kg.	Food	Pcs.
f6ac01be-7f1f-4314-801e-b58cc1b321d8	c1	Voila Black Rice 500 Gm	Food	Pcs.
7ab67738-ba15-48cb-9422-69e2e389c3fb	c1	Voila Frozen Blueberry 1kg	Food	Pcs.
fbd630c9-bf61-45a6-bad7-b0fcf975a07c	c1	Voila Frozen Raspberry 1kg	Food	Pcs.
39e7f078-f9cc-4f37-8998-816d6a74cf5f	c1	Voila Frozen Strawberry 1kg	Food	Pcs.
a10c553a-197c-4ec1-adc9-bd91ed81bd09	c1	Voila Ginger Pickled 1720g	Food	Pcs.
e347fcb2-9a28-40f7-9140-7b1dfa248053	c1	Voila Gluten Free Atta 2 Kg (5%)	Food	Pcs.
41fe48d7-d085-4144-8c14-f01f5332ec7b	c1	Voila Marukome White Miso Paste 1 Kg	Food	Pcs.
be195de5-5617-46bf-9554-43c25af3d8f3	c1	Voila Spring Roll Sheet Green Tea 7.5&quot; 550g	Food	Pcs.
62bbe1b1-0554-4307-a482-564317dd09e2	c1	Voila Spring Roll Sheet Turmeric 7.5&quot; 550g	Food	Pcs.
2362910d-ab08-496b-a525-e37c29d3d441	c1	Voila Sushi Rice 1kg	Food	Pcs.
ede348ef-27aa-4dd5-900d-902e205d8922	c1	Voila Teritaki Sauce 400g	Food	Pcs.
fb9b0adb-4f7b-4619-80dd-a3c297e73c5e	c1	Voila Tofu (Soyabean Curd) 300g	Food	Pcs.
76931857-0eeb-43eb-babc-3138e8870ff1	c1	Voila Wasabi Powder-1kg	Food	Pcs.
08c036c0-d480-4ae3-ab31-4056a0359607	c1	WAFER Biscuits 150g.	Biscuts	Pcs.
10e566d9-e38b-4bc8-855e-f5581f4f09dd	c1	Waffar Bissin Cocoa 100g.	Biscuts	Pcs.
a7ab49f4-1686-487f-80f1-c0dcf846de01	c1	Waffele Chips Classic	Biscuts	Pcs.
0ef0762d-1aff-42e7-8361-470712793533	c1	Waffle Chcolate 100gm.	Biscuts	Pcs.
044f9aff-c599-4a9d-a135-21f29ebc4a30	c1	Waffle Dark Chocolate 100gm.	Biscuts	Pcs.
2bcb3fbc-3d55-4e8d-9c8b-2f7122084d23	c1	Waffle Sea Salt Chips 100gm.	Biscuts	Pcs.
a67c70b1-824b-46db-85af-579afce0d785	c1	Waffle White Chocolate 100gm.	Biscuts	Pcs.
f76b15db-6ccb-44f7-86fc-3284793cf8ac	c1	Walna Tempura Flour 700 G	Food	Pcs.
e8b614f1-b294-463a-b8f3-93e805c969a7	c1	Walnut Milk Matcha Green Tea 1 Ltr	Drinks	Pcs.
34b038af-d2f0-46e1-a110-eb4c3aa613f5	c1	Walnut Patti 300g	GURU FOOD	Pcs.
8f6f3cb1-2a3a-4764-859a-ee5246e548fe	c1	Wasabi Paste SAKURA 100G*43G	Food	Pcs.
7fae787a-384b-483b-986e-b9beb031403c	c1	WASABI POWDER YOKA 1 KG	Food	Pcs.
e5604402-e685-400d-b317-12ed5a0ded44	c1	Wasuka Chocolate 15g.Bar20x6	Chocolate	Pcs.
0f11fa98-4070-41dd-80bb-300f5fd0cd03	c1	Waterchestnut 552gm.-First Choice	Food	Pcs.
2ae312d4-f704-4b37-b8c7-1bdf92ad8b9b	c1	Weetabix	Food	Pcs.
10afc42e-dd10-4fa1-9414-fa586ea5a70c	c1	Wella 4/6	Cosmatics	Pcs.
f2e1f96b-b484-4464-b99e-07b3a13e2055	c1	Wella Dcore 3/0	Cosmatics	Pcs.
eae0eca8-321e-4b2a-9884-22a0f43607d5	c1	Wella Decor	Cosmatics	Pcs.
c5555fd1-92dc-400c-9479-2203796b30fb	c1	Wella Decore 5/0	Cosmatics	Pcs.
ecb5f018-f65e-4252-9181-63a92b980840	c1	Wella Straite Normal	Cosmatics	Pcs.
f7b66571-16dc-43a2-a084-e5ac66c6d874	c1	Wella Straite Strong	Cosmatics	Pcs.
f17509e8-b131-4865-aac3-beea20bad7f8	c1	Wheat Starch / Roquette / 1 Kg	Food	kg.
bda45668-4a0c-482d-b471-c0aff1168292	c1	Wheat Starch(YOKA)	Food	Pcs.
0811e5ec-7107-4971-959f-5d19c1fcba15	c1	Whipping Cream 200ml (Elle &amp; Vire)	Food	Pcs.
3a471d68-08c6-4373-a8eb-b412c7d41283	c1	Whipping Cream 250gm	Dairy Products	Pcs.
f579d168-7409-4492-a286-1bb239f110bb	c1	White Castle 681g.	Biscuts	Pcs.
a5801459-f688-4df9-8488-24ca0abf28a5	c1	White Fungus 500g.	Food	Pcs.
2c13ca7e-81cd-4300-959a-9dba7f6465fb	c1	White Fungus (Dried Veg) 1 Kg (12%)	Food	Pcs.
79ea3636-d372-4cd6-a225-cd526f0fbbfe	c1	White Sirika 620ml.	Drinks	btl.
c71dce03-cdd7-4940-b6ee-de0d48eff152	c1	WHITE SUGAR  SACHET	Food	Pcs.
9f0640cd-6773-414a-9569-20f8b58531b3	c1	White Sugar Sachet (Case)	Food	case
3fe4a77b-4200-40c7-a2c9-6655d744082b	c1	Yowe Seasme Oil	Food	Pcs.
547a6102-0a0a-4cb7-b955-4d04586f1941	c1	White Wine Venegar 1 Ltr.(Varvello)	Drinks	Pcs.
d277686f-4b8a-40a3-8e6d-9289e363a112	c1	WHITE WINE VINEGER PET (1 LTR)	Drinks	btl.
d03b4a3f-f444-4607-b695-d0897c33f67d	c1	WH Khidri Dates Pouch (500 Gm) Mrp.699	All Items	Pcs.
2b65fb95-65ed-433b-bfcc-fa86269778b0	c1	WH Medjool Dates Pouch (500 Gm) Mrp.999	All Items	Pcs.
db190103-87dd-40a4-ad66-dc13d629417e	c1	Whole Kernel  410gm*24	Food	Pcs.
2b24a963-8eaa-456e-aea7-57b0151c4317	c1	WH Segai Dates Pouch (500 Gm) Mrp.899	All Items	Pcs.
44f5d2b0-c6b6-49e0-a4f6-a841a6e96e9f	c1	WH Sukkary Dates Pouch (500 Gm) Mrp.899	All Items	Pcs.
2ef838f3-f959-4e22-a877-0f77310fed2b	c1	Wild Kick Tropical Citrus 300ml	Drinks	btl.
87557eb1-7e10-42fc-bef6-082c14851d46	c1	Wild Sunshine Orange Mango 300 Ml	Drinks	btl.
3b4b8d7e-450f-4f82-8f9b-abc00656c0bb	c1	WOH HUP BLACK BEAN SAUCE 340GR	Food	Pcs.
5699cbe5-3cbb-4342-a67b-03bc5932ec14	c1	WOH HUP Black Pepper Sauce 340 Gm	Food	Pcs.
02ea0be2-ef27-47bd-879c-51512f3cd5e9	c1	Woh Hup Hoisin Sauce 350 Gm	Food	Pcs.
56fbb30b-ee80-4a0e-ac99-0c4885d9c1e4	c1	WOH HUP Hot Szechuan Sauce Paste 310 Gm	Food	Pcs.
aeddb877-bff5-4582-bb25-492ab0f00668	c1	WOH HUP KUNG PO SAUCE 335GM	Food	Pcs.
3e07f5ac-d9ff-451b-b251-4b103f4c0ebc	c1	Woh Hup Mermaid Oyester Sauce 480 Gm	Food	Pcs.
f7253d17-202a-48e9-a2a6-a0b4d2c523d3	c1	Woh Hup Plum Sauce 400 Gm	Food	Pcs.
0d6bfce5-07cf-4eba-9351-737638333cca	c1	Woh Hup Premium Dark Soya Sauce 775 Gm	Food	Pcs.
510002e1-ac64-4360-963d-b620e46b59db	c1	Woh Hup Premium Light Soya Sauce 730 Gm	Food	Pcs.
0abd6c2d-8d0a-4fb2-9f83-9084a465d2e1	c1	Woh Hup Sambal Oelek 320gm	Food	btl.
d7bcb747-6432-431a-b8ad-f365fb80b24f	c1	Woh Hup Singapore Laksa Paste 190gm	Food	Pcs.
6442d7ef-da6a-4a24-a0bd-9ef0f462ba9b	c1	Woh Hup Spicy Black Been Sauce 340 Gm	Food	Pcs.
cb89b960-f3c4-4694-bdba-9a1a1502fa7b	c1	WOH UP Black Bean Sauce 340 Gm	Food	Pcs.
10a4bb6a-c17f-41f1-828d-e562f3f2e2f2	c1	Wyke Colour Cheddar (5kg)	Dairy Products	kg.
eb0772d0-6ee4-4869-8506-02ae3ceacde7	c1	XCENT  DEO-FIRDAUS	Deo	Pcs.
5fe14545-191a-44f7-b56f-6a7e0a0effcd	c1	XCENT DEO- FLAME	Deo	Pcs.
602010ad-809c-4180-85a2-90ee48a7599e	c1	XCENT DEO- ICE COOL	Deo	Pcs.
dce4331f-1b4e-40a5-805c-9611a3eb0749	c1	XCENT-DEO KHUS	Deo	Pcs.
3fab2e4c-e842-4551-a1d4-564acad89e3a	c1	XCENT DEO-LAGOON	Deo	Pcs.
e6e4a4e8-bae9-4651-b2bc-03e2d0179d1d	c1	XCENT DEO-MUKHALLAT	Deo	Pcs.
eb5973e6-b46c-4c02-a73a-ae807205e68b	c1	XCENT DEO- OUDH	Deo	Pcs.
f9476763-3848-4b8f-840c-78805cdbcb27	c1	XCENT DEO ROSE	Deo	Pcs.
002f252b-622d-428c-ba3d-5c6a78382e24	c1	XCENT DEO- SEA BREEZE	Deo	Pcs.
5479a5ed-c31e-4700-8785-d5db3ac68366	c1	XCENT DEO- SHADOW	Deo	Pcs.
59fad7e9-2c68-4622-a22c-98bfb14f058a	c1	XIPAGODA BRAND SESAMEOIL 600ML	Oil	Pcs.
a7260298-9c9c-43c1-ab0f-e69d3a437cee	c1	XL R8 Deo 150ml. Rs.175/-	Deo	Pcs.
d1eff5f4-b614-4c34-a25e-b92d2270cdc0	c1	Xlr8 DEO ACTIV (150ml)	Deo	Pcs.
e9a2cd59-99f2-444b-85a6-32e5b71d2e2e	c1	XLR8 Deo Electric 150ml.	Deo	Pcs.
164584cf-22b5-4d0f-97cc-112a884e7d60	c1	Xlr8 Deo Instinct (150ml)	Deo	Pcs.
26832904-887a-4926-82ff-4eda6a5f1322	c1	Xlr8 Deo Oasis (150ml)	Deo	Pcs.
a9ddbf65-6067-409e-92f9-483f9312fec7	c1	Xlr8 Deo Pro (150ml)	Deo	Pcs.
67cda8ee-4a36-4b2d-befb-24e94dce5d27	c1	Xlr8 Deo Pure (150ml)	Deo	Pcs.
aa68c94a-9d90-4643-b14b-20f75ff566f2	c1	Xlr8 Deo Rage (150ml)	Deo	Pcs.
d4b822bc-393c-4ec3-87dc-54f7b6755a62	c1	Xlr8 Deo Sharp (150ml)	Deo	Pcs.
73dcd259-f00b-40d8-956d-8ce852811332	c1	Xlr8 Deo Sizzie (150ml)	Deo	Pcs.
d8efb0b8-2fb4-4e38-971e-bc46057d336c	c1	Yabarra E V Olive Oil 500ml.	Oil	Pcs.
e546a07c-a286-45d0-a647-0672516dcce5	c1	Yabbra Oliv Oil 1ltr Pure	Oil	Pcs.
021a2a1d-1015-47d4-aded-d60c12bee28d	c1	Yabbra Oliv Oilo 1ltr.E.V.	Oil	Pcs.
3045d7dc-a3b5-46e9-9b8d-e5076f0ed0ed	c1	YAKI Noori Roasted Seaweed	Food	Pcs.
de81a194-1274-41ee-bcce-5a599408d510	c1	Yaki Noori Seaweed (10pcs*40)	Food	Pcs.
ab1f5957-08c9-40a1-8e5a-c921bd4f3b55	c1	Yaki Sushi Yaki Nori 10 Sheet 28gm	Food	Pcs.
2254ea08-e838-461f-9e62-ed10edd859b6	c1	YAKITORI SAUCE 150ML.(ENSO)	Food	Pcs.
1e5c0556-8653-43d3-be6d-dad05a40edb4	c1	YELLO FARM EDAM VEGES 200 GM	Dairy Products	Pcs.
7f38d67a-976f-43b3-a7ce-768873c1c849	c1	Yellow Cheddar (Cremeitalia )1 Kg	Food	kg.
f1c2b618-2335-475a-b9f2-b8f2dcf89199	c1	YELLOW CURRY POWDER 200 GM WAUGHS	Food	btl.
9bf07d66-2cc7-45de-bed1-83b161f6de39	c1	Yellow Farm Emmenthai-200gm	Dairy Products	Pcs.
74d169ee-0c06-41e2-a2cd-ff536084caca	c1	Yellow Farms Gauda Classic- 180gm	Dairy Products	Pcs.
d4a5c26a-2dec-463c-b1d0-ac155866fa53	c1	Yellow Mustered Classicc	Food	Pcs.
03ac668e-0767-4901-865f-c330717f1221	c1	Yoka Bamboo Chopsticks	Food	Pcs.
bf3ab628-5cfa-4642-aeae-9ed1e87ea051	c1	YOKA BRAND SUSHI VINEGAR (1.8 LTR *6)	Oil	Pcs.
c7c40e68-1138-489f-be62-6945aa296940	c1	Yoka Glutinous Rice 1 Kg (5%)	Food	Pcs.
50f6db93-6194-4d33-954a-f5ef4273f334	c1	Yoka Pink Sushi Ginger 900g	Food	Pcs.
b80db4e2-9815-4759-a1cc-a867125692ac	c1	Yoka Rice Vinegar 625ml (18%)	Food	Pcs.
952474cf-3fc8-4ca0-ad6e-1fca3d14ece2	c1	Yoka Shitake Dried Mushroom 1kg	Food	Pcs.
87b69c3c-082a-43fd-8b71-bf7c4f7baa54	c1	Yoka Sushi Rice 1 Kg (5%)	Food	Pcs.
aeb34cd0-91c5-48fc-a1a6-c1488155c4f6	c1	Yoka Sushi Vinegar 1.8ltr	Food	Pcs.
96ed5c49-fc2b-4aa6-af4d-86f90d8abb98	c1	Yoka Sushi Vinegar 500 Ml	Food	Pcs.
da6c1aa3-4d54-4b72-8b3c-5b912cf7257a	c1	YOKA Tempura Batter Mix 1 Kg	Food	Pcs.
4bf3385d-5fe5-4731-b9d0-d1177b5c44ba	c1	YOKA Toasted Sesame Seed Oil	Oil	Pcs.
49cdf0a8-933e-44a3-873e-3e1fae9f87b0	c1	Yoka Wasabi Powder 1 Kg.	Food	Pcs.
9f6a2261-88f9-4734-b66c-0b849d6e9885	c1	Yokoso Jasmine Tea 227 Gm	Food	Pcs.
4f06e029-672c-4ec9-96e1-1a4d1ef0b924	c1	Yokoso Soba Noodle 300 Gm	Food	Pcs.
50c10645-2897-4a37-ae69-6d3123ef5d23	c1	Yokoso Udon Noodle 300 Gm	Food	Pcs.
6fc1be4d-68a6-4e52-8e3f-80264c7e576b	c1	Yokoso Wasabi Paste 43 Gm	Food	Pcs.
1a2fdea7-b87b-47ef-bcb6-57cb2f18fe72	c1	Yo-Pop	Namkeen	Pcs.
0618d47d-6544-4b43-b1b8-ecb3af151a1d	c1	Yun Yun Cup Noodells 70g.	Food	Pcs.
339751f7-6a13-44d8-90a2-6262b777c222	c1	Yun Yun Noodells 60g.	Food	Pcs.
78f11ac7-0e0e-4126-9d10-ac15693c4527	c1	Yun Yun Noodells 70g.	Food	Pcs.
71105f04-70b6-4d1e-95bf-5960d6b6039d	c1	Zaatar Powder 500g	Food	Pcs.
f9d487eb-d600-45a5-bfa2-8132a03abbb5	c1	Zenko Granola Chocolate Trail Mix 300g	SHS GLOBAL	Pcs.
f8f8c498-db00-4092-bde2-10406852f2db	c1	Zenko Granola Golden Honey Crunch 300g	SHS GLOBAL	Pcs.
c402c81b-4a2b-49e5-b59d-02b9eff2305a	c1	Zenko Granola Tropical Fruit Mix 300g	SHS GLOBAL	Pcs.
b7f0496a-e96f-4d8f-ac56-f12ec1d8a3df	c1	Zero Sugar Lemonade Flav 300ml. Rs.55/-	Drinks	btl.
e9952718-15c4-4cbb-84b2-01efd6bd6822	c1	Zimi All Purpose Fillo Pastry Sheet 454 Gm Mrp.550	Food	Pcs.
43aaf7d8-0b44-455f-a596-c67aa4495e43	c1	Zogo Dry BD Large	Sanatry Napkin	Pcs.
fca08219-cdb7-41a1-8a1a-c23be5d7cf68	c1	Zogo Dry BD Med.	Sanatry Napkin	Pcs.
eff26cc6-743b-46f7-bfa4-e3da6134c58e	c1	Zogo Dry BD Small 38	Sanatry Napkin	Pcs.
160b334d-0ee9-45e7-a539-a7e4da14968a	c1	Zogo Dry BD x-Large	Sanatry Napkin	Pcs.
58aedcef-6915-4bd0-9a64-84794b46ad3d	c1	ZP Almond Maricle Coffee (1 Pc) - Pack of 12 Pcs	Drinks	Pcs.
0d96e3c1-6c6d-45e5-9de0-574c0fad4270	c1	ZP Almond Miracle(1 Pc) - Pack of 12 Pcs	Drinks	Pcs.
0782026b-d986-4221-aee0-91a686a0e0af	c1	ZP Almond Miracle Box-3pcs	Food	Pcs.
7cac1a93-c02a-45dd-9c05-06ab8b187826	c1	ZP Almond Miracle Brownie (1 Pc) - Pack of 12 Pcs	Drinks	Pcs.
76da9c32-70be-4ee7-a43e-93621178657d	c1	ZP Almond Miracle Brownie Box-3pcs	Food	Pcs.
d6ea990e-3626-4e0f-9f0a-cd891fb984f4	c1	ZP Almond Miracle Coffee Box-3pcs	Drinks	Pcs.
2a19c00a-4d36-4c83-adeb-3339d773ecc7	c1	ZP Berry Nuts 200 Gm Mrp.380	Food	Pcs.
79f4c6d6-e584-4908-bfdd-f05270b9b92e	c1	ZP Black Raisins Afghani Seedless 200Gms	Food	Pcs.
e6cb64da-c606-428d-9cf6-e01739fa84fa	c1	ZP Blueberry 150 Gm Mrp.480	Food	Pcs.
e761bc74-e967-42a1-8a01-9d0c0b00dd7b	c1	ZP Butter Cookies 350 Gm Mrp.350 (18%)	Food	Pcs.
610eb9a5-a534-4629-87fe-d7e72d919708	c1	ZP Cheese &amp; Chilly Foxnuts	Food	Pcs.
ed91ee0b-7c5a-4d7c-83eb-b07bc89aa3ab	c1	ZP Cheese &amp; Herbs Foxnuts	Food	Pcs.
a2a0ab82-6ad9-4174-861a-8bf370820dfd	c1	ZP Cranberries 200 Gm Mrp.290	Food	Pcs.
935aa9e5-5728-47fe-a233-c6f0d7940a7e	c1	ZP Dried Mangoes Dehydrated 200 Gm Mrp.340	Food	Pcs.
465bf3fa-5f2c-480e-8963-a61fc88da172	c1	ZP Dried Strawberries 200 Gm Mrp.340	Food	Pcs.
70a96a93-e6a0-420e-bc45-5ea3da8c0b40	c1	ZP Dries Kiwi Dehydrated 200 Gm Mrp.290	Food	Pcs.
3b2d5616-9b7a-4f23-828a-7c583060ad52	c1	ZP Fusion Barries 200	Food	Pcs.
ebb7f5b8-d737-4d8f-9034-af792412541d	c1	ZP GREEN RAISINS AFGHANI 200GMS	Food	Pcs.
bbf3f06a-2c74-4c7f-b479-cc5e4a251ff3	c1	ZP Mix Fruits Dehydrated 200 Gm Mrp.340	Food	Pcs.
3cd88700-7f2a-4bcc-908e-4747229a8c1c	c1	ZP Peri Peri Foxnuts	Food	Pcs.
9b5f1b05-031d-4768-a478-c0502a850ca3	c1	ZP Pineapple Dried &amp; Sliced 200 Gm Mrp.380	Food	Pcs.
4002db31-d732-4f7c-b37c-5200709d1d96	c1	ZP Pistachio Akbari 200 Gms	Food	Pcs.
d389bc2e-9654-43fa-9213-dbaaafe2fa57	c1	ZP Prunes 200 Gms	Food	Pcs.
ff572e87-3b2d-4078-b3c2-0eb86e1af0f2	c1	ZP Pudina Punch Foxnuts	Food	Pcs.
9c518335-ef38-49c2-84b6-79c2dc751c3e	c1	ZP Salted Almond 200 Gms	Food	Pcs.
3645ed4f-31da-43e7-b217-e810bb102a9b	c1	ZP Salted Cashew 200 Gm Mrp.380	Food	Pcs.
7eced945-c8d3-471f-831e-a0e688895ffd	c1	ZP Seeds and Berries 200 Gms	Food	Pcs.
20a43fbc-5960-43bf-8418-96a1c9e1ca62	c1	ZP Tangy Tomato Foxnuts	Food	Pcs.
26db6827-5cc0-4790-9f8d-886aaed51c18	c1	ZP Wafer Cubes - Cuppuccino100 Gms	Drinks	Pcs.
\.


--
-- Data for Name: StockUnitCache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockUnitCache" (id, "companyId", name, symbol) FROM stdin;
b8f69157-aed6-4d07-abf6-80e8a58eddfd	c1	BAG	BAG
74d8b60d-8f7c-445f-b0f2-68190535a41f	c1	BOX	BOX
eda9d819-fb6f-4891-a330-1d3696adb0e0	c1	btl.	btl.
7e44ed14-7c5f-456b-9a67-53068a350e4b	c1	CAN	CAN
1dd1a222-792a-4557-816b-38eeaba4fe26	c1	CAR	CAR
ccb02880-8517-42c9-aa3c-6fa04f96a7ad	c1	case	case
c2f4f2e2-0730-4714-8b8d-a58d1c869923	c1	jar	jar
93706164-759a-443c-b98c-2cf682712628	c1	kg.	kg.
879c9bd1-4c9b-462d-9423-e47a5c4675bd	c1	ltr	ltr
1dc41077-0212-4fd9-be5a-e45ade20193b	c1	Pcs.	Pcs.
9586e717-206d-46ab-a119-db297b57c8ab	c1	Pcs. of 480 CAR	Pcs. of 480 CAR
850b9a38-d01a-4853-aa10-c25a419376c7	c1	Pcs. of 60 CAR	Pcs. of 60 CAR
3251700a-beac-4098-97e8-ead3c0bd0f51	c1	PKT	PKT
\.


--
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."User" (id, name, email, "passwordHash", role, "companyId", "createdAt") FROM stdin;
cmo3d4rt500001avfxn9uabms	Admin	admin@tallysync.com	$2a$10$2Zwde9nYUsRXHJ9wOXd53eeWpYnuQEovYNddh/t9Mww1ykO4hH8z2	ADMIN	\N	2026-04-17 20:30:42.377
cmo3d4rw200021avfrnvd9qec	Sharma Groceries	groceries@sharma.com	$2a$10$QcmV1DSAktYCVs7hCpglfetIFhWJMSukoldUKk40VtUN4LVT9u1YS	COMPANY	c1	2026-04-17 20:30:42.482
cmo3d4rym00041avf4s4kflnk	Electronics Hub	accounts@ehub.in	$2a$10$fB29s7uGqSmkdF5/izoLIOh3CW3YLvNqtRHvOHuMipL3R2EMcv/J.	COMPANY	c2	2026-04-17 20:30:42.574
cmo3d4s1700061avfbezaoe12	Raj Pharma	raj@pharmastore.com	$2a$10$tllG0HxsWedkpsqEU6LSPOeU7l4zFrVqTmnH.DOzb8LNTDhiIjOAW	COMPANY	c3	2026-04-17 20:30:42.667
\.


--
-- Name: Bill Bill_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Bill"
    ADD CONSTRAINT "Bill_pkey" PRIMARY KEY (id);


--
-- Name: Company Company_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Company"
    ADD CONSTRAINT "Company_pkey" PRIMARY KEY (id);


--
-- Name: LedgerCache LedgerCache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LedgerCache"
    ADD CONSTRAINT "LedgerCache_pkey" PRIMARY KEY (id);


--
-- Name: LineItem LineItem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LineItem"
    ADD CONSTRAINT "LineItem_pkey" PRIMARY KEY (id);


--
-- Name: StockGroupCache StockGroupCache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockGroupCache"
    ADD CONSTRAINT "StockGroupCache_pkey" PRIMARY KEY (id);


--
-- Name: StockItemAlias StockItemAlias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockItemAlias"
    ADD CONSTRAINT "StockItemAlias_pkey" PRIMARY KEY (id);


--
-- Name: StockItemCache StockItemCache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockItemCache"
    ADD CONSTRAINT "StockItemCache_pkey" PRIMARY KEY (id);


--
-- Name: StockUnitCache StockUnitCache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockUnitCache"
    ADD CONSTRAINT "StockUnitCache_pkey" PRIMARY KEY (id);


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- Name: Company_email_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Company_email_key" ON public."Company" USING btree (email);


--
-- Name: LedgerCache_companyId_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LedgerCache_companyId_name_key" ON public."LedgerCache" USING btree ("companyId", name);


--
-- Name: StockGroupCache_companyId_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "StockGroupCache_companyId_name_key" ON public."StockGroupCache" USING btree ("companyId", name);


--
-- Name: StockItemAlias_companyId_billItemName_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "StockItemAlias_companyId_billItemName_key" ON public."StockItemAlias" USING btree ("companyId", "billItemName");


--
-- Name: StockItemCache_companyId_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "StockItemCache_companyId_name_key" ON public."StockItemCache" USING btree ("companyId", name);


--
-- Name: StockUnitCache_companyId_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "StockUnitCache_companyId_name_key" ON public."StockUnitCache" USING btree ("companyId", name);


--
-- Name: User_email_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "User_email_key" ON public."User" USING btree (email);


--
-- Name: Bill Bill_companyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Bill"
    ADD CONSTRAINT "Bill_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES public."Company"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: LedgerCache LedgerCache_companyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LedgerCache"
    ADD CONSTRAINT "LedgerCache_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES public."Company"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: LineItem LineItem_billId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LineItem"
    ADD CONSTRAINT "LineItem_billId_fkey" FOREIGN KEY ("billId") REFERENCES public."Bill"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: StockGroupCache StockGroupCache_companyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockGroupCache"
    ADD CONSTRAINT "StockGroupCache_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES public."Company"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: StockItemAlias StockItemAlias_companyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockItemAlias"
    ADD CONSTRAINT "StockItemAlias_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES public."Company"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: StockItemAlias StockItemAlias_stockItemCacheId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockItemAlias"
    ADD CONSTRAINT "StockItemAlias_stockItemCacheId_fkey" FOREIGN KEY ("stockItemCacheId") REFERENCES public."StockItemCache"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: StockItemCache StockItemCache_companyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockItemCache"
    ADD CONSTRAINT "StockItemCache_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES public."Company"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: StockUnitCache StockUnitCache_companyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockUnitCache"
    ADD CONSTRAINT "StockUnitCache_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES public."Company"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: User User_companyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES public."Company"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict IitSqFQLgO541XGHEL6ReyDxafaVrL0obemGPBsN3H4xdKMr9UbxlyMimeBUEgc

