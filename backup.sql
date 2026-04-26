--
-- PostgreSQL database dump
--

\restrict 4h2RaokzEl0Y0zLUJPOSW8cVUKDbadAiharQqMb3oWlLALyqaYtIUMHdkbWFUfv

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
    "billType" text DEFAULT 'purchase'::text NOT NULL,
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
    email text,
    port integer DEFAULT 9000 NOT NULL,
    mapping jsonb,
    "voucherCounter" integer DEFAULT 0 NOT NULL,
    "syncTimestamps" jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."Company" OWNER TO postgres;

--
-- Name: CompanyFeature; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CompanyFeature" (
    id text NOT NULL,
    "companyId" text NOT NULL,
    feature text NOT NULL,
    enabled boolean DEFAULT false NOT NULL
);


ALTER TABLE public."CompanyFeature" OWNER TO postgres;

--
-- Name: GodownCache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."GodownCache" (
    id text NOT NULL,
    "companyId" text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."GodownCache" OWNER TO postgres;

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
    "enterpriseName" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."User" OWNER TO postgres;

--
-- Name: UserCompany; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."UserCompany" (
    id text NOT NULL,
    "userId" text NOT NULL,
    "companyId" text NOT NULL,
    "isDefault" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."UserCompany" OWNER TO postgres;

--
-- Data for Name: Bill; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Bill" (id, "companyId", "billNumber", "vendorName", "vendorGstin", "buyerGstin", "billDate", subtotal, "cgstAmount", "sgstAmount", "igstAmount", "totalAmount", status, "billType", "imageUrl", "originalData", "isEdited", "rawAiJson", "tallyXml", "tallyMapping", "roundOffAmount", "syncedAt", "syncError", "createdAt", "updatedAt") FROM stdin;
b_1777197318515	cmofl3ut6000hmjdmwqd3dziu	SSM/25-26/01438	S S Marketing	09ABTFS7998B1Z8	\N	2026-02-23	608161.7	54734.55	54734.55	0	717631	SYNCED	purchase	\N	{"billDate": "2026-02-23", "subtotal": 608161.7, "lineItems": [{"unit": "KG", "amount": 154822.2, "gstRate": 18, "hsnCode": "72142090", "quantity": 2990, "unitPrice": 51.78, "description": "HSD Bar (TMT) (8MM-550)", "discountPercent": null}, {"unit": "KG", "amount": 351060.8, "gstRate": 18, "hsnCode": "72142090", "quantity": 7010, "unitPrice": 50.08, "description": "HSD Bar (TMT) (10-12 MM-550)", "discountPercent": null}, {"unit": "KG", "amount": 102278.7, "gstRate": 18, "hsnCode": "72142090", "quantity": 2070, "unitPrice": 49.41, "description": "HSD Bar (TMT) (10-12 MM-550)", "discountPercent": null}], "billNumber": "SSM/25-26/01438", "buyerGstin": "09AEKPJ6707K1Z3", "cgstAmount": 54734.55, "igstAmount": 0, "sgstAmount": 54734.55, "vendorName": "S S Marketing", "totalAmount": 717631, "vendorGstin": "09ABTFS7998B1Z8", "roundOffAmount": 0.2, "invoiceDiscountAmount": null}	t	null	<?xml version="1.0" encoding="utf-8"?>\n<ENVELOPE>\n  <HEADER>\n    <TALLYREQUEST>Import Data</TALLYREQUEST>\n  </HEADER>\n  <BODY>\n    <IMPORTDATA>\n      <REQUESTDESC>\n        <REPORTNAME>Vouchers</REPORTNAME>\n        <STATICVARIABLES>\n          <SVCURRENTCOMPANY>Rajeev Traders (2024-2025) - (from 1-Apr-25)</SVCURRENTCOMPANY>\n        </STATICVARIABLES>\n      </REQUESTDESC>\n      <REQUESTDATA>\n        <TALLYMESSAGE xmlns:UDF="TallyUDF">\n          <VOUCHER VCHTYPE="PURCHASE GST" ACTION="Create" OBJVIEW="Invoice Voucher View">\n            <DATE>20260426</DATE>\n            <VOUCHERNUMBER>SSM/25-26/01438_1</VOUCHERNUMBER>\n            <REFERENCEDATE>20260223</REFERENCEDATE>\n            <VOUCHERTYPENAME>PURCHASE GST</VOUCHERTYPENAME>\n            <PARTYLEDGERNAME>S S MARKETING</PARTYLEDGERNAME>\n            <PARTYMAILINGNAME>S S MARKETING</PARTYMAILINGNAME>\n            <REFERENCE>SSM/25-26/01438</REFERENCE>\n            <VCHENTRYMODE>Item Invoice</VCHENTRYMODE>\n            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>\n            <ISINVOICE>Yes</ISINVOICE>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>HSD BAR (TMT)</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>51.78/M.T.</RATE>\n              <AMOUNT>-154822.2</AMOUNT>\n              <ACTUALQTY> 2990 M.T.</ACTUALQTY>\n              <BILLEDQTY> 2990 M.T.</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-154822.2</AMOUNT>\n                <ACTUALQTY> 2990 M.T.</ACTUALQTY>\n                <BILLEDQTY> 2990 M.T.</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>IGST</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-154822.2</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>HSD BAR (TMT)</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>50.08/M.T.</RATE>\n              <AMOUNT>-351060.8</AMOUNT>\n              <ACTUALQTY> 7010 M.T.</ACTUALQTY>\n              <BILLEDQTY> 7010 M.T.</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-351060.8</AMOUNT>\n                <ACTUALQTY> 7010 M.T.</ACTUALQTY>\n                <BILLEDQTY> 7010 M.T.</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>IGST</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-351060.8</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>HSD BAR (TMT)</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>49.41/M.T.</RATE>\n              <AMOUNT>-102278.7</AMOUNT>\n              <ACTUALQTY> 2070 M.T.</ACTUALQTY>\n              <BILLEDQTY> 2070 M.T.</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-102278.7</AMOUNT>\n                <ACTUALQTY> 2070 M.T.</ACTUALQTY>\n                <BILLEDQTY> 2070 M.T.</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>IGST</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-102278.7</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>S S MARKETING</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>Yes</ISPARTYLEDGER>\n              <AMOUNT>717631</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>CGST</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-54734.55</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>SGST</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-54734.55</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <ROUNDTYPE>Normal Rounding</ROUNDTYPE>\n              <LEDGERNAME>ROUNDED OFF</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-0.2</AMOUNT>\n              <ROUNDLIMIT> 1</ROUNDLIMIT>\n            </LEDGERENTRIES.LIST>\n          </VOUCHER>\n        </TALLYMESSAGE>\n      </REQUESTDATA>\n    </IMPORTDATA>\n  </BODY>\n</ENVELOPE>	{"cgstLedger": "CGST", "sgstLedger": "SGST", "vendorLedger": "S S MARKETING", "purchaseLedger": "IGST"}	0.2	2026-04-26 09:56:19.696	\N	2026-04-26 09:55:18.515	2026-04-26 09:56:19.753
b_1777197585382	cmofl3ut6000hmjdmwqd3dziu	SSM/25-26/01438	S S Marketing	09ABTFS7998B1Z8	\N	2026-02-23	608161.7	54734.55	54734.55	0	717631	PARSED	misc	\N	{"billDate": "2026-02-23", "subtotal": 608161.7, "lineItems": [{"unit": "Nos", "amount": 154822.2, "gstRate": 0, "hsnCode": "", "quantity": 1, "unitPrice": 154822.2, "description": "HSD Bar (TMT) (8MM-550)", "discountPercent": null}, {"unit": "Nos", "amount": 351060.8, "gstRate": 0, "hsnCode": "", "quantity": 1, "unitPrice": 351060.8, "description": "HSD Bar (TMT) (10-12 MM-550)", "discountPercent": null}, {"unit": "Nos", "amount": 102278.7, "gstRate": 0, "hsnCode": "", "quantity": 1, "unitPrice": 102278.7, "description": "HSD Bar (TMT) (10-12 MM-550)", "discountPercent": null}], "billNumber": "SSM/25-26/01438", "buyerGstin": "09AEKPJ6707K1Z3", "cgstAmount": 54734.55, "igstAmount": 0, "sgstAmount": 54734.55, "vendorName": "S S Marketing", "totalAmount": 717631, "vendorGstin": "09ABTFS7998B1Z8", "roundOffAmount": 0.2, "invoiceDiscountAmount": null}	f	\N	\N	\N	0.2	\N	\N	2026-04-26 09:59:45.382	2026-04-26 09:59:45.407
b_1777197881172	cmofl3ut6000hmjdmwqd3dziu	SSM/25-26/01438	S S Marketing	09ABTFS7998B1Z8	\N	2026-02-23	608161.7	54734.55	54734.55	0	717631	SYNCED	purchase	\N	{"billDate": "2026-02-23", "subtotal": 608161.7, "lineItems": [{"unit": "KG", "amount": 154822.2, "gstRate": 18, "hsnCode": "72142090", "quantity": 2990, "unitPrice": 51.78, "description": "HSD Bar (TMT) (8MM-550)", "discountPercent": null}, {"unit": "KG", "amount": 351060.8, "gstRate": 18, "hsnCode": "72142090", "quantity": 7010, "unitPrice": 50.08, "description": "HSD Bar (TMT) (10-12 MM-550)", "discountPercent": null}, {"unit": "KG", "amount": 102278.7, "gstRate": 18, "hsnCode": "72142090", "quantity": 2070, "unitPrice": 49.41, "description": "HSD Bar (TMT) (10-12 MM-550)", "discountPercent": null}], "billNumber": "SSM/25-26/01438", "buyerGstin": "09AEKPJ6707K1Z3", "cgstAmount": 54734.55, "igstAmount": 0, "sgstAmount": 54734.55, "vendorName": "S S Marketing", "totalAmount": 717631, "vendorGstin": "09ABTFS7998B1Z8", "roundOffAmount": 0.2, "invoiceDiscountAmount": null}	t	null	<?xml version="1.0" encoding="utf-8"?>\n<ENVELOPE>\n  <HEADER>\n    <TALLYREQUEST>Import Data</TALLYREQUEST>\n  </HEADER>\n  <BODY>\n    <IMPORTDATA>\n      <REQUESTDESC>\n        <REPORTNAME>Vouchers</REPORTNAME>\n        <STATICVARIABLES>\n          <SVCURRENTCOMPANY>Rajeev Traders (2024-2025) - (from 1-Apr-25)</SVCURRENTCOMPANY>\n        </STATICVARIABLES>\n      </REQUESTDESC>\n      <REQUESTDATA>\n        <TALLYMESSAGE xmlns:UDF="TallyUDF">\n          <VOUCHER VCHTYPE="PURCHASE GST" ACTION="Create" OBJVIEW="Invoice Voucher View">\n            <DATE>20260426</DATE>\n            <VOUCHERNUMBER>SSM/25-26/01438_2</VOUCHERNUMBER>\n            <REFERENCEDATE>20260223</REFERENCEDATE>\n            <VOUCHERTYPENAME>PURCHASE GST</VOUCHERTYPENAME>\n            <PARTYLEDGERNAME>S S MARKETING</PARTYLEDGERNAME>\n            <PARTYMAILINGNAME>S S MARKETING</PARTYMAILINGNAME>\n            <REFERENCE>SSM/25-26/01438</REFERENCE>\n            <VCHENTRYMODE>Item Invoice</VCHENTRYMODE>\n            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>\n            <ISINVOICE>Yes</ISINVOICE>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>HSD BAR (TMT)</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>51.78/M.T.</RATE>\n              <AMOUNT>-154822.2</AMOUNT>\n              <ACTUALQTY> 2990 M.T.</ACTUALQTY>\n              <BILLEDQTY> 2990 M.T.</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-154822.2</AMOUNT>\n                <ACTUALQTY> 2990 M.T.</ACTUALQTY>\n                <BILLEDQTY> 2990 M.T.</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>PURCHASE</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-154822.2</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>HSD BAR (TMT)</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>50.08/M.T.</RATE>\n              <AMOUNT>-351060.8</AMOUNT>\n              <ACTUALQTY> 7010 M.T.</ACTUALQTY>\n              <BILLEDQTY> 7010 M.T.</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-351060.8</AMOUNT>\n                <ACTUALQTY> 7010 M.T.</ACTUALQTY>\n                <BILLEDQTY> 7010 M.T.</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>PURCHASE</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-351060.8</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>HSD BAR (TMT)</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>49.41/M.T.</RATE>\n              <AMOUNT>-102278.7</AMOUNT>\n              <ACTUALQTY> 2070 M.T.</ACTUALQTY>\n              <BILLEDQTY> 2070 M.T.</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-102278.7</AMOUNT>\n                <ACTUALQTY> 2070 M.T.</ACTUALQTY>\n                <BILLEDQTY> 2070 M.T.</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>PURCHASE</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-102278.7</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>S S MARKETING</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>Yes</ISPARTYLEDGER>\n              <AMOUNT>717631</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>CGST</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-54734.55</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>SGST</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-54734.55</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <ROUNDTYPE>Normal Rounding</ROUNDTYPE>\n              <LEDGERNAME>ROUNDED OFF</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-0.2</AMOUNT>\n              <ROUNDLIMIT> 1</ROUNDLIMIT>\n            </LEDGERENTRIES.LIST>\n          </VOUCHER>\n        </TALLYMESSAGE>\n      </REQUESTDATA>\n    </IMPORTDATA>\n  </BODY>\n</ENVELOPE>	{"cgstLedger": "CGST", "sgstLedger": "SGST", "vendorLedger": "S S MARKETING", "purchaseLedger": "PURCHASE"}	0.2	2026-04-26 10:04:58.963	\N	2026-04-26 10:04:41.172	2026-04-26 10:04:59.23
b_1777199938773	cmofmpqxp0000tms4st6fcb8x	53	VAM ADVERTISING & MARKETING (P) LTD.	09AACCV0313J1ZI	\N	2026-04-08	6000	150	150	0	6300	SYNCED	misc	\N	{"billDate": "2026-04-08", "subtotal": 6000, "lineItems": [{"unit": "Nos", "amount": 6000, "gstRate": 0, "hsnCode": "", "quantity": 1, "unitPrice": 6000, "description": "Publication/Edition - Amarujala- Kanpur, Date: 27/Mar/2026, Size: 10x8 sq.cm, Rate: 75.00", "discountPercent": null}], "billNumber": "53", "buyerGstin": "09ABKCS8865P1Z2", "cgstAmount": 150, "igstAmount": 0, "sgstAmount": 150, "vendorName": "VAM ADVERTISING & MARKETING (P) LTD.", "totalAmount": 6300, "vendorGstin": "09AACCV0313J1ZI", "roundOffAmount": null, "invoiceDiscountAmount": null}	t	null	<?xml version="1.0" encoding="utf-8"?>\n<ENVELOPE>\n  <HEADER>\n    <TALLYREQUEST>Import Data</TALLYREQUEST>\n  </HEADER>\n  <BODY>\n    <IMPORTDATA>\n      <REQUESTDESC>\n        <REPORTNAME>Vouchers</REPORTNAME>\n        <STATICVARIABLES>\n          <SVCURRENTCOMPANY>S D Z FOOD PRODUCTS PRIVATE LIMITED</SVCURRENTCOMPANY>\n        </STATICVARIABLES>\n      </REQUESTDESC>\n      <REQUESTDATA>\n        <TALLYMESSAGE xmlns:UDF="TallyUDF">\n          <VOUCHER VCHTYPE="Purchase" ACTION="Create" OBJVIEW="Invoice Voucher View">\n            <DATE>20260426</DATE>\n            <VOUCHERNUMBER>53_4</VOUCHERNUMBER>\n            <REFERENCEDATE>20260408</REFERENCEDATE>\n            <VOUCHERTYPENAME>Purchase</VOUCHERTYPENAME>\n            <PARTYLEDGERNAME>Vam Advertising  &amp; Marketing Pvt Ltd. ( Creditor )</PARTYLEDGERNAME>\n            <PARTYMAILINGNAME>Vam Advertising  &amp; Marketing Pvt Ltd. ( Creditor )</PARTYMAILINGNAME>\n            <REFERENCE>53</REFERENCE>\n            <VCHENTRYMODE>Accounting Invoice</VCHENTRYMODE>\n            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>\n            <ISINVOICE>Yes</ISINVOICE>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>ADVERTISEMENT EXP @5%</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-6000</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>Vam Advertising  &amp; Marketing Pvt Ltd. ( Creditor )</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>Yes</ISPARTYLEDGER>\n              <AMOUNT>6300</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>INPUT CGST 2.5%</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-150</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>INPUT SGST 2.5%</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-150</AMOUNT>\n            </LEDGERENTRIES.LIST>\n          </VOUCHER>\n        </TALLYMESSAGE>\n      </REQUESTDATA>\n    </IMPORTDATA>\n  </BODY>\n</ENVELOPE>	{"cgstLedger": "INPUT CGST 2.5%", "sgstLedger": "INPUT SGST 2.5%", "vendorLedger": "Vam Advertising  & Marketing Pvt Ltd. ( Creditor )", "purchaseLedger": "Purchase 5%"}	\N	2026-04-26 10:41:46.364	Ledger &apos;Vam Advertising &amp;amp; Marketing Pvt Ltd. ( Creditor )&apos; does not exist!	2026-04-26 10:38:58.773	2026-04-26 10:41:46.432
b_1777200253059	cmofmpqxp0000tms4st6fcb8x	53	VAM ADVERTISING & MARKETING (P) LTD.	09AACCV0313J1ZI	\N	2026-04-08	6000	150	150	0	6300	PARSED	misc	\N	{"billDate": "2026-04-08", "subtotal": 6000, "lineItems": [{"unit": "Nos", "amount": 6000, "gstRate": 0, "hsnCode": "", "quantity": 1, "unitPrice": 6000, "description": "Publication/Edition - Amarujala - Kanpur, Date: 27/Mar/2026, Size: 10x8 sq.cm, Rate: 75.00", "discountPercent": null}], "billNumber": "53", "buyerGstin": "09ABKCS8865P1Z2", "cgstAmount": 150, "igstAmount": 0, "sgstAmount": 150, "vendorName": "VAM ADVERTISING & MARKETING (P) LTD.", "totalAmount": 6300, "vendorGstin": "09AACCV0313J1ZI", "roundOffAmount": null, "invoiceDiscountAmount": null}	f	\N	\N	\N	\N	\N	\N	2026-04-26 10:44:13.059	2026-04-26 10:44:13.071
b_1777201686406	cmofmpqxp0000tms4st6fcb8x	53	VAM ADVERTISING & MARKETING (P) LTD.	09AACCV0313J1ZI	\N	2026-04-08	6000	150	150	0	6300	ERROR	misc	\N	{"billDate": "2026-04-08", "subtotal": 6000, "lineItems": [{"unit": "Nos", "amount": 6000, "gstRate": 0, "hsnCode": "", "quantity": 1, "unitPrice": 6000, "description": "Publication/Edition - Amarujala- Kanpur, Date: 27/Mar/2026, Size: 10x8 sq.cm, Rate: 75.00", "discountPercent": null}], "billNumber": "53", "buyerGstin": "09ABKCS8865P1Z2", "cgstAmount": 150, "igstAmount": 0, "sgstAmount": 150, "vendorName": "VAM ADVERTISING & MARKETING (P) LTD.", "totalAmount": 6300, "vendorGstin": "09AACCV0313J1ZI", "roundOffAmount": null, "invoiceDiscountAmount": null}	t	null	<?xml version="1.0" encoding="utf-8"?>\n<ENVELOPE>\n  <HEADER>\n    <TALLYREQUEST>Import Data</TALLYREQUEST>\n  </HEADER>\n  <BODY>\n    <IMPORTDATA>\n      <REQUESTDESC>\n        <REPORTNAME>Vouchers</REPORTNAME>\n        <STATICVARIABLES>\n          <SVCURRENTCOMPANY>S D Z FOOD PRODUCTS PRIVATE LIMITED</SVCURRENTCOMPANY>\n        </STATICVARIABLES>\n      </REQUESTDESC>\n      <REQUESTDATA>\n        <TALLYMESSAGE xmlns:UDF="TallyUDF">\n          <VOUCHER VCHTYPE="Purchase" ACTION="Create" OBJVIEW="Invoice Voucher View">\n            <DATE>20260426</DATE>\n            <VOUCHERNUMBER>53_6</VOUCHERNUMBER>\n            <REFERENCEDATE>20260408</REFERENCEDATE>\n            <VOUCHERTYPENAME>Purchase</VOUCHERTYPENAME>\n            <PARTYLEDGERNAME>Vam Advertising &amp; Marketing Pvt Ltd. ( Creditor )</PARTYLEDGERNAME>\n            <PARTYMAILINGNAME>Vam Advertising &amp; Marketing Pvt Ltd. ( Creditor )</PARTYMAILINGNAME>\n            <REFERENCE>53</REFERENCE>\n            <VCHENTRYMODE>Accounting Invoice</VCHENTRYMODE>\n            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>\n            <ISINVOICE>Yes</ISINVOICE>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>ADVERTISEMENT EXP @5%</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-6000</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>Vam Advertising &amp; Marketing Pvt Ltd. ( Creditor )</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>Yes</ISPARTYLEDGER>\n              <AMOUNT>6300</AMOUNT>\n            </LEDGERENTRIES.LIST>\n          </VOUCHER>\n        </TALLYMESSAGE>\n      </REQUESTDATA>\n    </IMPORTDATA>\n  </BODY>\n</ENVELOPE>	{"vendorLedger": "Vam Advertising & Marketing Pvt Ltd. ( Creditor )"}	\N	\N	Tally exception: a ledger name may not exist in Tally, or the voucher type is not configured. Open the browser console (F12) to see the full Tally response and verify your CGST/SGST ledger names match exactly.	2026-04-26 11:08:06.406	2026-04-26 11:10:11.75
b_1777202033396	cmofmpqxp0000tms4st6fcb8x	164	GANPATI GRAPHICS	09AAHFG1073A1ZU	\N	2026-04-10	36205	905.13	905.13	0	38015	SYNCED	purchase	\N	{"billDate": "2026-04-10", "subtotal": 36205, "lineItems": [{"unit": "pcs", "amount": 9805, "gstRate": 5, "hsnCode": "48191010", "quantity": 740, "unitPrice": 13.25, "description": "Carton 400x280x255 (Sd Khari)", "discountPercent": null}, {"unit": "pcs", "amount": 26400, "gstRate": 5, "hsnCode": "48191010", "quantity": 2200, "unitPrice": 12, "description": "CARTON-445X227X280-SD COOKIES", "discountPercent": null}], "billNumber": "164", "buyerGstin": "09ABKCS8865P1Z2", "cgstAmount": 905.13, "igstAmount": 0, "sgstAmount": 905.13, "vendorName": "GANPATI GRAPHICS", "totalAmount": 38015, "vendorGstin": "09AAHFG1073A1ZU", "roundOffAmount": -0.26, "invoiceDiscountAmount": null}	t	null	<?xml version="1.0" encoding="utf-8"?>\n<ENVELOPE>\n  <HEADER>\n    <TALLYREQUEST>Import Data</TALLYREQUEST>\n  </HEADER>\n  <BODY>\n    <IMPORTDATA>\n      <REQUESTDESC>\n        <REPORTNAME>Vouchers</REPORTNAME>\n        <STATICVARIABLES>\n          <SVCURRENTCOMPANY>S D Z FOOD PRODUCTS PRIVATE LIMITED</SVCURRENTCOMPANY>\n        </STATICVARIABLES>\n      </REQUESTDESC>\n      <REQUESTDATA>\n        <TALLYMESSAGE xmlns:UDF="TallyUDF">\n          <VOUCHER VCHTYPE="Purchase" ACTION="Create" OBJVIEW="Invoice Voucher View">\n            <DATE>20260426</DATE>\n            <VOUCHERNUMBER>164_7</VOUCHERNUMBER>\n            <REFERENCEDATE>20260410</REFERENCEDATE>\n            <VOUCHERTYPENAME>Purchase</VOUCHERTYPENAME>\n            <PARTYLEDGERNAME>M/S GANPATI GRAPHICS</PARTYLEDGERNAME>\n            <PARTYMAILINGNAME>M/S GANPATI GRAPHICS</PARTYMAILINGNAME>\n            <REFERENCE>164</REFERENCE>\n            <VCHENTRYMODE>Item Invoice</VCHENTRYMODE>\n            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>\n            <ISINVOICE>Yes</ISINVOICE>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>CORRUGATED BOX B RUSK PRINTED</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>13.25/PCS</RATE>\n              <AMOUNT>-9805</AMOUNT>\n              <ACTUALQTY> 740 PCS</ACTUALQTY>\n              <BILLEDQTY> 740 PCS</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-9805</AMOUNT>\n                <ACTUALQTY> 740 PCS</ACTUALQTY>\n                <BILLEDQTY> 740 PCS</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>Purchase 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-9805</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <ALLINVENTORYENTRIES.LIST>\n              <STOCKITEMNAME>CORRUGATED BOX CUSTOM</STOCKITEMNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <RATE>12/PCS</RATE>\n              <AMOUNT>-26400</AMOUNT>\n              <ACTUALQTY> 2200 PCS</ACTUALQTY>\n              <BILLEDQTY> 2200 PCS</BILLEDQTY>\n              <BATCHALLOCATIONS.LIST>\n                <GODOWNNAME>Main Location</GODOWNNAME>\n                <BATCHNAME>Primary Batch</BATCHNAME>\n                <AMOUNT>-26400</AMOUNT>\n                <ACTUALQTY> 2200 PCS</ACTUALQTY>\n                <BILLEDQTY> 2200 PCS</BILLEDQTY>\n              </BATCHALLOCATIONS.LIST>\n              <ACCOUNTINGALLOCATIONS.LIST>\n                <LEDGERNAME>Purchase 5%</LEDGERNAME>\n                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n                <LEDGERFROMITEM>No</LEDGERFROMITEM>\n                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n                <ISPARTYLEDGER>No</ISPARTYLEDGER>\n                <AMOUNT>-26400</AMOUNT>\n              </ACCOUNTINGALLOCATIONS.LIST>\n            </ALLINVENTORYENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>M/S GANPATI GRAPHICS</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>Yes</ISPARTYLEDGER>\n              <AMOUNT>38015</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>INPUT CGST 2.5%</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-905.13</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>INPUT SGST 2.5%</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-905.13</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <ROUNDTYPE>Normal Rounding</ROUNDTYPE>\n              <LEDGERNAME>R/OFF</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>0.26</AMOUNT>\n              <ROUNDLIMIT> 1</ROUNDLIMIT>\n            </LEDGERENTRIES.LIST>\n          </VOUCHER>\n        </TALLYMESSAGE>\n      </REQUESTDATA>\n    </IMPORTDATA>\n  </BODY>\n</ENVELOPE>	{"cgstLedger": "INPUT CGST 2.5%", "sgstLedger": "INPUT SGST 2.5%", "vendorLedger": "M/S GANPATI GRAPHICS", "purchaseLedger": "Purchase 5%"}	-0.26	2026-04-26 11:15:26.505	\N	2026-04-26 11:13:53.396	2026-04-26 11:15:26.54
b_1777201972911	cmofmpqxp0000tms4st6fcb8x	53	VAM ADVERTISING & MARKETING (P) LTD.	09AACCV0313J1ZI	\N	2026-04-08	6000	150	150	0	6300	ERROR	misc	\N	{"billDate": "2026-04-08", "subtotal": 6000, "lineItems": [{"unit": "Nos", "amount": 6000, "gstRate": 0, "hsnCode": "", "quantity": 1, "unitPrice": 6000, "description": "Publication/Edition - Amarujala - Kanpur, Date: 27/Mar/2026, Size: 10x8 sq.cm, Rate: 75.00", "discountPercent": null}], "billNumber": "53", "buyerGstin": "09ABKCS8865P1Z2", "cgstAmount": 150, "igstAmount": 0, "sgstAmount": 150, "vendorName": "VAM ADVERTISING & MARKETING (P) LTD.", "totalAmount": 6300, "vendorGstin": "09AACCV0313J1ZI", "roundOffAmount": null, "invoiceDiscountAmount": null}	t	null	<?xml version="1.0" encoding="utf-8"?>\n<ENVELOPE>\n  <HEADER>\n    <TALLYREQUEST>Import Data</TALLYREQUEST>\n  </HEADER>\n  <BODY>\n    <IMPORTDATA>\n      <REQUESTDESC>\n        <REPORTNAME>Vouchers</REPORTNAME>\n        <STATICVARIABLES>\n          <SVCURRENTCOMPANY>S D Z FOOD PRODUCTS PRIVATE LIMITED</SVCURRENTCOMPANY>\n        </STATICVARIABLES>\n      </REQUESTDESC>\n      <REQUESTDATA>\n        <TALLYMESSAGE xmlns:UDF="TallyUDF">\n          <VOUCHER VCHTYPE="Purchase" ACTION="Create" OBJVIEW="Invoice Voucher View">\n            <DATE>20260426</DATE>\n            <VOUCHERNUMBER>53_8</VOUCHERNUMBER>\n            <REFERENCEDATE>20260408</REFERENCEDATE>\n            <VOUCHERTYPENAME>Purchase</VOUCHERTYPENAME>\n            <PARTYLEDGERNAME>Vam Advertising &amp; Marketing Pvt Ltd. ( Creditor )</PARTYLEDGERNAME>\n            <PARTYMAILINGNAME>Vam Advertising &amp; Marketing Pvt Ltd. ( Creditor )</PARTYMAILINGNAME>\n            <REFERENCE>53</REFERENCE>\n            <VCHENTRYMODE>Accounting Invoice</VCHENTRYMODE>\n            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>\n            <ISINVOICE>Yes</ISINVOICE>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>ADVERTISEMENT EXP @5%</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-6000</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>Vam Advertising &amp; Marketing Pvt Ltd. ( Creditor )</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>Yes</ISPARTYLEDGER>\n              <AMOUNT>6300</AMOUNT>\n            </LEDGERENTRIES.LIST>\n          </VOUCHER>\n        </TALLYMESSAGE>\n      </REQUESTDATA>\n    </IMPORTDATA>\n  </BODY>\n</ENVELOPE>	{"vendorLedger": "Vam Advertising & Marketing Pvt Ltd. ( Creditor )"}	\N	\N	Tally exception: a ledger name may not exist in Tally, or the voucher type is not configured. Open the browser console (F12) to see the full Tally response and verify your CGST/SGST ledger names match exactly.	2026-04-26 11:12:52.911	2026-04-26 11:20:42.205
b_1777203448596	cmofmpqxp0000tms4st6fcb8x	53	VAM ADVERTISING & MARKETING (P) LTD.	09AACCV0313J1ZI	\N	2026-04-08	6000	150	150	0	6300	ERROR	misc	\N	{"billDate": "2026-04-08", "subtotal": 6000, "lineItems": [{"unit": "Nos", "amount": 6000, "gstRate": 0, "hsnCode": "", "quantity": 1, "unitPrice": 6000, "description": "Publication/Edition - Amarujala- Kanpur, Date: 27/Mar/2026, Size: 10x8 sq.cm, Rate: 75.00", "discountPercent": null}], "billNumber": "53", "buyerGstin": "09ABKCS8865P1Z2", "cgstAmount": 150, "igstAmount": 0, "sgstAmount": 150, "vendorName": "VAM ADVERTISING & MARKETING (P) LTD.", "totalAmount": 6300, "vendorGstin": "09AACCV0313J1ZI", "roundOffAmount": null, "invoiceDiscountAmount": null}	t	null	<?xml version="1.0" encoding="utf-8"?>\n<ENVELOPE>\n  <HEADER>\n    <TALLYREQUEST>Import Data</TALLYREQUEST>\n  </HEADER>\n  <BODY>\n    <IMPORTDATA>\n      <REQUESTDESC>\n        <REPORTNAME>Vouchers</REPORTNAME>\n        <STATICVARIABLES>\n          <SVCURRENTCOMPANY>S D Z FOOD PRODUCTS PRIVATE LIMITED</SVCURRENTCOMPANY>\n        </STATICVARIABLES>\n      </REQUESTDESC>\n      <REQUESTDATA>\n        <TALLYMESSAGE xmlns:UDF="TallyUDF">\n          <VOUCHER VCHTYPE="Purchase" ACTION="Create" OBJVIEW="Invoice Voucher View">\n            <DATE>20260426</DATE>\n            <VOUCHERNUMBER>53_9</VOUCHERNUMBER>\n            <REFERENCEDATE>20260408</REFERENCEDATE>\n            <VOUCHERTYPENAME>Purchase</VOUCHERTYPENAME>\n            <PARTYLEDGERNAME>Vam Advertising &amp; Marketing Pvt Ltd. ( Creditor )</PARTYLEDGERNAME>\n            <PARTYMAILINGNAME>Vam Advertising &amp; Marketing Pvt Ltd. ( Creditor )</PARTYMAILINGNAME>\n            <REFERENCE>53</REFERENCE>\n            <VCHENTRYMODE>Accounting Invoice</VCHENTRYMODE>\n            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>\n            <ISINVOICE>Yes</ISINVOICE>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>ADVERTISEMENT EXP @5%</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>No</ISPARTYLEDGER>\n              <AMOUNT>-6000</AMOUNT>\n            </LEDGERENTRIES.LIST>\n            <LEDGERENTRIES.LIST>\n              <LEDGERNAME>Vam Advertising &amp; Marketing Pvt Ltd. ( Creditor )</LEDGERNAME>\n              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>\n              <LEDGERFROMITEM>No</LEDGERFROMITEM>\n              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>\n              <ISPARTYLEDGER>Yes</ISPARTYLEDGER>\n              <AMOUNT>6300</AMOUNT>\n            </LEDGERENTRIES.LIST>\n          </VOUCHER>\n        </TALLYMESSAGE>\n      </REQUESTDATA>\n    </IMPORTDATA>\n  </BODY>\n</ENVELOPE>	{"vendorLedger": "Vam Advertising & Marketing Pvt Ltd. ( Creditor )", "purchaseLedger": "Purchase Exempt"}	\N	\N	Tally exception: a ledger name may not exist in Tally, or the voucher type is not configured. Open the browser console (F12) to see the full Tally response and verify your CGST/SGST ledger names match exactly.	2026-04-26 11:37:28.596	2026-04-26 11:38:28.871
b_1777203608459	cmofmpqxp0000tms4st6fcb8x	21	S.S. Enterprises	09ACYPJ1932A1ZL	\N	2026-04-07	1000	90	90	0	1180	PARSED	purchase	\N	{"billDate": "2026-04-07", "subtotal": 1000, "lineItems": [{"unit": "Pc", "amount": 1000, "gstRate": 18, "hsnCode": "9032", "quantity": 1, "unitPrice": 1000, "description": "DTI FEK 72x72", "discountPercent": null}], "billNumber": "21", "buyerGstin": "09ABKCS1880SP1Z2", "cgstAmount": 90, "igstAmount": 0, "sgstAmount": 90, "vendorName": "S.S. Enterprises", "totalAmount": 1180, "vendorGstin": "09ACYPJ1932A1ZL", "roundOffAmount": null, "invoiceDiscountAmount": null}	f	\N	\N	\N	\N	\N	\N	2026-04-26 11:40:08.46	2026-04-26 11:40:08.636
\.


--
-- Data for Name: Company; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Company" (id, name, gstin, email, port, mapping, "voucherCounter", "syncTimestamps", "createdAt") FROM stdin;
c1	Sharma Groceries Pvt Ltd	07AABCS1429B1Z1	\N	9000	{"cgst": "Input CGST @2.5%", "igst": "Input IGST", "sgst": "Input SGST @2.5%", "purchase": "Grocery Purchases"}	0	\N	2026-04-26 09:32:08.13
c2	Sharma Wholesale	07AABCS1429B1Z2	\N	9001	\N	0	\N	2026-04-26 09:32:08.141
c3	Raj Pharma Store	09AAACR5055K1Z5	\N	9000	\N	0	\N	2026-04-26 09:32:08.15
cmofmpqxp0000tms4st6fcb8x	S D Z FOOD PRODUCTS PRIVATE LIMITED	09ABKCS8865P1Z2	\N	9000	{"igst_5": "Input IGST@5%", "igst_18": "INPUT IGST 18%", "input_cgst_9": "INPUT CGST 9%", "input_sgst_9": "INPUT SGST9%", "purchase_up_5": "Purchase 5%", "input_cgst_2_5": "INPUT CGST 2.5%", "input_sgst_2_5": "INPUT SGST 2.5%", "purchase_up_18": "PURCHASE 18%", "purchase_exempt": "Purchase Exempt", "roundoff_ledger": "R/OFF", "purchase_interstate_5": "Purchase IGST@5%", "purchase_interstate_18": "Purchase IGST@18%"}	9	{"ledgers": "2026-04-26T11:07:28.559Z", "stockItems": "2026-04-26T10:35:25.459Z", "stockUnits": "2026-04-26T10:35:27.376Z", "stockGroups": "2026-04-26T10:35:26.420Z"}	2026-04-26 10:32:11.677
cmofkp2az0001mjdm3pw0n2wo	Anurag Agencies (2024-25)	09AATPM2300E1ZV	\N	9000	\N	0	{"ledgers": "2026-04-26T09:53:58.162Z", "stockItems": "2026-04-26T09:40:43.857Z", "stockUnits": "2026-04-26T09:40:00.879Z", "stockGroups": "2026-04-26T09:40:00.211Z"}	2026-04-26 09:35:40.523
cmofl3ut6000hmjdmwqd3dziu	Rajeev Traders (2024-2025) - (from 1-Apr-25)	09AEKPJ6707K1Z3	\N	9000	{"igst_5": "IGST", "igst_18": "IGST", "input_cgst_9": "CGST", "input_sgst_9": "SGST", "input_cgst_2_5": "CGST", "input_sgst_2_5": "SGST", "purchase_up_18": "PURCHASE", "roundoff_ledger": "ROUNDED OFF", "purchase_interstate_18": "PURCHASE IGST-CENTRAL@18%"}	2	{"ledgers": "2026-04-26T09:47:59.840Z", "stockItems": "2026-04-26T09:48:01.652Z", "stockUnits": "2026-04-26T09:48:53.816Z", "stockGroups": "2026-04-26T09:48:03.388Z"}	2026-04-26 09:47:10.65
\.


--
-- Data for Name: CompanyFeature; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CompanyFeature" (id, "companyId", feature, enabled) FROM stdin;
\.


--
-- Data for Name: GodownCache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."GodownCache" (id, "companyId", name) FROM stdin;
\.


--
-- Data for Name: LedgerCache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LedgerCache" (id, "companyId", name, "group", gstin, state, "openingBalance", "gstRegistrationType") FROM stdin;
e154caff-303b-44cf-beb8-fdce446ae771	cmofl3ut6000hmjdmwqd3dziu	360 Degree Solutions	Sundry Debtors	09AZMPS9126J2ZJ	\N	0.00	Regular
482354fa-cdf6-4cd0-8cfc-2400f7622aaf	cmofl3ut6000hmjdmwqd3dziu	AADARSH KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
215aa9d2-1fb1-4dee-8966-75057a26cd52	cmofl3ut6000hmjdmwqd3dziu	AADIYOGI MINERALS PVT LTD	Sundry Creditors	09AARCA6991N1ZK	\N	0.00	Regular
215222b5-24f4-4771-92d9-20d6ddf47ee3	cmofl3ut6000hmjdmwqd3dziu	ABHAY KUMAR MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
75793e90-b9ce-4d91-82ae-08b997ab0425	cmofl3ut6000hmjdmwqd3dziu	Abhay Singh	Sundry Debtors	\N	\N	0.00	Unregistered
cf3db557-cce5-4bc9-b45e-4b0bfc0c7444	cmofl3ut6000hmjdmwqd3dziu	ABHAY TRAVELS	Sundry Debtors	09AIMPB7024P1ZU	\N	0.00	Regular
2cca8aa9-c947-4338-ae48-9fa269878eaf	cmofl3ut6000hmjdmwqd3dziu	ABHIJEET JAIN	Unsecured Loans	\N	\N	895141.00	Unregistered
74f13f73-2396-4047-b50f-a35e949be517	cmofl3ut6000hmjdmwqd3dziu	ABHIMANYU SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
298c55e0-0d6f-47dc-a5fb-512b443429c6	cmofl3ut6000hmjdmwqd3dziu	Abhinav Trivdi	Sundry Debtors	\N	\N	0.00	Unregistered
fdc0504b-22fe-4893-97bc-56af5701a313	cmofl3ut6000hmjdmwqd3dziu	Abhinay Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
64ad38f8-ed44-4161-81c3-f6e9dff138fe	cmofl3ut6000hmjdmwqd3dziu	Abhinesh Katiyar	Sundry Debtors	\N	\N	0.00	Unregistered
f3b35489-a194-47e8-bea9-35d2a8887ad7	cmofl3ut6000hmjdmwqd3dziu	ABHISHEK PAL	Sundry Debtors	\N	\N	0.00	Unregistered
7ec94c84-80ba-4b76-8bbd-e0660ea5de43	cmofl3ut6000hmjdmwqd3dziu	ABHISHEK TIWARI	Sundry Debtors	\N	\N	0.00	Unregistered
cbfa8d79-7fcd-48ac-95fa-175b3c9d8bfb	cmofl3ut6000hmjdmwqd3dziu	Abhishek Verma	Sundry Debtors	\N	\N	0.00	Unregistered
35927269-d7df-4668-b918-cc31add2dddc	cmofl3ut6000hmjdmwqd3dziu	ABHI TELECOM	Sundry Debtors	\N	\N	0.00	\N
4ffe22cb-00a4-4e1c-9c19-1d983530f672	cmofl3ut6000hmjdmwqd3dziu	Accounting Charges	Indirect Expenses	\N	\N	0.00	\N
d36d4e4d-577b-4c21-ae5d-a076ca07c78b	cmofl3ut6000hmjdmwqd3dziu	Ace Interiors	Sundry Debtors	09ALGPB1667H1Z6	\N	0.00	Regular
bbf2d8a6-2d40-404d-9998-c19a6e43310d	cmofl3ut6000hmjdmwqd3dziu	Adarsh	Sundry Debtors	\N	\N	0.00	Unregistered
2cab2c46-2bb3-4fbc-af54-8b6189e27b9a	cmofl3ut6000hmjdmwqd3dziu	ADHIROHAH INFRASTRUCTURE PRIVATE LIMITED	Sundry Debtors	09AASCA6367R1ZH	\N	0.00	Regular
4b911944-1fc1-4934-bc77-ead369dd0c90	cmofl3ut6000hmjdmwqd3dziu	Aditya &amp; Associates	Sundry Debtors	\N	\N	0.00	Unregistered
2c07f138-4547-43eb-a3f8-40b79b151d44	cmofl3ut6000hmjdmwqd3dziu	ADITYA MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
5c750f5c-9bdb-42e8-876b-a1d6c40926b2	cmofl3ut6000hmjdmwqd3dziu	Aditya Nigam	Sundry Debtors	\N	\N	0.00	\N
25c32d13-1a09-412a-8778-9c1ec8aee384	cmofl3ut6000hmjdmwqd3dziu	ADITYA PRATAP SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
0023b38f-5d25-4f43-867b-ddcede516f20	cmofl3ut6000hmjdmwqd3dziu	Advance Netal and Alloys Product	Sundry Debtors	09ABFFA4407R1Z1	\N	0.00	Regular
b8e3fc14-ce9e-4a8d-8885-e21920938c15	cmofl3ut6000hmjdmwqd3dziu	Advance Paid by Transporter	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
279eb9dd-fa57-41ef-99d2-18b18cff5db0	cmofl3ut6000hmjdmwqd3dziu	ADVANCE TAX-	Deposits (Asset)	\N	\N	0.00	Unregistered
a8a6cd09-f387-400b-a541-2ce434282478	cmofl3ut6000hmjdmwqd3dziu	ADVANCE TAX A.Y. 2022-2023	Deposits (Asset)	\N	\N	0.00	Regular
35d4bf75-4071-4e2d-9087-bc43c2b6286b	cmofl3ut6000hmjdmwqd3dziu	Adv. ANSH ROAD LINES	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
7188182e-95ce-4b31-8b0f-da80e54996d2	cmofl3ut6000hmjdmwqd3dziu	Adv. Arvind Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
8f2e3ff5-8c05-4b4a-824b-f6f4d31d7ac1	cmofl3ut6000hmjdmwqd3dziu	Adv. Bhardwaj Roadways	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
9617cde2-e781-4f56-81a5-74e9a713a608	cmofl3ut6000hmjdmwqd3dziu	Adv-Damodar Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Regular
817d3974-74b7-4e58-aa00-2da173215363	cmofl3ut6000hmjdmwqd3dziu	Adv-GERA TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
b00a829d-5940-477d-a502-62e430b8ccf8	cmofl3ut6000hmjdmwqd3dziu	Adv Mansarovat Transport	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
c687b6f3-47ce-4885-bebc-dbea4734c16a	cmofl3ut6000hmjdmwqd3dziu	Adv- Odisha Ghaziabad Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
a82b17ca-839d-4045-89a5-47fe89aee09c	cmofl3ut6000hmjdmwqd3dziu	Adv. SHARDA TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
6e07bac3-9e1c-4066-96a8-026fb0600ee8	cmofl3ut6000hmjdmwqd3dziu	Adv. Taj Transport	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
68f60cba-c41a-4d05-96dc-8be45aa78274	cmofl3ut6000hmjdmwqd3dziu	Adv. U P Maharashtra  Roadways	Sundry Creditors for Transporter	\N	\N	0.00	Regular
09b0511e-529e-45bd-a4e0-a6763a9d7694	cmofl3ut6000hmjdmwqd3dziu	Adv. Vijay Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
dbeac0f8-2e97-44d4-92f1-4975a6504792	cmofl3ut6000hmjdmwqd3dziu	Afsana	Sundry Debtors	\N	\N	0.00	\N
9cb2f554-213c-4622-a773-d12436f1b069	cmofl3ut6000hmjdmwqd3dziu	AGGARWAL BUILDTEC INDIA	Sundry Debtors	09AGSPA8620Q2ZN	\N	0.00	Regular
42f9c7a7-7f2c-4488-ac74-ed73f7273494	cmofl3ut6000hmjdmwqd3dziu	AGNIHOTRI TRADERS	Sundry Debtors	\N	\N	0.00	\N
a5aee342-c4a8-40df-aca9-0bb29336f1b2	cmofl3ut6000hmjdmwqd3dziu	Agroha Iron and Steel Industries	Sundry Creditors	\N	\N	0.00	Regular
2d4527ff-ff54-478c-8817-89c364091124	cmofl3ut6000hmjdmwqd3dziu	Ahmed &amp; Co.	Sundry Debtors	09AHRPA6487H2ZS	\N	0.00	Regular
1fc3fcf6-78e0-48c2-b95b-0f1e3fb814c8	cmofl3ut6000hmjdmwqd3dziu	Ahuja Electronics	Sundry Creditors	\N	\N	0.00	Unregistered
e2d2e807-d5d3-4e0b-afb1-6aeb3f948fca	cmofl3ut6000hmjdmwqd3dziu	Aikshik	Sundry Debtors	\N	\N	0.00	Unregistered
3f6048b9-9feb-4af2-a62f-b6b581c1b040	cmofl3ut6000hmjdmwqd3dziu	Air Conditioner	Fixed Assets	\N	\N	0.00	Regular
7a8cb70e-3dd0-4d33-81f7-15c392d97312	cmofl3ut6000hmjdmwqd3dziu	AIRCONDITIONER A/C	Fixed Assets	\N	\N	-95858.20	\N
12e56fde-01d1-441a-9599-2f1c80bcf152	cmofl3ut6000hmjdmwqd3dziu	AIR CONDITIONER -VOLTAS	Fixed Assets	\N	\N	0.00	\N
36fcd1a0-c775-4054-a92c-791d92bfb257	cmofl3ut6000hmjdmwqd3dziu	Ajay	Sundry Debtors	\N	\N	0.00	Unregistered
76f08dd5-3651-4e59-8e6d-31ab081da851	cmofl3ut6000hmjdmwqd3dziu	Ajay Bajpai	Sundry Debtors	\N	\N	0.00	Unregistered
32142717-2a0e-4628-8ef6-0363c6367ae0	cmofl3ut6000hmjdmwqd3dziu	Ajay Dool	Sundry Debtors	\N	\N	0.00	Unregistered
b2760228-e57a-455d-b4a8-03dc279a6d7b	cmofl3ut6000hmjdmwqd3dziu	Ajay Honey	Sundry Debtors	\N	\N	0.00	\N
beac8d83-2169-41c6-8520-7164e3e5eab0	cmofl3ut6000hmjdmwqd3dziu	Ajay Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
8c053105-9175-410b-a2b6-007f4f1376c1	cmofl3ut6000hmjdmwqd3dziu	Ajay Kumar Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
286d2270-13d8-4c27-9a32-9a0b6c897570	cmofl3ut6000hmjdmwqd3dziu	Ajay Kumar Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
75086e97-9902-4b85-84a4-1f2dd5e8ba4b	cmofl3ut6000hmjdmwqd3dziu	AJAY PRAKASH PAL	Sundry Debtors	\N	\N	0.00	Unregistered
4df3e233-f719-467c-8300-02637a84d53b	cmofl3ut6000hmjdmwqd3dziu	Ajay Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
cb5b1c43-7411-405a-9e35-3a26a0c814dd	cmofl3ut6000hmjdmwqd3dziu	Ajay Singh Solanki	Sundry Debtors	\N	\N	0.00	Unregistered
b2aa4bc8-4f13-4406-b326-9f9b7c41c873	cmofl3ut6000hmjdmwqd3dziu	Ajay Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
ceb50e9a-fbf7-4c12-a658-c34477069ed9	cmofl3ut6000hmjdmwqd3dziu	Ajeet	Sundry Debtors	\N	\N	0.00	Unregistered
0e2f6f54-e5a2-4c5b-af11-8b56b406e987	cmofl3ut6000hmjdmwqd3dziu	Ajit Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
77acdabf-9de6-4c14-879b-eb0e0a284849	cmofl3ut6000hmjdmwqd3dziu	AKASH ASSOCIATES	Sundry Debtors	09AAKFA9619D1ZB	\N	0.00	Regular
b3dba0aa-7e58-493e-b516-d8744a789c0f	cmofl3ut6000hmjdmwqd3dziu	AKASH DIVEDI	Sundry Debtors	\N	\N	0.00	Unregistered
29b48146-4d88-4b85-bc9a-05f52bdbb9c6	cmofl3ut6000hmjdmwqd3dziu	AKASH ELECTRICAL INFRTECH PVT LTD	Sundry Debtors	09ABCCS2932B1ZN	\N	0.00	Regular
f19fb419-45d5-4078-989f-e295b33bcb01	cmofl3ut6000hmjdmwqd3dziu	Akash Kushwaha	Sundry Debtors	\N	\N	0.00	Unregistered
6dc5ad7f-9cc4-4092-8c2e-94f280ee17d5	cmofl3ut6000hmjdmwqd3dziu	Akash Sachin	Sundry Debtors	\N	\N	0.00	Unregistered
50163b2f-852f-483c-86bf-77ed3e45f753	cmofl3ut6000hmjdmwqd3dziu	Akash Shukla	Sundry Debtors	\N	\N	0.00	Unregistered
eec7bea8-d6db-4b6a-89dd-70b89dd6c1bc	cmofl3ut6000hmjdmwqd3dziu	Akash Singh	Sundry Debtors	\N	\N	0.00	Unregistered
03e3ea6f-cdc3-43dd-9ace-fac97f061a03	cmofl3ut6000hmjdmwqd3dziu	AKASH VERMA	Sundry Debtors	\N	\N	0.00	Unregistered
bc565fd3-ba07-4e08-bf9a-f2495beab581	cmofl3ut6000hmjdmwqd3dziu	Akhand Jyoti Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
6a0cf737-ed17-4f1a-b1e3-b8498349842c	cmofl3ut6000hmjdmwqd3dziu	Akhil Bhartiya Mahila Shiksha Prasar Samiti	Sundry Debtors	\N	\N	0.00	Unregistered
c951a297-f53b-43ea-8748-33085c090d6c	cmofl3ut6000hmjdmwqd3dziu	AKHILESH GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
11c07382-6f3c-4b37-b51a-214f16cbf47a	cmofl3ut6000hmjdmwqd3dziu	Akhilesh Kumar	Sundry Debtors	\N	\N	0.00	\N
dd39fbed-13c9-4b35-877c-159936c09bf4	cmofl3ut6000hmjdmwqd3dziu	A K SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
6efaeb06-142b-48f9-984a-e0e1d3659f4e	cmofl3ut6000hmjdmwqd3dziu	Akshya Kumar Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
b4ebb81d-2e77-44e6-9b91-5bf7db020cd6	cmofl3ut6000hmjdmwqd3dziu	ALIMA  FABRICS	Sundry Debtors	09FAEPM0906E1ZX	\N	0.00	Regular
2921c4e3-d58a-4ece-a730-59ab01a08a01	cmofl3ut6000hmjdmwqd3dziu	ALKA RANI CHAUBEY	Sundry Debtors	09ABXPC9227D1ZD	\N	0.00	Regular
80dc3c68-3f5e-4baa-a69c-0a2eb5cd2f5a	cmofl3ut6000hmjdmwqd3dziu	ALLAHABAD KANPUR TRANSPORT COMPANY	Sundry Creditors for Transporter	22ASVPM6836F1ZD	\N	0.00	Regular
ae09eef1-28a3-447e-883c-b820383bbd5a	cmofl3ut6000hmjdmwqd3dziu	ALLAHDIN	Sundry Debtors	\N	\N	0.00	Unregistered
7e5383bd-260d-4cb2-bde9-d754aad3670b	cmofl3ut6000hmjdmwqd3dziu	All Over India Transport Co.	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
427361a4-03a6-4c8d-9173-e38d677156b9	cmofl3ut6000hmjdmwqd3dziu	Alok Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
d16c6767-900b-4cbf-93c0-49e151e3e051	cmofl3ut6000hmjdmwqd3dziu	Alok Tripathi	Sundry Debtors	\N	\N	0.00	\N
69bdb2aa-c295-4ed2-b16f-c8ce198ec719	cmofl3ut6000hmjdmwqd3dziu	Aman Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
ac6bf17b-092e-4e6c-b327-f57f0710c761	cmofl3ut6000hmjdmwqd3dziu	Aman Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
3c4358eb-370d-4098-93d3-7bee97f304a6	cmofl3ut6000hmjdmwqd3dziu	Aman Pal	Sundry Debtors	\N	\N	0.00	Unregistered
e802bbc7-e1ac-444e-8ffc-b62b22d2e626	cmofl3ut6000hmjdmwqd3dziu	Amar	Sundry Debtors	\N	\N	0.00	Unregistered
4c5de035-5731-4d1a-b031-dd4dcf0034de	cmofl3ut6000hmjdmwqd3dziu	AMAR ENTERPRISES	Sundry Creditors	22ACBPJ5107G1Z9	\N	0.00	Regular
f28a4837-8236-4dbf-9d92-0172cd50033b	cmofl3ut6000hmjdmwqd3dziu	Amar Pal	Sundry Debtors	\N	\N	0.00	\N
bcae002f-6dbe-4e59-9e59-20195be87229	cmofl3ut6000hmjdmwqd3dziu	Amar Singh	Sundry Debtors	\N	\N	0.00	Unregistered
64920e9b-9329-4163-a176-acdf8ca8d8a9	cmofl3ut6000hmjdmwqd3dziu	AMAR STEEL	Sundry Creditors	22ALRPJ2810M1Z1	\N	0.00	Regular
bc88833d-361e-4bfc-8da5-4c9b0921dcd1	cmofl3ut6000hmjdmwqd3dziu	AMBA SHAKTI UDYOG  LTD	Sundry Creditors	23AAMCA5657N1Z6	\N	0.00	Regular
88f57057-497f-481d-85d9-465d76c04c6a	cmofl3ut6000hmjdmwqd3dziu	AMBEY TRADERS	Sundry Debtors	09AZYPS1175P1Z3	\N	0.00	Regular
4c4ba4ee-4773-4ad2-ad5c-c1538575170f	cmofl3ut6000hmjdmwqd3dziu	AMBIKA CORPORATION	Sundry Debtors	09ABUPG0786A1ZK	\N	0.00	Regular
efb65beb-2a09-4e42-93ea-97230f614be4	cmofl3ut6000hmjdmwqd3dziu	Ambika Kushwaha	Sundry Debtors	\N	\N	0.00	Unregistered
035ad3a1-6666-44d3-89dd-dba7c955a02f	cmofl3ut6000hmjdmwqd3dziu	AMBIKA PRASAD  SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
d6462a87-49e0-4947-94be-4e37ce6e4fae	cmofl3ut6000hmjdmwqd3dziu	AMBRISH AGENCIES PVT LTD	Sundry Creditors	09AABCA2303A1ZL	\N	0.00	Regular
0fa538ce-9c54-4254-8d6c-2b4c1c34ce42	cmofl3ut6000hmjdmwqd3dziu	Amit Builder	Sundry Debtors	09FGQPS5390E1ZN	\N	0.00	Regular
2151ae5a-dc28-4284-b1bf-1356d2ee1854	cmofl3ut6000hmjdmwqd3dziu	Amit Engineers	Sundry Debtors	\N	\N	0.00	Unregistered
77cea153-0200-4bbf-80d1-135f8df42b65	cmofl3ut6000hmjdmwqd3dziu	Amitesh Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
fd5437a3-f44f-4bcf-a99a-3587fc64d69b	cmofl3ut6000hmjdmwqd3dziu	AMIT GRAMOUDYOG SANSTHAN	Sundry Debtors	09AAAAA4534C1Z9	\N	0.00	Regular
64f5bd86-500a-4226-ae42-30f0a3ff590b	cmofl3ut6000hmjdmwqd3dziu	Amit Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
97996b65-2fdc-4387-a42e-96019ddc508b	cmofl3ut6000hmjdmwqd3dziu	Amit Kr Srivastava	Sundry Debtors	\N	\N	0.00	Unregistered
76e2637b-251b-47d5-8dbc-e2b4e037063d	cmofl3ut6000hmjdmwqd3dziu	AMIT KUMAR SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
6b082ed5-a884-434a-a6cd-e5ea42d8761d	cmofl3ut6000hmjdmwqd3dziu	AMIT KUMAR SRIVASTAVA	Sundry Debtors	\N	\N	0.00	Unregistered
32f0cd02-e2dd-4adc-ad41-b3bb8e8f050d	cmofl3ut6000hmjdmwqd3dziu	Amit Kumar Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
798b4907-4c49-47cc-996e-b7b904cec0ba	cmofl3ut6000hmjdmwqd3dziu	AMIT RAJPUT	Sundry Debtors	\N	\N	0.00	Unregistered
5fff69a8-ec77-485c-8fb6-291c647fe9f0	cmofl3ut6000hmjdmwqd3dziu	Amit Singh	Sundry Debtors	\N	\N	0.00	Unregistered
9949ef62-0fdc-4237-a959-150acebbc415	cmofl3ut6000hmjdmwqd3dziu	Amit Verma	Sundry Debtors	\N	\N	0.00	Unregistered
43463cd0-e237-4632-91cc-05ac95d116d8	cmofl3ut6000hmjdmwqd3dziu	AMOL SACHAN	Sundry Debtors	\N	\N	0.00	Unregistered
8fe6ad70-e434-4eff-a847-236a633e018a	cmofl3ut6000hmjdmwqd3dziu	ANAND CONSTRUCTION	Sundry Debtors	09EFVPS7670G1ZE	\N	0.00	Regular
5e7e1561-4a56-46d4-aab2-a2479bdf72fb	cmofl3ut6000hmjdmwqd3dziu	ANAND KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
63719a6d-0aed-4960-a8ec-170e97089994	cmofl3ut6000hmjdmwqd3dziu	Anand Kumar-Kanpur	Sundry Debtors	\N	\N	0.00	Unregistered
92232068-c572-4d27-8aa2-6786a7d350c1	cmofl3ut6000hmjdmwqd3dziu	ANAND RAJ GAUTAM	Sundry Debtors	\N	\N	0.00	Unregistered
f2a57ec9-12a4-4265-ab35-42c579b4d1b0	cmofl3ut6000hmjdmwqd3dziu	Anand Shashtri	Sundry Debtors	\N	\N	0.00	Unregistered
ead343fb-8258-433a-b5bd-b8ee15aaf3a3	cmofl3ut6000hmjdmwqd3dziu	ANANT  RESOURCES	Sundry Creditors	22ABNFA9927A1ZL	\N	0.00	Regular
b0505751-8f18-4a06-be99-7e461539814e	cmofl3ut6000hmjdmwqd3dziu	ANEESH AHAMED	Sundry Debtors	\N	\N	0.00	Unregistered
f671ac3d-b06a-44f2-87e3-66d48b3fe4f9	cmofl3ut6000hmjdmwqd3dziu	Aniket Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
00061b5b-abbc-4a59-8c20-ce0875b4b715	cmofl3ut6000hmjdmwqd3dziu	Anil Katiyar	Sundry Debtors	\N	\N	0.00	Unregistered
315360f7-7508-4922-abd8-663504addc07	cmofl3ut6000hmjdmwqd3dziu	Anil Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
db694081-58c4-4773-aae0-7e31ee4df83e	cmofl3ut6000hmjdmwqd3dziu	ANIL KUMAR PATHAK	Sundry Debtors	09AIYPP8190N1ZV	\N	0.00	Regular
de2d6ab6-a150-4c8b-b4ea-c3c2378de1bb	cmofl3ut6000hmjdmwqd3dziu	ANIL KUMARR	Sundry Debtors	\N	\N	0.00	Unregistered
02542f60-5743-4a6a-8665-21921c0329a7	cmofl3ut6000hmjdmwqd3dziu	Anil Kumar Shukla	Sundry Debtors	\N	\N	0.00	Unregistered
c476622f-6c64-458c-bd4c-6c85869e7547	cmofl3ut6000hmjdmwqd3dziu	ANIL KUMAR VERMA	Sundry Debtors	\N	\N	0.00	Unregistered
b6470613-c69d-411c-9f9e-ee2eaff4795f	cmofl3ut6000hmjdmwqd3dziu	Anil Lime Company	Sundry Debtors	09AAQPA3715J1ZM	\N	0.00	Regular
978b22d8-ffa3-49c9-b70d-d9a6d70f5877	cmofl3ut6000hmjdmwqd3dziu	ANIRUDH Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
8c61c276-1af1-4a94-85c9-d072d4117e78	cmofl3ut6000hmjdmwqd3dziu	ANJALI TRADERS	Sundry Debtors	09ADVPG9616Q1ZF	\N	0.00	Regular
26c3be48-8735-47f7-958f-7d3b2328ff4b	cmofl3ut6000hmjdmwqd3dziu	ANJANA	Sundry Debtors	\N	\N	0.00	Unregistered
74b5b218-ad5d-4b9a-9645-2b7e8280da6d	cmofl3ut6000hmjdmwqd3dziu	Anju Dixit	Sundry Debtors	\N	\N	0.00	\N
f0083066-6b86-4be9-a0fe-33a207be3484	cmofl3ut6000hmjdmwqd3dziu	Anjul Steel Traders	Sundry Debtors	09ABMPJ4660N1Z1	\N	0.00	Regular
dd37906d-6be2-49d4-a4b1-d3aa6f74348a	cmofl3ut6000hmjdmwqd3dziu	ANJU SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
4c802199-a4f6-4dc4-8176-3f50fedb53d9	cmofl3ut6000hmjdmwqd3dziu	Ankit Kamal	Sundry Debtors	\N	\N	0.00	Unregistered
57f4bf4d-7eae-40fa-bb37-44b3d6768447	cmofl3ut6000hmjdmwqd3dziu	ANKIT KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
666193e0-760d-4ae3-83b5-0e28c7d484bd	cmofl3ut6000hmjdmwqd3dziu	ANKIT KUMAR DIXIT	Sundry Debtors	\N	\N	0.00	Unregistered
5ec86166-7f0c-4d56-915f-386dfd2e9bd9	cmofl3ut6000hmjdmwqd3dziu	ANKIT KUMAR TIWARI	Sundry Debtors	\N	\N	0.00	Unregistered
c1b588b4-a01a-4e12-88d2-580d2a80d4b9	cmofl3ut6000hmjdmwqd3dziu	Ankit Kushwaha	Sundry Debtors	\N	\N	0.00	Unregistered
17b3c849-212d-47c7-8990-81cfed4eeac7	cmofl3ut6000hmjdmwqd3dziu	ANKIT PANDEY	Sundry Debtors	\N	\N	0.00	Unregistered
088c7d32-0cd5-4be7-8dbb-d83ce4bd40f0	cmofl3ut6000hmjdmwqd3dziu	ANKIT SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
65a99e89-7aa3-4c9b-94a4-a9afb1ec3d76	cmofl3ut6000hmjdmwqd3dziu	Ankit Singh	Sundry Debtors	\N	\N	0.00	Unregistered
44c2814d-42ee-4dce-a3bf-450a2bf0466c	cmofl3ut6000hmjdmwqd3dziu	Ankuj	Sundry Debtors	\N	\N	0.00	Unregistered
4c998ca6-3f2c-4feb-9296-61fd8cafb033	cmofl3ut6000hmjdmwqd3dziu	Ankur	Sundry Debtors	\N	\N	0.00	Unregistered
24c01dcd-5b4e-4986-a015-4941c447bcb5	cmofl3ut6000hmjdmwqd3dziu	Ankur Tripathi	Sundry Debtors	\N	\N	0.00	\N
645f4b73-e314-4db1-abf1-f2c9cdc79bc6	cmofl3ut6000hmjdmwqd3dziu	ANKUR UDYOG LIMITED	Sundry Creditors	09AACCA6741R2Z2	\N	0.00	Regular
0049d357-51c3-4ff0-b738-8d124d358ae4	cmofl3ut6000hmjdmwqd3dziu	Annu Food Products	Sundry Debtors	09BIHPK5717J1ZX	\N	0.00	Regular
e1514e55-95b9-4380-a4d2-3f8a425dedfe	cmofl3ut6000hmjdmwqd3dziu	ANSHIKA  STEEL LLP	Sundry Creditors	09ABRFA5987C1ZX	\N	0.00	Regular
c88ef6c4-ed2e-4fc1-bfdd-a52b16ef1b68	cmofl3ut6000hmjdmwqd3dziu	ANSH ROAD LINES	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
0f0d1481-30d5-4add-9464-e6e334470363	cmofl3ut6000hmjdmwqd3dziu	Anshul Chaturvedi	Sundry Debtors	\N	\N	0.00	Unregistered
4ac82208-4b9d-448a-ab97-c1568430e9e7	cmofl3ut6000hmjdmwqd3dziu	ANUJ KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
4a7a28e2-bba6-44bc-8406-bda6be5dc835	cmofl3ut6000hmjdmwqd3dziu	Anuj Pal	Sundry Debtors	\N	\N	0.00	\N
36deddff-73e6-4306-b793-ff4c5bcddb9d	cmofl3ut6000hmjdmwqd3dziu	Anuj Tripathi	Sundry Debtors	\N	\N	0.00	Unregistered
ab7eb0fb-4e59-4327-a50f-4153cfec67af	cmofl3ut6000hmjdmwqd3dziu	ANUPAM AWASTHI	Sundry Debtors	\N	\N	0.00	Unregistered
6ecd1c77-db8c-4c1c-bf4d-6bffa03982d8	cmofl3ut6000hmjdmwqd3dziu	Anupam Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
b5ffd19f-88c9-4cc5-a184-63f3f0aaae18	cmofl3ut6000hmjdmwqd3dziu	Anup Kumar Srivastava	Sundry Debtors	09ASYPS1959A1Z4	\N	0.00	Regular
80059c9a-d032-4e9f-b993-b48fdd477f19	cmofl3ut6000hmjdmwqd3dziu	Anup Singh Pal	Sundry Debtors	\N	\N	0.00	Unregistered
742af1c2-a211-4a48-9765-9e8d6418a9e7	cmofl3ut6000hmjdmwqd3dziu	Anurag Awasthi	Sundry Debtors	\N	\N	0.00	Unregistered
4ab2f823-2fc3-4c11-804a-f7105daddbfe	cmofl3ut6000hmjdmwqd3dziu	Anurag Gautam	Sundry Debtors	\N	\N	0.00	Unregistered
d4b913bd-68ee-4543-ba11-91a1e6e4e400	cmofl3ut6000hmjdmwqd3dziu	Anurag Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
09e36041-d25e-4ace-986c-05a968c3cd7c	cmofl3ut6000hmjdmwqd3dziu	ANURAG SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
0b7a97aa-3514-4201-86d9-430976fd2072	cmofl3ut6000hmjdmwqd3dziu	Apsara Construction	Sundry Debtors	\N	\N	0.00	\N
ad20d405-d6f4-41d1-a435-efe80c73bf3a	cmofl3ut6000hmjdmwqd3dziu	Archana Agarwal	Sundry Debtors	\N	\N	0.00	Unregistered
a2d03281-4131-4ce7-ac6b-3f73c0003a53	cmofl3ut6000hmjdmwqd3dziu	ARCHI TECTURAL  SOLUATION	Sundry Debtors	\N	\N	0.00	Unregistered
a88865b7-80d1-4d55-8050-a16d3d545ae9	cmofl3ut6000hmjdmwqd3dziu	A R DESIGN AND FACILITIES	Sundry Debtors	07BCFPR7988J3ZM	\N	0.00	Regular
7007fcf0-4bff-4b09-9623-6e5c24ff0566	cmofl3ut6000hmjdmwqd3dziu	A R Infradevelopers	Sundry Debtors	09ABPFA1702M1Z9	\N	0.00	Regular
4aabb905-7388-4b98-8fcd-f7202f2c17b5	cmofl3ut6000hmjdmwqd3dziu	Arjun Sinhg	Sundry Debtors	\N	\N	0.00	Unregistered
704d571a-c0af-42d2-b80a-681a1a471dca	cmofl3ut6000hmjdmwqd3dziu	ARPANA SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
d325d001-9ef6-41f9-9c0b-481f447d0eee	cmofl3ut6000hmjdmwqd3dziu	ARPAN SRIVASTAVA	Sundry Debtors	\N	\N	0.00	Unregistered
8cc13915-8098-4586-af3a-16db0544c34d	cmofl3ut6000hmjdmwqd3dziu	ARPITA SACHAN	Sundry Debtors	\N	\N	0.00	Unregistered
623e9173-e9ff-4a44-95ad-2ef6d5b6b4fb	cmofl3ut6000hmjdmwqd3dziu	Arpit Srivastava	Sundry Debtors	\N	\N	0.00	Unregistered
110fbb58-8971-41f0-beed-cf6fda2e5a9c	cmofl3ut6000hmjdmwqd3dziu	Arti Kushwaha	Sundry Debtors	\N	\N	0.00	Unregistered
1ec86df2-bf9e-4eb6-bea4-1a4409176cd1	cmofl3ut6000hmjdmwqd3dziu	ARUN DIXIT	Sundry Debtors	\N	\N	0.00	Unregistered
3e7b7856-5a1b-4b86-913a-4f4d9f4fb5b6	cmofl3ut6000hmjdmwqd3dziu	Arun Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
779ae4d3-b44d-45ab-95f6-337f389919c9	cmofl3ut6000hmjdmwqd3dziu	ARUN KUMAR AGARWAL	Sundry Debtors	\N	\N	0.00	Unregistered
46e174ba-eb04-4e8e-b715-9d4803e300b4	cmofl3ut6000hmjdmwqd3dziu	ARUN KUMAR-KANPUR DILWAL	Sundry Debtors	\N	\N	0.00	Unregistered
e6d4d45f-3507-4139-beae-8d727b12ad78	cmofl3ut6000hmjdmwqd3dziu	ARUN KUMAR SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
0ceeba6c-94b7-48e3-910b-8568ba9ece75	cmofl3ut6000hmjdmwqd3dziu	ARVIND KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
e3406ada-d922-4993-85d4-e84b093446b6	cmofl3ut6000hmjdmwqd3dziu	Arvind Kumar Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
34e926bf-bf2e-4f6c-872e-f372bb11a3a3	cmofl3ut6000hmjdmwqd3dziu	Arvind Kumar Pal	Sundry Debtors	\N	\N	0.00	Unregistered
3d95d689-5ce1-4276-a9fd-249d1b51e32d	cmofl3ut6000hmjdmwqd3dziu	ARVIND KUMAR -SWAROOP NAGAR	Sundry Debtors	\N	\N	0.00	Unregistered
fb58e81c-1f6b-45a3-a191-19e893552572	cmofl3ut6000hmjdmwqd3dziu	ARVIND ROAD LINES	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
2e6e226d-02c0-4290-aac6-0efb916b618d	cmofl3ut6000hmjdmwqd3dziu	ARYAN SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
b3f2da27-35d5-4fd4-a34f-980631c88922	cmofl3ut6000hmjdmwqd3dziu	A.S. ENTERPRISES	Sundry Debtors	09ABMFA1332J1ZG	\N	0.00	Regular
932deca8-20af-4e4b-8656-c6c43c2dd538	cmofl3ut6000hmjdmwqd3dziu	A S ENTERPRISESS	Sundry Debtors	\N	\N	0.00	\N
cee79191-32c8-4a04-8d20-6e5d3b0346e9	cmofl3ut6000hmjdmwqd3dziu	ASHISH GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
8473cf18-3318-4438-97e3-a6c015dc9011	cmofl3ut6000hmjdmwqd3dziu	ASHISH KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
6a4c0cd9-ead8-439c-9c7e-b0097ae8abaa	cmofl3ut6000hmjdmwqd3dziu	Ashish Kumar Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
c79ab53a-b634-4bd6-925a-aa0337250588	cmofl3ut6000hmjdmwqd3dziu	ASHISH KUMAR SHAH	Sundry Debtors	\N	\N	0.00	Unregistered
314a7726-3078-46ac-a082-d438d26fad24	cmofl3ut6000hmjdmwqd3dziu	ASHISH MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
0a71b870-3110-4181-b02f-d5196d40612b	cmofl3ut6000hmjdmwqd3dziu	ASHISH NIGAM	Sundry Debtors	\N	\N	0.00	Unregistered
ffcc28c7-4d18-4cf4-8591-6ab3e3a68e2e	cmofl3ut6000hmjdmwqd3dziu	Ashish Shah	Sundry Debtors	\N	\N	0.00	Unregistered
ea154fd9-b6bb-4e37-a5ba-58e68af04e97	cmofl3ut6000hmjdmwqd3dziu	ASHISH SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
9baa9d4f-ce71-414c-935f-cd824c959bac	cmofl3ut6000hmjdmwqd3dziu	ASHISH SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
cfc26fc9-703e-4641-a793-8b961c41bbc2	cmofl3ut6000hmjdmwqd3dziu	Ashish Steels	Sundry Creditors	09AMAPM4946K1ZO	\N	0.00	Regular
43cf7f6a-9ef2-41b2-94cd-f573dfda321e	cmofl3ut6000hmjdmwqd3dziu	Ashok Kumar Bhatia	Sundry Debtors	\N	\N	0.00	Unregistered
5638757b-733b-40e3-99cd-8c444cc643e5	cmofl3ut6000hmjdmwqd3dziu	Ashok Kumar Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
da41b677-4134-4191-a386-dea70853d4d8	cmofl3ut6000hmjdmwqd3dziu	Ashok Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
962eaf8d-5bb5-4f64-8fe6-bc7a71b9ce02	cmofl3ut6000hmjdmwqd3dziu	Ashutosh	Sundry Debtors	\N	\N	0.00	Unregistered
f36e3d8d-663d-4ea1-aa86-dba332368582	cmofl3ut6000hmjdmwqd3dziu	ASHUTOSH KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
4af85e26-4f39-4408-aaac-e8a3a955ba33	cmofl3ut6000hmjdmwqd3dziu	Ashutosh Monteshari Shikasha Samiti	Sundry Debtors	\N	\N	0.00	Unregistered
a15e0954-aec8-412b-9ad9-1a47daf36d2d	cmofl3ut6000hmjdmwqd3dziu	ASHUTOSH SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
55a8f4ec-cbab-44bd-a03a-8c40fa8cd92d	cmofl3ut6000hmjdmwqd3dziu	Ashutosh Tripathi	Sundry Debtors	\N	\N	0.00	Unregistered
9c098886-7d71-4063-9f11-b3f20eb0e4c1	cmofl3ut6000hmjdmwqd3dziu	ASIA PETOCHEM  INDUSTRIES	Sundry Debtors	09ABYFA0444M1ZV	\N	0.00	Regular
f2938062-3123-434d-827a-769f5e919453	cmofl3ut6000hmjdmwqd3dziu	A.S.INFRATECH	Sundry Debtors	\N	\N	0.00	\N
2de1be93-2dfa-4ad2-8a53-7256ca28f068	cmofl3ut6000hmjdmwqd3dziu	A.S. ISPAT	Sundry Debtors	09AAFHA8165F1Z9	\N	0.00	Regular
02ca4aac-c113-4b2c-9a41-e22f3a0d5d5f	cmofl3ut6000hmjdmwqd3dziu	ATUL KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
c32919fd-acf2-4a2f-bab5-5eeceee5e479	cmofl3ut6000hmjdmwqd3dziu	ATUL SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
e27eca82-9bc3-4d82-b4b6-8684f41fe641	cmofl3ut6000hmjdmwqd3dziu	AUDIT FEE	Indirect Expenses	\N	\N	0.00	\N
bd7f3999-4dfa-437c-b526-3d6c4062ec77	cmofl3ut6000hmjdmwqd3dziu	Audit Fee Payable	Provisions	\N	\N	0.00	\N
32c43482-9380-4861-99b4-94888d9722e6	cmofl3ut6000hmjdmwqd3dziu	A U EDUCATION AND SOLUATION LTd	Sundry Debtors	09AARCA5094L1ZW	\N	0.00	Regular
07288295-b85a-44ee-8fef-d20e52db9238	cmofl3ut6000hmjdmwqd3dziu	AVESH	Sundry Debtors	\N	\N	0.00	Unregistered
97d82fc9-710a-4180-8ed8-708f7d8c591e	cmofl3ut6000hmjdmwqd3dziu	Avesh Sachan	Sundry Debtors	\N	\N	0.00	Unregistered
f323cd85-8656-4592-bf73-36698c2bb987	cmofl3ut6000hmjdmwqd3dziu	Avinash Kumar Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
169a47c3-3294-4db9-9b50-b131e8c164b5	cmofl3ut6000hmjdmwqd3dziu	Avinash Singh	Sundry Debtors	\N	\N	0.00	Unregistered
3691ee31-2638-4d58-bead-ad34c8a65d3b	cmofl3ut6000hmjdmwqd3dziu	AVINASH TRIPATHI	Sundry Debtors	\N	\N	0.00	Unregistered
379f9bf0-03fc-495d-a254-5db6617308b9	cmofl3ut6000hmjdmwqd3dziu	Avinash Verma	Sundry Debtors	\N	\N	0.00	Unregistered
9e34f7b8-8839-4ae5-870b-a117ddfad5ea	cmofl3ut6000hmjdmwqd3dziu	AVISHKA BUILDERS	Sundry Debtors	09BBQPK7780P2ZF	\N	0.00	Regular
fd16614a-182f-4983-ad05-f63a497181a6	cmofl3ut6000hmjdmwqd3dziu	Avneet Kushwaha	Sundry Debtors	\N	\N	0.00	Unregistered
370ae185-25d9-4d2a-b451-d1e3aa42afc5	cmofl3ut6000hmjdmwqd3dziu	AVS AGRAWAL IRON AND STEEL SALES PVT LTD	Sundry Creditors	09AAUCA7384G1ZZ	\N	0.00	Regular
590c4832-70da-4f0c-9bf1-949ff731cb22	cmofl3ut6000hmjdmwqd3dziu	AYUSH GARG	Sundry Debtors	\N	\N	0.00	Unregistered
2ce18d47-7c09-49b8-8b50-a9c40cca69f4	cmofl3ut6000hmjdmwqd3dziu	Ayushi Traders	Sundry Debtors	\N	\N	0.00	Unregistered
88334fc8-d9a0-47a7-8f80-f63ac1633a84	cmofl3ut6000hmjdmwqd3dziu	Ayush Rathour	Sundry Debtors	\N	\N	0.00	\N
4e2153f6-d34c-43b3-8d29-e2544dfb7c3e	cmofl3ut6000hmjdmwqd3dziu	Baba Hardev Furnitures	Sundry Debtors	09BCZPG2600Q1Z4	\N	0.00	Regular
e78e82d4-9c3c-4714-8c38-9ccb94465ff6	cmofl3ut6000hmjdmwqd3dziu	Babu Ram	Sundry Debtors	\N	\N	0.00	Unregistered
edb1ff18-ded3-4cde-9643-e91ab80be06b	cmofl3ut6000hmjdmwqd3dziu	Bad Debts	Indirect Expenses	\N	\N	0.00	\N
2452826c-7e54-4deb-817b-c68cff48491c	cmofl3ut6000hmjdmwqd3dziu	BADRI PRASAD JANKI PRASAD	Sundry Debtors	09AFDPG9870Q1ZL	\N	0.00	Regular
0b0240b0-c7af-4557-a18e-26042f1f6cd5	cmofl3ut6000hmjdmwqd3dziu	Badri Trading Company	Sundry Debtors	09ANDPT8353K1ZB	\N	0.00	Regular
112ae16d-edd2-413b-bb21-a22b01ff6608	cmofl3ut6000hmjdmwqd3dziu	BAHADUR SECURITY SERVICE	Sundry Debtors	\N	\N	0.00	Unregistered
4cc72b16-3eba-47d4-94d3-1be80a036433	cmofl3ut6000hmjdmwqd3dziu	BAJRANG  TRANSPORT COMPANY	Sundry Creditors for Transporter	09AFGPE6368C1ZI	\N	0.00	Regular
7c5e812e-db1e-4f24-9e10-fbfcb028e3cb	cmofl3ut6000hmjdmwqd3dziu	BALAJI CONSTRUCTION CO.	Sundry Debtors	\N	\N	0.00	\N
1149e57e-ed77-4ce4-b795-38e040307754	cmofl3ut6000hmjdmwqd3dziu	Balaji Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
9e5fd4d3-f386-43ef-b7e4-cac6acb2a497	cmofl3ut6000hmjdmwqd3dziu	BALAJI GENERATOR SERVICES	Sundry Debtors	09AYMPR2148E2Z5	\N	0.00	Regular
76cd01f0-ae02-472e-a87a-cf0a20b20015	cmofl3ut6000hmjdmwqd3dziu	Balaji Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	\N
67872e3c-6e89-477b-9f6e-8c7b4b28403d	cmofl3ut6000hmjdmwqd3dziu	BALKALYAN SAMITI SARASHWATI SHISHU MANDIR	Sundry Debtors	\N	\N	0.00	Unregistered
42280304-fa15-46b0-a672-007ad546a0a9	cmofl3ut6000hmjdmwqd3dziu	Balram and Asha Devi	Sundry Debtors	\N	\N	0.00	Unregistered
4f957a7d-fdfa-4faa-ac11-c863f7dd7141	cmofl3ut6000hmjdmwqd3dziu	BALRAM SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
3ae37152-e68f-4c38-88a8-027a2f79f47c	cmofl3ut6000hmjdmwqd3dziu	Bamleshwari Trading Company	Sundry Creditors	22AFRPA8796F1Z5	\N	0.00	Regular
9296e942-ab21-436a-bc73-c6a4bcceb5f0	cmofl3ut6000hmjdmwqd3dziu	Bandhu Electricals	Sundry Debtors	09ABWPY7062P1Z6	\N	0.00	Regular
6eaa21a7-28cc-4090-a991-e51f6f6f473f	cmofl3ut6000hmjdmwqd3dziu	Bangalore Nagpur Roadways	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
a023a864-ff83-4d06-941d-4d1aa5bc9897	cmofl3ut6000hmjdmwqd3dziu	Bank Charges	Indirect Expenses	\N	\N	0.00	\N
469d52c2-2347-4fbd-978d-bb82b72eed4a	cmofl3ut6000hmjdmwqd3dziu	BANKC HARGES ------GST	Indirect Expenses	\N	\N	0.00	\N
771d97dc-5052-4777-a682-66d737e85de8	cmofl3ut6000hmjdmwqd3dziu	BANK INTEREST	Indirect Expenses	\N	\N	0.00	\N
00d0a7ff-8bac-449e-89e6-d38fd1383f5c	cmofl3ut6000hmjdmwqd3dziu	BANSAL TRADING COMPANY	Sundry Creditors	\N	\N	0.00	Regular
7fd0e07a-27bf-4349-aa99-107e52e08424	cmofl3ut6000hmjdmwqd3dziu	Basant Infra Build Pvt  Ltd	Sundry Debtors	09AADCB3316N1ZK	\N	0.00	Regular
3807a575-a66b-445d-949e-58afbdc8eb14	cmofl3ut6000hmjdmwqd3dziu	BEE CHEMS	Sundry Debtors	09AADHS9047N1ZD	\N	0.00	Regular
d3bd9b50-09d1-47a8-82fa-10236b4369ba	cmofl3ut6000hmjdmwqd3dziu	Bhagwan Prasad Gour	Sundry Debtors	\N	\N	0.00	Unregistered
2db0979f-6c52-46e6-8869-7bfe160ace57	cmofl3ut6000hmjdmwqd3dziu	BHAGWATI INFRATECH	Sundry Debtors	07AKNPG1992N1ZJ	\N	0.00	Regular
be6c997e-2bc4-41f0-a331-518d002cb19d	cmofl3ut6000hmjdmwqd3dziu	BHAGWATI PRASAD	Sundry Debtors	\N	\N	0.00	Unregistered
1eea8b34-2c02-4eb7-9855-3ccb55655f41	cmofl3ut6000hmjdmwqd3dziu	BHANU PRATAP SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
0fecdbf8-1477-47cc-a61f-990fec4115b8	cmofl3ut6000hmjdmwqd3dziu	Bharat Radios	Sundry Debtors	09APTPS0068J1Z6	\N	0.00	Regular
a473deb4-e30d-4a4c-ad2c-84506d52d64f	cmofl3ut6000hmjdmwqd3dziu	BHARAT SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
eab56532-d8fe-4d0c-8403-d899b5c9e521	cmofl3ut6000hmjdmwqd3dziu	BHARAT SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
409f5755-45b8-44c2-93fa-46480e427d38	cmofl3ut6000hmjdmwqd3dziu	Bharat Traders	Sundry Debtors	09IEJPK6775P1Z9	\N	0.00	Regular
8e80749c-d0c4-4b0f-ba5e-8022ea315e19	cmofl3ut6000hmjdmwqd3dziu	Bharat_singh	Sundry Debtors	\N	\N	0.00	Unregistered
73aa6212-0f17-4df7-ba69-83a438032667	cmofl3ut6000hmjdmwqd3dziu	BHARDWAJ ROADWAYS	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
890e7ec7-8090-4da4-ad7f-75df8f3112e2	cmofl3ut6000hmjdmwqd3dziu	Bhavya Dixit	Sundry Debtors	\N	\N	0.00	Unregistered
b81dccbf-e4e3-483f-904c-7574158ce2ce	cmofl3ut6000hmjdmwqd3dziu	BHAVYA ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
900e9a94-634e-48f8-a8cf-d457b6f0e2ef	cmofl3ut6000hmjdmwqd3dziu	Bhawani Construction and Satring Works	Sundry Debtors	09DAYPS7884F1ZG	\N	0.00	Regular
a27e2d8e-fd8a-4957-a36b-487f58645e63	cmofl3ut6000hmjdmwqd3dziu	BHIMANI CONSTRUCTION AND SATRING Wors	Sundry Debtors	09DAYPS7884F1ZG	\N	0.00	Regular
be48ac4f-82c3-400f-a769-07e282c567a7	cmofl3ut6000hmjdmwqd3dziu	BHIMA SHANKAR TRADERS	Sundry Debtors	09ARPPG8842C1ZJ	\N	0.00	Regular
affe9199-b407-4ec8-adbc-0a89582278fa	cmofl3ut6000hmjdmwqd3dziu	BHOOP KISHOR MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
e80a23f3-5398-4163-8806-34d3a724b5e6	cmofl3ut6000hmjdmwqd3dziu	BIJAY KARAN SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
96608a42-8429-4ece-b88b-ae457df07be9	cmofl3ut6000hmjdmwqd3dziu	BIJAY KUMAR DAS	Sundry Debtors	\N	\N	0.00	Unregistered
38b240ba-c216-42e0-a9bb-6a94e22aa0ed	cmofl3ut6000hmjdmwqd3dziu	BIRENDA VERMA	Sundry Debtors	\N	\N	0.00	Unregistered
afadc8f9-1229-444c-97a5-29037894a2bd	cmofl3ut6000hmjdmwqd3dziu	Bishok Singh	Sundry Debtors	\N	\N	0.00	Unregistered
9805434f-73a6-4db7-bd67-8784910d7ecf	cmofl3ut6000hmjdmwqd3dziu	BJD ENGINEERS INDIA PRIVATE LIMITED	Sundry Debtors	09AADCB0871C2Z0	\N	0.00	Regular
26ab7eec-9382-4100-ad4f-2f31bfa4f8cc	cmofl3ut6000hmjdmwqd3dziu	B L ENTERPRISES	Sundry Creditors	09ACAPJ1790J1ZI	\N	0.00	Regular
80c0b57c-ef3a-44d9-b7b1-3e0a5baa026a	cmofl3ut6000hmjdmwqd3dziu	B.N. Enterprises	Sundry Debtors	09AFZPP0640P1ZI	\N	0.00	Regular
7f9e6210-68bf-4744-8757-ad4af62d159a	cmofl3ut6000hmjdmwqd3dziu	BOBY SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
0d87d4d6-de9b-449d-b25c-116ad4b7b3d5	cmofl3ut6000hmjdmwqd3dziu	B P Tiwari	Sundry Debtors	09AASFB8618H1ZX	\N	0.00	Regular
70c9761b-d299-43da-b575-044e469180c3	cmofl3ut6000hmjdmwqd3dziu	BRAHM NARAIN	Sundry Debtors	\N	\N	0.00	Unregistered
9e24b4d2-78b7-4c0a-8009-f404643ac319	cmofl3ut6000hmjdmwqd3dziu	Brajesh Kuamr Sonkar	Sundry Debtors	\N	\N	0.00	Unregistered
48d13820-2e3a-4b2c-af6f-3ec51593664f	cmofl3ut6000hmjdmwqd3dziu	BRANCON INFRAPROJECTS PRIVATE LIMITED	Sundry Debtors	09AALCB4953D1ZK	\N	0.00	Regular
dd01c819-8a7a-42e7-9922-c53cc44bf63d	cmofl3ut6000hmjdmwqd3dziu	Brijendra Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
369728ba-3bbb-48ac-b194-50908b6b6a68	cmofl3ut6000hmjdmwqd3dziu	BRIJESH Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
a0828572-2a0c-4e72-9bf8-75fc7fe03952	cmofl3ut6000hmjdmwqd3dziu	Brijesh Yadav Satabdi Nagar	Sundry Debtors	\N	\N	0.00	Unregistered
2b612988-78b6-46f0-a06d-8bcdb9b7e5b3	cmofl3ut6000hmjdmwqd3dziu	BRIJ KISHOR	Sundry Debtors	\N	\N	0.00	Unregistered
49f196a3-c1a8-4a7a-b567-c4440962ef14	cmofl3ut6000hmjdmwqd3dziu	Srayanshu Srivastava	Sundry Debtors	\N	\N	0.00	\N
09025fa0-013c-4ea5-9dbc-312b5f5e724c	cmofl3ut6000hmjdmwqd3dziu	Brijwasi Transport	Sundry Creditors for Transporter	\N	\N	0.00	\N
2e0692a0-f51a-4c4d-b9fa-10777160592f	cmofl3ut6000hmjdmwqd3dziu	BROTHER TRADERS	Sundry Debtors	09ADAPF9061H1ZL	\N	0.00	Regular
7e7f54aa-72db-4c96-bb07-db9f395b4f72	cmofl3ut6000hmjdmwqd3dziu	B S CONSTRUCTION	Sundry Creditors	09CHGPK9090K1ZO	\N	0.00	Regular
76a75702-b332-47c8-a6bd-b7e111c418d2	cmofl3ut6000hmjdmwqd3dziu	Building	Fixed Assets	\N	\N	-2762172.26	Unregistered
b1942f05-6e3f-4ade-b3d0-7dc0a82d8666	cmofl3ut6000hmjdmwqd3dziu	BUILDING CONSTRUCTION	Indirect Expenses	\N	\N	0.00	\N
c2030f5c-0906-4245-a75b-2d10c7193563	cmofl3ut6000hmjdmwqd3dziu	BUTLER PALACE&#13;&#10;&#13;&#10;	Sundry Debtors	09APSPS0749B2ZJ	\N	0.00	Regular
ca1b6083-ea71-4f48-81a9-ffd1813eb54f	cmofl3ut6000hmjdmwqd3dziu	CAPTAIN CARGO MOVERS	Sundry Creditors for Transporter	\N	\N	0.00	Regular
dade2221-834f-4b1c-b08f-f620d84ab208	cmofl3ut6000hmjdmwqd3dziu	CAPTAIN  STEEL INDIA LTD	Sundry Creditors	10AACCB2921L1Z4	\N	0.00	Regular
4aafd2bf-83c9-4974-b817-6b976484f6f6	cmofl3ut6000hmjdmwqd3dziu	Captain Steel Security	Loans & Advances (Asset)	\N	\N	0.00	Regular
e9061e9c-c25e-4726-bc9c-696d3c962e79	cmofl3ut6000hmjdmwqd3dziu	CAR A/C	Fixed Assets	\N	\N	-908755.40	Regular
299d3809-3d0f-4cbc-975d-2c87d463b932	cmofl3ut6000hmjdmwqd3dziu	CAR INSURANCE	Indirect Expenses	\N	\N	0.00	\N
58f147c1-a03d-40e7-9dd2-c9ba7ebc1d00	cmofl3ut6000hmjdmwqd3dziu	CASH	Cash-in-hand	\N	\N	-396355.00	\N
bc714656-5cfe-4ca0-9b01-2f13d0b8a601	cmofl3ut6000hmjdmwqd3dziu	CGST	Duties & Taxes	\N	\N	-10000.00	\N
1e3b951a-31c3-42d5-b044-38778835bb3e	cmofl3ut6000hmjdmwqd3dziu	Cgst Cash Ledger	Duties & Taxes	\N	\N	0.00	\N
1a78427f-28f4-4702-bf38-3d3ae2412bfd	cmofl3ut6000hmjdmwqd3dziu	CGST EXCESS CLAIMED	Duties & Taxes	\N	\N	0.00	\N
bad2bb12-0b5d-45ec-90e4-70875cb84ccc	cmofl3ut6000hmjdmwqd3dziu	CGSTINWARD@14%	Duties & Taxes	\N	\N	0.00	\N
62d169c4-74d2-4a15-80bc-287a8f0a2892	cmofl3ut6000hmjdmwqd3dziu	CGST INWARD @ 9%	Duties & Taxes	\N	\N	0.00	\N
8f16c7e2-b496-46c6-bf2e-9ff35389a1b1	cmofl3ut6000hmjdmwqd3dziu	CGST OUTWARD@14%	Duties & Taxes	\N	\N	0.00	\N
d9eb005c-daae-48f6-9e33-22fb7f242ae0	cmofl3ut6000hmjdmwqd3dziu	CGST OUTWARD @ 9%	Duties & Taxes	\N	\N	0.00	\N
39dccb84-d2af-4ca7-ae1c-99ec4c37eccb	cmofl3ut6000hmjdmwqd3dziu	CGST PAID T. Over Tax	Duties & Taxes	\N	\N	0.00	\N
6e958bdb-985f-4ec1-b232-c1e426f1d601	cmofl3ut6000hmjdmwqd3dziu	CGST PAYABLE	Provisions	\N	\N	0.00	\N
fbf83011-ad51-49de-a5cb-2061ed48b4ef	cmofl3ut6000hmjdmwqd3dziu	CGST P B	Duties & Taxes	\N	\N	0.00	\N
6b5ed15a-7ad7-4bec-bc51-3598898aeae0	cmofl3ut6000hmjdmwqd3dziu	CGST RCM	Duties & Taxes	\N	\N	0.00	\N
37ea9663-3b0d-46f8-8774-fba8930f23fe	cmofl3ut6000hmjdmwqd3dziu	CGST RCM PAYABLE	Provisions	\N	\N	0.00	\N
616fc447-aafd-475d-927c-4c2c774cb8e9	cmofl3ut6000hmjdmwqd3dziu	CGST TO BE CLAIMED	Duties & Taxes	\N	\N	0.00	\N
63f35e1f-3ea4-4ed0-8be0-754db866fbc2	cmofl3ut6000hmjdmwqd3dziu	CHAITI BHATTACHARYA	Sundry Debtors	\N	\N	0.00	Unregistered
520b5e11-54c0-430a-bdf9-09fe311b622b	cmofl3ut6000hmjdmwqd3dziu	Chakrapani Dwivedi	Sundry Debtors	\N	\N	0.00	\N
45c8bf6d-c106-468d-ac83-da71de518fd6	cmofl3ut6000hmjdmwqd3dziu	Chanda Jeet Vishwakarma	Sundry Debtors	\N	\N	0.00	Unregistered
23b748e5-5cf8-451c-8de5-374218956eeb	cmofl3ut6000hmjdmwqd3dziu	CHANDI LAL	Sundry Debtors	\N	\N	0.00	Unregistered
744f7883-4c85-4238-afa9-c849ceb5b2e2	cmofl3ut6000hmjdmwqd3dziu	Chandra Bhan Singh	Sundry Debtors	\N	\N	0.00	\N
445b3ed5-9c58-4a5b-8a7c-4b3025f8f5dd	cmofl3ut6000hmjdmwqd3dziu	CHANDRA JEET VISHWAKARMA	Sundry Debtors	\N	\N	0.00	Unregistered
67ac1fca-f6a6-4fef-be58-8049eadbfc65	cmofl3ut6000hmjdmwqd3dziu	Chandra Mohan Prajapati	Sundry Debtors	\N	\N	0.00	Unregistered
9a8dba3d-2158-40a8-8739-ba743123ce7c	cmofl3ut6000hmjdmwqd3dziu	Chandraprabha	Sundry Debtors	\N	\N	0.00	Unregistered
cdb6caa5-b884-4f11-8731-f9ae3dc1962d	cmofl3ut6000hmjdmwqd3dziu	Chandra Prabha Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
cf778229-00c4-4be9-b167-e6124e472134	cmofl3ut6000hmjdmwqd3dziu	Chandra Prakash Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
af74a7f1-fb98-4cda-b30d-36358b502284	cmofl3ut6000hmjdmwqd3dziu	CHANDRA STEEL INDUSTRIES	Sundry Debtors	09AAVPK1635Q1ZU	\N	0.00	Regular
e6166a48-1af3-4721-bc5d-efcd8e71119f	cmofl3ut6000hmjdmwqd3dziu	CHAND TRADERS	Sundry Debtors	09AWMPC6508K1Z8	\N	0.00	Regular
7bc2dce9-b9f7-4cec-91e3-eae22a66a258	cmofl3ut6000hmjdmwqd3dziu	Chansi Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
7273c6b7-dda2-4d76-868e-bdc5bdf42848	cmofl3ut6000hmjdmwqd3dziu	Charan Singh	Sundry Debtors	\N	\N	0.00	Unregistered
a8358fcb-1e63-4dc2-901c-4138ff4af244	cmofl3ut6000hmjdmwqd3dziu	CHATURVEDI  ENTERPRISES	Sundry Debtors	09AUSPC0372K1ZC	\N	0.00	Regular
7452efe7-034c-49c1-bd85-714e6045bf88	cmofl3ut6000hmjdmwqd3dziu	CHAUDHARY CONSTRUCTION	Sundry Debtors	06AYEPC5912B1Z3	\N	0.00	Regular
d9b2326c-2526-437f-9c87-e83a221009bf	cmofl3ut6000hmjdmwqd3dziu	Chauhan Motors	Sundry Debtors	09EGRPS2019N1ZK	\N	0.00	Regular
a20032b8-0dd5-454a-9ff4-2a9cf327231e	cmofl3ut6000hmjdmwqd3dziu	Chauhan_Motors	Sundry Debtors	09JFJPS5946L1ZB	\N	0.00	Regular
168329ad-eead-42e6-9072-8844942beb3b	cmofl3ut6000hmjdmwqd3dziu	Chedi Lal	Sundry Debtors	\N	\N	0.00	Unregistered
3a2f812c-c0ea-4d31-b0de-895e7c5c2032	cmofl3ut6000hmjdmwqd3dziu	Chhota	Sundry Debtors	\N	\N	0.00	\N
ddf129c1-fdf0-4c56-934f-e037bd1b66fd	cmofl3ut6000hmjdmwqd3dziu	CHITRA BEEJ	Sundry Debtors	\N	\N	0.00	Unregistered
391e37c3-02e7-487c-8721-a1994254ae50	cmofl3ut6000hmjdmwqd3dziu	Cholamandalam MS General Insurance Company Limited	Sundry Creditors	\N	\N	0.00	\N
c91d5539-ec99-4ed2-a5fb-a0a4a5a1af42	cmofl3ut6000hmjdmwqd3dziu	CKE KITCHEN EQUIPMENT	Sundry Debtors	09APCPL0370D2Z9	\N	0.00	Regular
97be9f3d-5d17-4be1-826f-edc9355acfdc	cmofl3ut6000hmjdmwqd3dziu	Computer	Fixed Assets	\N	\N	-1435.20	Regular
98176cab-0cf9-4554-aeff-6fb20e4cbf95	cmofl3ut6000hmjdmwqd3dziu	Construction Engineers &amp; Assoicates	Sundry Debtors	09ACNPM1714A2ZW	\N	0.00	Regular
2e338af4-e8ef-49b6-af16-e081d6ee4c0f	cmofl3ut6000hmjdmwqd3dziu	Conveyance	Indirect Expenses	\N	\N	0.00	\N
78869e8b-19c3-4e80-8c71-6c26f8889562	cmofl3ut6000hmjdmwqd3dziu	CRESCENT STEEL PRODUCT	Sundry Debtors	09ARPPJ3743B1ZS	\N	0.00	Regular
40d7b3d7-5a51-4018-a574-3441e0fdae86	cmofl3ut6000hmjdmwqd3dziu	CRIISTEENA  MEDICAL AGENCIES	Sundry Debtors	09ASJPK8275E1ZC	\N	0.00	Regular
4b1be5ef-dc64-4db9-8711-0ac517d735c4	cmofl3ut6000hmjdmwqd3dziu	DAMBODAR ENTERPRISES	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
1113e4c9-48ab-4936-ba19-f3e33a1fe614	cmofl3ut6000hmjdmwqd3dziu	DAMODAR ENTERPRISES	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
7e8bafa5-5b2f-4ec9-ab86-2070a3961fe7	cmofl3ut6000hmjdmwqd3dziu	DASHRATH	Sundry Debtors	\N	\N	0.00	Unregistered
d81242a5-8cd8-4262-bbe7-0f8d6a7403ba	cmofl3ut6000hmjdmwqd3dziu	Daulat Devi Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
a1a5358b-4213-4ddb-88d9-33cb322c2187	cmofl3ut6000hmjdmwqd3dziu	Debit Note -18%	Purchase Accounts	\N	\N	0.00	\N
0d1c8be4-c157-4d0e-a96d-85f1d3384e98	cmofl3ut6000hmjdmwqd3dziu	Deepak	Sundry Debtors	\N	\N	0.00	Unregistered
dbe8eed4-f26c-46eb-8f64-814883add9e8	cmofl3ut6000hmjdmwqd3dziu	Deepak Dubey	Sundry Debtors	\N	\N	0.00	Unregistered
7e08cb7f-fefd-46c5-b836-a0998fbfdb65	cmofl3ut6000hmjdmwqd3dziu	DEEPAK KANOJIYA	Sundry Debtors	\N	\N	0.00	Unregistered
65d2775e-126c-4d89-8e10-333e02f1014f	cmofl3ut6000hmjdmwqd3dziu	Deepak Katiyar	Sundry Debtors	\N	\N	0.00	Unregistered
7dfa9a8c-ca6a-4bb1-af8e-07e9568c15ec	cmofl3ut6000hmjdmwqd3dziu	DEEPAK KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
6aa7fb47-02ef-4458-bc90-676f559287b6	cmofl3ut6000hmjdmwqd3dziu	Deepak Kumar Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
1e1c6de8-8023-4202-8510-f3005e13de50	cmofl3ut6000hmjdmwqd3dziu	Deepak Sachan	Sundry Debtors	\N	\N	0.00	Unregistered
00879b1a-4811-4288-b116-1e79a84ce289	cmofl3ut6000hmjdmwqd3dziu	DEEPAK SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
21d66cd6-57fe-41a5-b405-77206df767be	cmofl3ut6000hmjdmwqd3dziu	Deepawli and Poojan Expenses	Indirect Expenses	\N	\N	0.00	\N
95d76300-a1f9-4fe8-ae52-3335a2b8c808	cmofl3ut6000hmjdmwqd3dziu	Deepika Singh	Sundry Debtors	\N	\N	0.00	Unregistered
a3d747c3-d042-4bbf-9beb-76f54c721dee	cmofl3ut6000hmjdmwqd3dziu	Deep Sales Corporation	Sundry Debtors	09ACVPT9128M1ZD	\N	0.00	Regular
cb3d4576-5766-4928-b1c0-6abf3ac3784e	cmofl3ut6000hmjdmwqd3dziu	DEEP SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
26a2f28b-418b-4c04-99cf-aa027d1bc4aa	cmofl3ut6000hmjdmwqd3dziu	DEEPU	Sundry Debtors	\N	\N	0.00	Unregistered
f5884d0c-ea18-4b13-8e06-ad8d95f98a0d	cmofl3ut6000hmjdmwqd3dziu	Deprication	Indirect Expenses	\N	\N	0.00	\N
c50f1c04-0405-4d5f-9bce-15c7d3942cc0	cmofl3ut6000hmjdmwqd3dziu	DESIGN FORMIS	Sundry Debtors	\N	\N	0.00	\N
52f9c6c3-1c08-46d7-a21b-cb8779233d5b	cmofl3ut6000hmjdmwqd3dziu	DEVANS MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
78474893-33e5-46ee-9c68-1832279a1f88	cmofl3ut6000hmjdmwqd3dziu	Devendra	Sundry Debtors	\N	\N	0.00	Unregistered
aaf4a67f-e203-47c7-b529-fc78f9aed19d	cmofl3ut6000hmjdmwqd3dziu	Devi Prasad	Sundry Debtors	\N	\N	0.00	Unregistered
a464d90c-f159-4c16-befc-0e3a7d19ad7a	cmofl3ut6000hmjdmwqd3dziu	Dev Narayan	Sundry Debtors	\N	\N	0.00	Unregistered
b20daff7-286c-4de9-b456-4fc6195f1d51	cmofl3ut6000hmjdmwqd3dziu	Dev Traders	Sundry Debtors	\N	\N	0.00	\N
16a626d9-3828-49d6-ba42-78a17a7bf35a	cmofl3ut6000hmjdmwqd3dziu	Dhanjay Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
db356c55-c954-4742-a2b9-e4e33789d13a	cmofl3ut6000hmjdmwqd3dziu	Dharam Chand Dwarka Das Agarwal	Sundry Creditors	09AAEFD2649G1ZG	\N	0.00	Regular
95f059d5-ed35-4789-bb9f-ded85c2a2a9e	cmofl3ut6000hmjdmwqd3dziu	Dharmendra Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
dc0d6afb-08f7-4882-a877-637da0e59c72	cmofl3ut6000hmjdmwqd3dziu	Dharmendra Kumar Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
f5890bea-e0ee-4d3e-bbbc-c6823e27a911	cmofl3ut6000hmjdmwqd3dziu	DHARMENDRA KUMAR SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
677d2878-b01f-4aac-ad86-9fc101345c10	cmofl3ut6000hmjdmwqd3dziu	DHEERAJ CHUGHA	Sundry Debtors	\N	\N	0.00	Unregistered
347b8916-52d5-4a2c-aa83-c1063536b95f	cmofl3ut6000hmjdmwqd3dziu	Dheer Singh	Sundry Debtors	\N	\N	0.00	Unregistered
a33b5809-b51e-4de4-abd0-18466f1af17d	cmofl3ut6000hmjdmwqd3dziu	Dhirendra  Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
07437462-a839-4fd1-bc12-e0333fe3cd62	cmofl3ut6000hmjdmwqd3dziu	DHUPER CHEMICALS PVT LTD	Sundry Debtors	09AAACD5802G1ZX	\N	0.00	Regular
9d01e677-9cec-40fe-bd49-16976e1f717c	cmofl3ut6000hmjdmwqd3dziu	Digvijay Singh	Sundry Debtors	\N	\N	0.00	Unregistered
22d501d7-732b-4e21-be77-20c497358f2d	cmofl3ut6000hmjdmwqd3dziu	DIGVIJAY SINGH YADAVA	Sundry Debtors	\N	\N	0.00	Unregistered
874b5b9d-308c-4ef4-aeac-6ba032063fa4	cmofl3ut6000hmjdmwqd3dziu	Diksha Srivastava	Sundry Debtors	\N	\N	0.00	Unregistered
f5229d0e-910e-41c1-aad1-54fd169d3c3c	cmofl3ut6000hmjdmwqd3dziu	Dileep Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
8e10dcb5-72f4-4bf3-971a-5fe8b991b805	cmofl3ut6000hmjdmwqd3dziu	DILEEP SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
a3153827-ab0f-4efd-9888-f323d207c396	cmofl3ut6000hmjdmwqd3dziu	DILIP KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
6087efc8-35ea-4362-b466-7500945547cb	cmofl3ut6000hmjdmwqd3dziu	Dilip_ Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
115d815d-c09b-4693-8c6d-269a381ff3be	cmofl3ut6000hmjdmwqd3dziu	DINESH GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
a065740d-e3de-4e05-a361-8a88244c7098	cmofl3ut6000hmjdmwqd3dziu	Dinesh Kumar	Sundry Debtors	\N	\N	0.00	\N
a3b43fca-ce12-4baf-aa19-65339a114593	cmofl3ut6000hmjdmwqd3dziu	DINESH KUMAR GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
3a2ed253-e2c4-49ad-a5e4-9e19753cf368	cmofl3ut6000hmjdmwqd3dziu	Dinesh Kumar Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
5e24ae88-8c9b-4dcb-b89c-b2770fc0d0b2	cmofl3ut6000hmjdmwqd3dziu	DINESH MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
a3ea031c-78b0-4165-b6e6-fad5a8ca97de	cmofl3ut6000hmjdmwqd3dziu	Dinesh Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
18394020-b3b5-44fe-ade0-389270e4ae24	cmofl3ut6000hmjdmwqd3dziu	Dipak Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
1eab08e4-2845-45fe-af5a-a8208a000161	cmofl3ut6000hmjdmwqd3dziu	Dipendra Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
fe2d145a-1e4a-4b1e-a4e2-75ff7b276dc8	cmofl3ut6000hmjdmwqd3dziu	Discount	Indirect Incomes	\N	\N	0.00	\N
4eded0c3-ba27-4ce7-93f6-e9eb4a784482	cmofl3ut6000hmjdmwqd3dziu	Divident	Indirect Incomes	\N	\N	0.00	\N
123e620e-009e-42cb-a020-15243499001b	cmofl3ut6000hmjdmwqd3dziu	Divine Exports	Sundry Debtors	09EZYPS3594G1Z7	\N	0.00	Regular
a04dcbe2-4649-4285-b785-cbbb853e7c9e	cmofl3ut6000hmjdmwqd3dziu	Divine Synthetics Pvt Ltd	Sundry Debtors	09AABCN3981F1ZC	\N	0.00	Regular
dc01079a-9c45-4be1-a456-e63e090222ce	cmofl3ut6000hmjdmwqd3dziu	Divya Enterprises	Sundry Debtors	09AAUPY6249B1Z0	\N	0.00	Regular
c4822780-436a-4915-a2b4-5de8a7a6e5c1	cmofl3ut6000hmjdmwqd3dziu	DIVYAKANT TRIVEDI	Sundry Debtors	\N	\N	0.00	Unregistered
a3175839-3777-4733-91f4-ae2c7331faed	cmofl3ut6000hmjdmwqd3dziu	DIVYANSH	Sundry Debtors	\N	\N	0.00	Unregistered
e46d2e18-b394-4eb9-902b-ab05040a1beb	cmofl3ut6000hmjdmwqd3dziu	D.O. Construction Company	Sundry Debtors	09AJBPT4608B1ZE	\N	0.00	Regular
6be37ce6-c777-4510-bfe3-211d0431739b	cmofl3ut6000hmjdmwqd3dziu	DOLLY CONSTRUCTION CO.	Sundry Debtors	09BQRPS3630L1Z3	\N	0.00	Regular
a1817c74-a4cb-4faa-a7cb-197b7ad0e97d	cmofl3ut6000hmjdmwqd3dziu	D P SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
491044ce-50c9-44e5-aec8-793ad728ae9a	cmofl3ut6000hmjdmwqd3dziu	Drawing	Capital Account	\N	\N	1024632.87	Unregistered
76859177-6427-4470-bea7-f3e9df4d1a51	cmofl3ut6000hmjdmwqd3dziu	D S BAGHEL	Sundry Debtors	\N	\N	0.00	Unregistered
126f5de7-6a3f-4f18-8325-8d92e0674c56	cmofl3ut6000hmjdmwqd3dziu	Durga Prasad Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
4b06c751-ac60-4310-9f17-1a8c69ce845c	cmofl3ut6000hmjdmwqd3dziu	DURGESH KUMAR DUBEY	Sundry Debtors	\N	\N	0.00	Unregistered
f3174c15-6120-4b1d-bb71-71dc77f8db08	cmofl3ut6000hmjdmwqd3dziu	Durgesh Kumar Jha	Sundry Debtors	\N	\N	0.00	Unregistered
8193de63-454d-448c-a282-6e8950039ac8	cmofl3ut6000hmjdmwqd3dziu	DURGESH PRAKSH GAUTAM	Sundry Debtors	\N	\N	0.00	Unregistered
58156851-cd12-47ab-876a-cf3b2dab4667	cmofl3ut6000hmjdmwqd3dziu	Ecoplus Steels Pvt Ltd	Sundry Creditors	09AAECP7598M1ZF	\N	0.00	Regular
bab2ba89-dfbc-412a-b7ea-da7db7288dde	cmofl3ut6000hmjdmwqd3dziu	EKATAH SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
81111a4f-2240-4bff-9db6-2011efc7189a	cmofl3ut6000hmjdmwqd3dziu	Electricity Expenes Payable	Current Liabilities	\N	\N	0.00	Regular
be207af5-f870-4324-ac58-5d1b77fb6f1a	cmofl3ut6000hmjdmwqd3dziu	Electricity Expenses	Indirect Expenses	\N	\N	0.00	\N
5282b3c2-0b28-47a8-b777-9304fb3a1698	cmofl3ut6000hmjdmwqd3dziu	Electronic Weight Scale	Fixed Assets	\N	\N	-23337.60	\N
0d9e158a-7701-4c0a-9529-7fe272d2219b	cmofl3ut6000hmjdmwqd3dziu	Engineers Wizard	Sundry Debtors	07ATGPN0144B1Z8	\N	0.00	Regular
6ea7f948-8f6b-4167-9b7b-499e6540f257	cmofl3ut6000hmjdmwqd3dziu	ENVIROCRAT CONSULTANCY SERVICES	Sundry Debtors	09ABOPY8055A2Z5	\N	0.00	Regular
4c62bbc9-e5b8-4a01-8da4-b280e4a6dcd0	cmofl3ut6000hmjdmwqd3dziu	EPC PERFECT PRIVATE LIMITED	Sundry Debtors	\N	\N	0.00	\N
65989c79-9256-4ce8-a39c-9298ea56ed52	cmofl3ut6000hmjdmwqd3dziu	ERTYUIO	Sundry Debtors	\N	\N	0.00	Regular
dced71bf-8345-4c38-a016-b6d40550f0e1	cmofl3ut6000hmjdmwqd3dziu	EXCELLENCE INDIA ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
68c50f25-c52b-41f8-ac8b-af502c6002d3	cmofl3ut6000hmjdmwqd3dziu	Faishal Raodlines	Sundry Creditors for Transporter	19GUWPS6677D1ZG	\N	0.00	Regular
49f8f614-505b-4bd9-853e-f13b0be62ab7	cmofl3ut6000hmjdmwqd3dziu	FDR WITH HDFC	Investments	\N	\N	-2282809.94	\N
6622d1e1-3ec7-4307-991f-30924edc8af8	cmofl3ut6000hmjdmwqd3dziu	FDR WITH PNB	Investments	\N	\N	0.00	\N
b5dfd377-107c-47e5-acd8-d3b67b41709e	cmofl3ut6000hmjdmwqd3dziu	F D WITH UNION BANK OF INDIA	Investments	\N	\N	-663600.00	\N
7ff30057-8423-448c-bf01-8b07d83df2e1	cmofl3ut6000hmjdmwqd3dziu	Flat1/2-----------Harsh Nagar	Fixed Assets	\N	\N	-340000.00	\N
4413eb94-bec3-45bf-a19e-6fcbab5673b3	cmofl3ut6000hmjdmwqd3dziu	Freight  Advance	Direct Expenses	\N	\N	0.00	\N
f7c42485-a952-45e2-90c7-977852fcda16	cmofl3ut6000hmjdmwqd3dziu	Freight Advance-18% Gst	Direct Expenses	\N	\N	0.00	\N
6ac2f6c8-976d-46e6-8086-5887c321f98d	cmofl3ut6000hmjdmwqd3dziu	Freight and Cartage Ex Up (Rcm A/c)	Direct Expenses	\N	\N	0.00	\N
bb9eeeee-dc8f-4ae9-b48e-e98151385fd9	cmofl3ut6000hmjdmwqd3dziu	FREIGHT AND CARTAGE IGST ON PURCHASE	Direct Expenses	\N	\N	0.00	\N
3842e41e-6d3f-4b48-a927-ab4504615215	cmofl3ut6000hmjdmwqd3dziu	Freight and Cartage Inward	Direct Expenses	\N	\N	0.00	\N
97511cc1-efdb-4001-940a-820ade075dec	cmofl3ut6000hmjdmwqd3dziu	FREIGHT AND CARTAGE INWARD A/C	Direct Expenses	\N	\N	0.00	\N
02fdba82-36f0-4129-913f-9d6ddada9c22	cmofl3ut6000hmjdmwqd3dziu	FREIGHT AND CARTAGE INWARD (Rcm)	Direct Expenses	\N	\N	0.00	\N
39e8cd69-2729-4849-aa6b-699521abda38	cmofl3ut6000hmjdmwqd3dziu	Freight and Cartage Outward	Indirect Incomes	\N	\N	0.00	\N
ce48662c-4863-4ac0-a85c-7b2933ff41d2	cmofl3ut6000hmjdmwqd3dziu	Freight on Sale	Sales Accounts	\N	\N	0.00	\N
1c418d14-18cf-4fdf-8515-bac329bf92a5	cmofl3ut6000hmjdmwqd3dziu	Freight on Sale Gst	Indirect Incomes	\N	\N	0.00	\N
d9645200-3e5a-4ed9-a82d-f738877841d2	cmofl3ut6000hmjdmwqd3dziu	Fridge	Fixed Assets	\N	\N	-39951.53	Unregistered
b3fe0655-ae3e-4390-bbd2-f1ad9f46f438	cmofl3ut6000hmjdmwqd3dziu	Fridge-Gst	Fixed Assets	\N	\N	0.00	\N
f85a13b2-20cd-48b2-82b8-5cd054346465	cmofl3ut6000hmjdmwqd3dziu	Gajanan Traders	Sundry Debtors	09EGEPS4728D1Z6	\N	0.00	Regular
c7197aee-5c5f-4548-9f6e-d07e1858a4c4	cmofl3ut6000hmjdmwqd3dziu	GAJENDRA KUMAR SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
20dbe441-88b3-4b2e-a388-cfea1b70e601	cmofl3ut6000hmjdmwqd3dziu	GALANT ISPAT LIMITED	Sundry Creditors	09AACCG2969B1ZO	\N	0.00	Regular
a515347e-2e94-47eb-91e9-b71b5872b43d	cmofl3ut6000hmjdmwqd3dziu	GALLANTT ISPAT LIMITED-GORAKHPUR	Sundry Creditors	09AACCG2934JIZI	\N	0.00	Regular
291de1a9-bd0f-4a9d-8f07-69817c442a35	cmofl3ut6000hmjdmwqd3dziu	GANGA DEVI	Sundry Debtors	\N	\N	0.00	Unregistered
534839f4-8e37-4e9c-9516-a87b94c40037	cmofl3ut6000hmjdmwqd3dziu	Ganga Gamuna Roadways	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
3f33dbc4-a3c0-4f62-8ed9-869f3f171345	cmofl3ut6000hmjdmwqd3dziu	Ganga Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
58ff555a-d7cf-4dc5-86d5-1f347c8933fc	cmofl3ut6000hmjdmwqd3dziu	Ganpati Cargo Movers	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
405d0ae4-f3d4-44dd-ac9d-4dcce1f8ac14	cmofl3ut6000hmjdmwqd3dziu	GARIMA MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
16cd83b7-eabc-49ad-a972-4a9f86d2ff82	cmofl3ut6000hmjdmwqd3dziu	Gaurav	Sundry Debtors	\N	\N	0.00	Unregistered
205d5547-af9c-47d8-924e-6b18a9ea4ce7	cmofl3ut6000hmjdmwqd3dziu	GAURAV CONSTRUCTION	Sundry Debtors	09AHCPD2024J1ZR	\N	0.00	Regular
9f101a7e-4527-44a2-bb9b-66917bad9433	cmofl3ut6000hmjdmwqd3dziu	Gaurav Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
b88dcae8-7d72-4455-83ab-f86dc722d6f1	cmofl3ut6000hmjdmwqd3dziu	Gaurav Singh	Sundry Debtors	\N	\N	0.00	Unregistered
8395ae72-460e-4e44-89c3-cf9179465dcb	cmofl3ut6000hmjdmwqd3dziu	Gaurav Singh Chauhan	Sundry Debtors	\N	\N	0.00	Unregistered
2dc867e8-8df0-49ef-befa-c79f3d2dea40	cmofl3ut6000hmjdmwqd3dziu	Gauri Iron &amp; Steel Co.	Sundry Creditors	19AARFG6285C1ZZ	\N	0.00	Regular
9482bc63-07fd-4e1e-b49b-4c040fceb820	cmofl3ut6000hmjdmwqd3dziu	Gaurishanker Vishwanath Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
235053e5-fa9f-4904-af0f-715597113779	cmofl3ut6000hmjdmwqd3dziu	Gaurv Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
b11731b8-ef15-4150-bb8f-4ad5e092813f	cmofl3ut6000hmjdmwqd3dziu	GAYATRI CONSTRUCTION	Sundry Debtors	09AIKPM0033H1ZF	\N	0.00	Regular
d7e6c5a5-e3a2-4ab6-a75f-9db03c436da3	cmofl3ut6000hmjdmwqd3dziu	Gayatri Devi Indrapratap	Sundry Debtors	\N	\N	0.00	Unregistered
3ed5a3a3-e9a7-41d4-9ad2-dbde47e78b27	cmofl3ut6000hmjdmwqd3dziu	GBA  STEELS&amp; METALS PVT LTD	Sundry Creditors	09AADCG7353E1ZL	\N	0.00	Regular
b71b7ab1-b068-4459-bb5f-65c792908b6c	cmofl3ut6000hmjdmwqd3dziu	GDS Infrastructure Pvt Ltd	Sundry Debtors	\N	\N	0.00	Regular
f6245187-6e33-4141-a63d-fcc9795e8f77	cmofl3ut6000hmjdmwqd3dziu	GEETA ENTERPRISES	Sundry Debtors	\N	\N	0.00	Unregistered
ccb43e58-48ff-4548-9c8b-cbe285a834be	cmofl3ut6000hmjdmwqd3dziu	Vijay Kumar	Sundry Debtors	\N	\N	0.00	\N
c34948a7-0630-4f5c-8469-2d648415030a	cmofl3ut6000hmjdmwqd3dziu	GERA TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
7e06530e-4170-40f6-85de-803264d206c0	cmofl3ut6000hmjdmwqd3dziu	Ghanshyam Singh	Sundry Debtors	\N	\N	0.00	Unregistered
7d7c5193-6ddc-4e91-91b8-91584f27c953	cmofl3ut6000hmjdmwqd3dziu	Ghanshyam Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
de31d802-70c6-4d54-8461-9eaaa7734a3c	cmofl3ut6000hmjdmwqd3dziu	Giriraj Narayan Agarwal	Sundry Debtors	\N	\N	0.00	\N
9f72fad2-98d1-4bcf-a07e-0dad38b43d5f	cmofl3ut6000hmjdmwqd3dziu	GIRISH KUMAR TIWARI	Sundry Debtors	\N	\N	0.00	Unregistered
47d6ab5c-1102-473d-add2-b91b83ea53d1	cmofl3ut6000hmjdmwqd3dziu	GIRJA DEVI	Sundry Debtors	\N	\N	0.00	Unregistered
cd9d10fd-349d-48a7-9fae-b20ba4960b0e	cmofl3ut6000hmjdmwqd3dziu	GLOBAL ANALYTICAL AND RESEARCH LABS PRIVATE LIMITED	Sundry Debtors	\N	\N	0.00	\N
61ebfd63-c901-41cf-b438-6a70703d0fa7	cmofl3ut6000hmjdmwqd3dziu	Global Enterprises	Sundry Debtors	09AAKFG9770D1Z1	\N	0.00	Regular
7b992b3d-ab1a-47d8-9d96-8c22d84f2acd	cmofl3ut6000hmjdmwqd3dziu	GLOBAL MARKETING	Sundry Debtors	\N	\N	0.00	Regular
63cabdb7-b4a8-4a2d-babf-89c1ceb01d8c	cmofl3ut6000hmjdmwqd3dziu	G N BUILDER	Sundry Debtors	09AAXFG4852F1ZV	\N	0.00	Regular
7f6f4e84-d5ca-4de6-b8a3-08fc19387615	cmofl3ut6000hmjdmwqd3dziu	GODREJ AND BOYCE MANUFACTURING CO LTD	Sundry Debtors	09AAACG1395D1ZS	\N	0.00	Regular
40974e33-2239-4b95-9cdf-555cdbe9246d	cmofl3ut6000hmjdmwqd3dziu	GOLDEN TRIO LLP	Sundry Debtors	\N	\N	0.00	Unregistered
40e9e1cc-bedc-4265-8907-cbd1def9a316	cmofl3ut6000hmjdmwqd3dziu	GOLD PURCHASE	Investments	\N	\N	0.00	\N
5bd8242f-2d29-4aa4-a6dd-b046186898ac	cmofl3ut6000hmjdmwqd3dziu	Gold Steels	Sundry Creditors	09AASFG6902D1Z9	\N	0.00	Regular
fed28cfa-baf3-4056-a741-3bdbe9be868a	cmofl3ut6000hmjdmwqd3dziu	Gonda Bahraich  Transport Service	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
e6c8e6b5-e46a-4c62-bc74-a6655e4ce295	cmofl3ut6000hmjdmwqd3dziu	GOODLUCK CONSTRUCTION COMPANY	Sundry Debtors	09CJCPB5424J2ZB	\N	0.00	Regular
cad272e5-672a-4908-aa64-8334cd661fe5	cmofl3ut6000hmjdmwqd3dziu	Gopal Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
10a624d2-63a5-492d-83c7-02055c206964	cmofl3ut6000hmjdmwqd3dziu	Gopal Swaroop Agarwal	Sundry Debtors	\N	\N	0.00	Unregistered
d9a7bd93-c3c5-40c8-b8ed-7ff70f6b0583	cmofl3ut6000hmjdmwqd3dziu	Govind	Sundry Debtors	\N	\N	0.00	Unregistered
2792ef51-ff30-4894-a42e-35e300d13b1b	cmofl3ut6000hmjdmwqd3dziu	Govind Das	Sundry Debtors	\N	\N	0.00	Unregistered
2208216d-e312-4bc9-a8c5-39c49d3a5a0a	cmofl3ut6000hmjdmwqd3dziu	GOVIND HARI SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
d8ad66ad-eb57-4d3b-8152-e01ac72a723a	cmofl3ut6000hmjdmwqd3dziu	GOVIND TRADERS	Sundry Debtors	09FPVPS5695E2ZQ	\N	0.00	Regular
b4bdb45b-a050-48f1-849c-4832c722422d	cmofl3ut6000hmjdmwqd3dziu	GOYAL TRADERS	Sundry Debtors	\N	\N	0.00	Unregistered
81a06846-cd9d-4c03-8c40-587bc4e97565	cmofl3ut6000hmjdmwqd3dziu	GRAVITY  FERROUS PVT LTD	Sundry Creditors	22AACCG3005C1ZL	\N	0.00	Regular
86b9977b-5aa2-4405-882d-709c3edf92c1	cmofl3ut6000hmjdmwqd3dziu	GRAVITY FERROUS PVT LTD 9UNIT-IIND)	Sundry Creditors	22AACCG3005C3ZJ	\N	0.00	Regular
0592a4cd-e167-4067-bb61-73bbccc26d92	cmofl3ut6000hmjdmwqd3dziu	Growmore  Enterprises	Sundry Creditors for Transporter	\N	\N	0.00	\N
4674d0b3-3b43-4b7a-ae02-ef435c6a5e3a	cmofl3ut6000hmjdmwqd3dziu	G S SALES CORPORATION	Sundry Creditors	22APIPA8189H1ZU	\N	0.00	Regular
2ccf9ff5-c626-4fda-9eeb-e268727a018f	cmofl3ut6000hmjdmwqd3dziu	G.S. STEELS	Sundry Debtors	09AAEFG9377J1ZR	\N	0.00	Regular
45f08ddc-f86d-4157-83d1-2ebbe9a24594	cmofl3ut6000hmjdmwqd3dziu	Gst Cash Ledger	Loans & Advances (Asset)	\N	\N	-10000.00	Unregistered
5d9c68ff-9418-4814-a0b3-4bff3a794630	cmofl3ut6000hmjdmwqd3dziu	GST Demand(2019-2020)	Indirect Expenses	\N	\N	0.00	\N
da589c2a-6549-4cb5-b936-7eefc4c0ee99	cmofl3ut6000hmjdmwqd3dziu	GST Demand(21-22)	Indirect Expenses	\N	\N	0.00	\N
6e0db7c1-e543-4242-ad56-e7cc55fe9c5d	cmofl3ut6000hmjdmwqd3dziu	GST Late Fee and Interest Charges	Indirect Expenses	\N	\N	0.00	\N
80d6ef06-b98f-4515-be16-54856c497c5d	cmofl3ut6000hmjdmwqd3dziu	GST Payable	Provisions	\N	\N	51492.00	\N
55549169-1e1d-4c2a-8c09-871e90f27e99	cmofl3ut6000hmjdmwqd3dziu	GST Payable on RCM	Duties & Taxes	\N	\N	-3018.00	\N
2892b67a-9ca3-4d01-8cb4-63dfcf8d4c4f	cmofl3ut6000hmjdmwqd3dziu	GST PENALTY AND TAX	Deposits (Asset)	\N	\N	0.00	Unregistered
fbc9b3a7-4059-49a7-9428-f1a974491fdc	cmofl3ut6000hmjdmwqd3dziu	GST Receivable	Duties & Taxes	\N	\N	0.00	\N
d2f52dcb-771b-4d7d-bb9a-d7dc756f61d0	cmofl3ut6000hmjdmwqd3dziu	GST SALE	Sales Accounts	\N	\N	0.00	\N
033a153c-01c3-4fa4-be00-83e26b5c3b68	cmofl3ut6000hmjdmwqd3dziu	GST SALES	Sales Accounts	\N	\N	0.00	\N
e90cfd49-79ee-406f-92b6-7aa2d537f4f7	cmofl3ut6000hmjdmwqd3dziu	GUDDU SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
6b310083-42b2-4730-9860-049d5a5e366b	cmofl3ut6000hmjdmwqd3dziu	GUNI STEELS	Sundry Debtors	09ANCPD3065D1ZG	\N	0.00	Regular
2cdd0f8f-dfd6-4bd5-a760-458745cb98c1	cmofl3ut6000hmjdmwqd3dziu	Guru Nanak Public School	Sundry Debtors	\N	\N	0.00	\N
806500ff-467c-42ec-aeeb-0162bb8bc05d	cmofl3ut6000hmjdmwqd3dziu	Guru Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
8c11ae38-27f2-485b-a529-bcd85790dad7	cmofl3ut6000hmjdmwqd3dziu	GYANENDRA SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
6eb9fbe8-0a58-4e39-a03a-6273e30a53fa	cmofl3ut6000hmjdmwqd3dziu	GYAN PRATAP SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
4fb0bcd2-cc8f-4b09-80bc-b22e746fec80	cmofl3ut6000hmjdmwqd3dziu	HANUMAN HARDWARE &amp; PAINT STORE	Sundry Debtors	09AAPPA2200D1ZE	\N	0.00	Regular
2bcf32f7-8e2b-40b8-93a3-336842a56ce9	cmofl3ut6000hmjdmwqd3dziu	Harendra Singh	Sundry Debtors	\N	\N	0.00	Unregistered
c61e5fdd-1496-4b8e-9404-4f95ee18529a	cmofl3ut6000hmjdmwqd3dziu	HARI KRISHNA CHOUDHARY	Sundry Debtors	\N	\N	0.00	Unregistered
aa804edc-40d9-49e5-925d-ed4fb402db0d	cmofl3ut6000hmjdmwqd3dziu	HARI MOHAN Shukla	Sundry Debtors	\N	\N	0.00	Unregistered
36c8b595-b812-44f5-9e26-0b742e483c84	cmofl3ut6000hmjdmwqd3dziu	Hari Om	Sundry Debtors	\N	\N	0.00	Unregistered
c7af51b2-dfd2-4b22-bec5-40654b6cb855	cmofl3ut6000hmjdmwqd3dziu	Harish Chandra Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
46919bd9-1031-4469-ae2c-cacb31266c71	cmofl3ut6000hmjdmwqd3dziu	Harish Chandra Pal	Sundry Debtors	\N	\N	0.00	Unregistered
02cc6938-04a6-46a9-a509-8945b339d356	cmofl3ut6000hmjdmwqd3dziu	HARI SINGH YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
6ef4803f-af8e-4708-aa7c-b24dfccb35d6	cmofl3ut6000hmjdmwqd3dziu	Hariyana  Punjab Roadways	Sundry Creditors for Transporter	\N	\N	0.00	\N
bce65ba2-f934-4bfe-9d29-b791ad51bbeb	cmofl3ut6000hmjdmwqd3dziu	HARSHIT	Sundry Debtors	\N	\N	0.00	Unregistered
1e8f1c01-3d02-4665-b575-c72f3036bdd4	cmofl3ut6000hmjdmwqd3dziu	Harshit Dwivedi	Sundry Debtors	\N	\N	0.00	\N
56c81d92-1756-421f-a76f-859c93ad8053	cmofl3ut6000hmjdmwqd3dziu	HARSH KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
efc16a86-7038-4145-b860-02d9b7246661	cmofl3ut6000hmjdmwqd3dziu	HASAN IRON ENTERPRISES	Sundry Debtors	09EFSPA2360N1ZZ	\N	0.00	Regular
9a8d7b6b-cabd-4620-86e4-feebaab257b1	cmofl3ut6000hmjdmwqd3dziu	Haseeb Akhatar	Sundry Debtors	\N	\N	0.00	Unregistered
895cdf46-8af3-4aef-a178-8a185aaeea2d	cmofl3ut6000hmjdmwqd3dziu	H A STEELS	Sundry Debtors	\N	\N	0.00	\N
9ca48be2-e996-41b2-891f-342173b4f918	cmofl3ut6000hmjdmwqd3dziu	HAVALDAR CHANDRA BHAN	Sundry Debtors	\N	\N	0.00	Unregistered
91e992a0-54fc-44f7-8629-df51f2d9311e	cmofl3ut6000hmjdmwqd3dziu	Hemant	Sundry Debtors	\N	\N	0.00	\N
3b0b878b-8d67-42de-ade4-b74c816d184e	cmofl3ut6000hmjdmwqd3dziu	Hetvi Construction LLP	Sundry Debtors	09AAKFH9232M1ZS	\N	0.00	Regular
de9309d1-4f89-47ff-9195-39ecafe177ab	cmofl3ut6000hmjdmwqd3dziu	Himalaya Goods Carrier	Sundry Creditors for Transporter	19AKQPS6471H1ZC	\N	0.00	Regular
de0f2f6c-5a92-4532-8e4b-374ae84c492b	cmofl3ut6000hmjdmwqd3dziu	Himanshu	Sundry Debtors	\N	\N	0.00	\N
dccfe872-8bdd-463e-a7ed-5783379305b8	cmofl3ut6000hmjdmwqd3dziu	Himansu Gangwar	Sundry Debtors	\N	\N	0.00	Unregistered
f17edd2f-33c8-4ea8-ba59-1f35f1775580	cmofl3ut6000hmjdmwqd3dziu	HIND MOULDING WORKS	Sundry Debtors	09ABDPH9515R1Z0	\N	0.00	Regular
c22c36b8-29ea-438d-85ee-a8727bec490f	cmofl3ut6000hmjdmwqd3dziu	HINDUSTAN TRADERS	Sundry Debtors	\N	\N	0.00	Unregistered
f6026442-44df-46e3-9288-17dcd162f931	cmofl3ut6000hmjdmwqd3dziu	HIRENDRA SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
597a3518-8ad5-48f2-8ed7-314989a489f5	cmofl3ut6000hmjdmwqd3dziu	Hi -Tech Power and Steel Limited	Sundry Creditors	22AACCM8028R1Z3	\N	0.00	Regular
7f53b6fe-52f2-4ca3-83e5-3ecfc315b0cb	cmofl3ut6000hmjdmwqd3dziu	Home Loan	Indirect Expenses	\N	\N	0.00	\N
458cde63-a0f4-4d17-98c2-cc9663f483ee	cmofl3ut6000hmjdmwqd3dziu	HORCE CENTRE	Sundry Debtors	09AACFH9557P1ZI	\N	0.00	Regular
920d476b-9d18-4c25-af20-62da7e29fabb	cmofl3ut6000hmjdmwqd3dziu	Hridesh Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
71597eab-4aa2-40e4-b7a7-42c29d43c3de	cmofl3ut6000hmjdmwqd3dziu	Ichchha	Sundry Debtors	\N	\N	0.00	\N
793087af-83ca-43fa-86d9-3ceaf5357a63	cmofl3ut6000hmjdmwqd3dziu	IGST	Duties & Taxes	\N	\N	0.00	\N
01c42693-f695-4467-a315-d01314dd3546	cmofl3ut6000hmjdmwqd3dziu	IGST @ 18% on Purchase	Duties & Taxes	\N	\N	0.00	\N
0d94c4aa-def5-47f5-847c-b49fb7e2a330	cmofl3ut6000hmjdmwqd3dziu	IGST OUTWARD @ 18%	Duties & Taxes	\N	\N	0.00	\N
a82f0f3c-6140-4558-8d79-5235db5e9e13	cmofl3ut6000hmjdmwqd3dziu	Igst Payable	Provisions	\N	\N	0.00	\N
bc9028fa-8e38-4a2e-9cd4-82ebd8baee81	cmofl3ut6000hmjdmwqd3dziu	IGST RCM	Duties & Taxes	\N	\N	0.00	\N
85762346-09d1-467f-b7e0-c886aed60811	cmofl3ut6000hmjdmwqd3dziu	IGST TO BE CLAIMED	Duties & Taxes	\N	\N	0.00	\N
d336b044-2a92-4179-adce-d765276e3343	cmofl3ut6000hmjdmwqd3dziu	I I  F L SECURITIES	Deposits (Asset)	\N	\N	0.00	Unregistered
9379c8c6-1046-4178-be40-aee7dc4d8e07	cmofl3ut6000hmjdmwqd3dziu	IMAGINE	Sundry Debtors	09AFYPB3393L1ZP	\N	-247583.00	Regular
6f47a572-6ea2-4e7f-9edc-fa9f6c844554	cmofl3ut6000hmjdmwqd3dziu	IMPEX CORPORATION	Sundry Creditors	09ACDPT2952P1ZV	\N	0.00	Regular
26a5a6fd-1007-49b6-8aca-d535fe22a8f6	cmofl3ut6000hmjdmwqd3dziu	INCOME TAX FILING CHARGES	Indirect Expenses	\N	\N	0.00	\N
5059344d-76a5-4993-97b0-33221e0ce7c0	cmofl3ut6000hmjdmwqd3dziu	INDER RAJ SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
1f690a5f-06c4-427d-8b06-393bb56dc0dc	cmofl3ut6000hmjdmwqd3dziu	INDIA AGRO FOOD INDUSTRIES	Sundry Debtors	09LPNPS4670D1Z6	\N	0.00	Regular
4d15b6d0-50dd-472f-aad1-84be1b2e2be6	cmofl3ut6000hmjdmwqd3dziu	INELIGIBALE ITC-	Indirect Expenses	\N	\N	0.00	\N
7168400c-87b8-4272-8701-7c48b3a3f2c1	cmofl3ut6000hmjdmwqd3dziu	Infiniti Retail Limited K	Sundry Creditors	09AACCV1726H1	\N	0.00	Regular
d83572c0-3386-4e81-9334-d7d6679570db	cmofl3ut6000hmjdmwqd3dziu	INSURANCE ACCOUNT	Indirect Expenses	\N	\N	0.00	\N
5c842ead-a9d1-4e9d-bb19-c54854c1da1a	cmofl3ut6000hmjdmwqd3dziu	INSURANCE IGST	Indirect Expenses	\N	\N	0.00	\N
4c5a47d3-be06-4046-8044-a2447153420e	cmofl3ut6000hmjdmwqd3dziu	INSURANCE on Local Purchase	Indirect Expenses	\N	\N	0.00	\N
011822e4-dbbb-4f8f-9500-1bb5c82add53	cmofl3ut6000hmjdmwqd3dziu	INSURANCE on Purchase	Indirect Expenses	\N	\N	0.00	\N
46fd4d26-2039-437c-a978-c57cefbeeb1f	cmofl3ut6000hmjdmwqd3dziu	Insurance Scooty	Indirect Expenses	\N	\N	0.00	\N
5bee2d92-fffb-4b4f-ade6-a7e0e9b24fdd	cmofl3ut6000hmjdmwqd3dziu	INTEREST &amp; LATE FEE ON GST	Indirect Expenses	\N	\N	0.00	\N
79082229-f7c8-4974-9918-30676b8d9582	cmofl3ut6000hmjdmwqd3dziu	Interest on Fdr	Indirect Incomes	\N	\N	0.00	\N
eb8ecd2e-6cfc-4b2a-9ae4-ac631d2d9c2c	cmofl3ut6000hmjdmwqd3dziu	Interest on Gst	Indirect Expenses	\N	\N	0.00	\N
bef60dec-3531-410a-89a0-cf8bf463a232	cmofl3ut6000hmjdmwqd3dziu	INTEREST ON PPF A/C	Indirect Incomes	\N	\N	0.00	\N
841c71fc-6424-4f6c-a3db-77dede4e4a3a	cmofl3ut6000hmjdmwqd3dziu	INTEREST ON SAVING A/C	Indirect Incomes	\N	\N	0.00	\N
bff2715a-8c9a-45c4-bca7-d99c7b58c20b	cmofl3ut6000hmjdmwqd3dziu	INTEREST ON TDS	Indirect Expenses	\N	\N	0.00	\N
4ce6d9d5-4d69-419c-ad69-90c8c820805b	cmofl3ut6000hmjdmwqd3dziu	INTEREST ON UBI FDR	Indirect Incomes	\N	\N	0.00	\N
622db8d1-057e-4b98-9372-9d03040c0bef	cmofl3ut6000hmjdmwqd3dziu	Interest Paid	Indirect Expenses	\N	\N	0.00	\N
bb9c8f48-bc02-443e-9a86-dce00c619634	cmofl3ut6000hmjdmwqd3dziu	INTEREST PAID ON DEPOSIT	Indirect Expenses	\N	\N	0.00	\N
66ea495c-121c-4ec1-acec-b1ddf79ce0ca	cmofl3ut6000hmjdmwqd3dziu	Interior Chemistry &amp; Construction	Sundry Debtors	09EMOPK3670J1ZF	\N	0.00	Regular
5c7877b5-95ef-482f-b97c-c179069a428c	cmofl3ut6000hmjdmwqd3dziu	Intrest on Home Loan	Indirect Expenses	\N	\N	0.00	\N
522c9e89-7c43-4b1a-b3b5-c4ea180a0aa7	cmofl3ut6000hmjdmwqd3dziu	Intt.on Home Loan	Indirect Expenses	\N	\N	0.00	\N
7f4f6bbe-2d99-4002-bf31-6429489d192d	cmofl3ut6000hmjdmwqd3dziu	Ishan Infra  Pramotors Pvt Ltd	Sundry Debtors	09AACCI2589K1Z3	\N	0.00	Regular
f4050c0e-80ce-49c7-9bb2-4c74632d4989	cmofl3ut6000hmjdmwqd3dziu	ISPAT STEELS	Sundry Creditors	09AGYPJ1138J1ZW	\N	-6667.00	Regular
7348bf44-8bf2-441f-8085-401a7e08e0d7	cmofl3ut6000hmjdmwqd3dziu	ITC Writeoff	Indirect Expenses	\N	\N	0.00	\N
c33c9813-ff1a-4334-8bbb-3822b8e8651e	cmofl3ut6000hmjdmwqd3dziu	JAI BABA TRADERS	Sundry Debtors	\N	\N	0.00	Unregistered
253c9e72-e509-454e-89bf-fdf7dba75b84	cmofl3ut6000hmjdmwqd3dziu	Jai Balaji Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
f02c78d4-7c26-4938-8d1d-c9dfc6318d31	cmofl3ut6000hmjdmwqd3dziu	Jai Bhagwati  Transport  Service	Sundry Creditors for Transporter	\N	\N	0.00	Regular
8b0a2ccb-249c-4e37-8d0f-69df79f0ea11	cmofl3ut6000hmjdmwqd3dziu	JAI DURGA TRADERS	Sundry Debtors	\N	\N	0.00	Unregistered
cf409a52-33e2-4d64-ad12-0217df8a5938	cmofl3ut6000hmjdmwqd3dziu	JAI DURGA TRADERS-KANPUR	Sundry Debtors	09AMTPG4004B1ZD	\N	0.00	Regular
de8c8e65-5518-475f-9188-a364778358b0	cmofl3ut6000hmjdmwqd3dziu	Jai Hanuman Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
82ed08d0-2e5e-47fe-9638-0b131754d672	cmofl3ut6000hmjdmwqd3dziu	JAI HIND	Sundry Debtors	\N	\N	0.00	Regular
8e9859f7-e811-4319-8db7-3ab174143214	cmofl3ut6000hmjdmwqd3dziu	JAI JAGANNATH TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
cf11c4f0-b9e9-45e7-ae96-ef961e2a72d6	cmofl3ut6000hmjdmwqd3dziu	Jai Maa Annapurna Roadways	Sundry Creditors for Transporter	\N	\N	0.00	&#4; Unknown
61f4d439-e238-4af5-9764-49e7326d3b9d	cmofl3ut6000hmjdmwqd3dziu	JAI MAA ASSOCIATE	Sundry Debtors	09CMTPM9811J2Z6	\N	0.00	Regular
4cac0751-99e6-4b0f-a387-f3710c4ea7b7	cmofl3ut6000hmjdmwqd3dziu	Jai Maa Bhagwati Transport Service	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
355d01e7-0c8c-4566-b05d-4184be34555e	cmofl3ut6000hmjdmwqd3dziu	Jai Maa Bhawani Transport Service &amp; Commision Agent	Sundry Creditors for Transporter	09AQKPY3844N1ZT	\N	0.00	Regular
4b600e2f-8c8b-46a5-9a31-f19d3a720112	cmofl3ut6000hmjdmwqd3dziu	Jai Narain	Sundry Debtors	\N	\N	0.00	Unregistered
c5808188-0074-49d4-9dbc-5d0ebb13c69a	cmofl3ut6000hmjdmwqd3dziu	JAIN HIND TRADERS	Sundry Debtors	09MMTPS2327B1ZJ	\N	0.00	Regular
d2e91d81-0e19-428c-bc7a-78aba7e9ab6f	cmofl3ut6000hmjdmwqd3dziu	JAIN TRADERS	Sundry Creditors	09ACFPJ7332M1Z9	\N	0.00	Regular
24a4274f-ec0d-4da0-886c-bafdd783437f	cmofl3ut6000hmjdmwqd3dziu	JAI PRAKASH BATHAM	Sundry Debtors	\N	\N	0.00	Unregistered
d84de394-9054-4e98-8bd2-f2b157aefcda	cmofl3ut6000hmjdmwqd3dziu	JAI PRAKASH KANOJIYA	Sundry Debtors	\N	\N	0.00	Unregistered
0364865d-486d-4c10-bcae-09b0d25b46b2	cmofl3ut6000hmjdmwqd3dziu	Jai Shri Ram Goods Carrier	Sundry Creditors	\N	\N	0.00	Regular
e508fdfe-4172-4577-b4d3-53ba2086804a	cmofl3ut6000hmjdmwqd3dziu	JAI TRIPATI  STEELS PVT LTD	Sundry Creditors	24AABCJ5104E1Z7	\N	0.00	Regular
323038a1-4fc7-4db8-89f9-673a2375563c	cmofl3ut6000hmjdmwqd3dziu	JASPAL GOODS CARRIER	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
c56fa0ab-ce1d-414a-8e66-68c7976c48c5	cmofl3ut6000hmjdmwqd3dziu	Jaswant Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
fbbdf1d5-4f61-4a24-aebb-c51d3c3343cf	cmofl3ut6000hmjdmwqd3dziu	JAY BABA TRADERS	Sundry Debtors	09GCKPD1535H1ZM	\N	0.00	Regular
d19ae8e9-0a8c-46b5-b300-747742db2c34	cmofl3ut6000hmjdmwqd3dziu	Jay Bhole Shankar Transport Service	Sundry Creditors for Transporter	20ATUPP9454G1Z7	\N	0.00	Regular
26a7d3fd-1145-43a7-b758-9a5bcbec1fd5	cmofl3ut6000hmjdmwqd3dziu	Jay  Enterprises	Sundry Debtors	09ANYPK5683L2ZT	\N	0.00	Regular
62211496-0587-421a-9a52-83898efa54b6	cmofl3ut6000hmjdmwqd3dziu	Jay Shanker Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
666c3aa0-fd0c-4191-8dc8-9527f771091b	cmofl3ut6000hmjdmwqd3dziu	JAYSHESH SUBODH	Sundry Debtors	\N	\N	0.00	Unregistered
54a147d8-8733-41c4-9ddd-e3d69148fa8a	cmofl3ut6000hmjdmwqd3dziu	JAY SHREE TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
1d82a8b6-38ec-4601-95a0-5e47fb26b2a6	cmofl3ut6000hmjdmwqd3dziu	Jayvir Singh	Sundry Debtors	\N	\N	0.00	Unregistered
8979045c-c896-499b-8739-f0c1bd782e6a	cmofl3ut6000hmjdmwqd3dziu	J D Construction Pvt Ltd	Sundry Debtors	09AACCJ5257D1ZM	\N	0.00	Regular
07578378-6537-4474-af9f-d9578963e0e7	cmofl3ut6000hmjdmwqd3dziu	JEET ISPAT	Sundry Creditors	09ARWPG2709D1ZO	\N	0.00	Regular
ec706d6a-60a4-4f58-81ef-98fd1adf73bd	cmofl3ut6000hmjdmwqd3dziu	JEEVAN SAMRIDHI	Investments	\N	\N	0.00	\N
9b3954be-97cc-4094-8ac8-3065e1fb8624	cmofl3ut6000hmjdmwqd3dziu	Jeevesh	Sundry Debtors	\N	\N	0.00	\N
46ea7ca4-19c0-4751-a68a-e0260e5b2538	cmofl3ut6000hmjdmwqd3dziu	JITENDRA KATARIYA	Sundry Debtors	\N	\N	0.00	Unregistered
19cb5cfc-1b7a-435b-a2a1-fb361756c0bb	cmofl3ut6000hmjdmwqd3dziu	JITENDRA KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
9cf4a90b-a228-42f4-b31e-3187ecc023df	cmofl3ut6000hmjdmwqd3dziu	Jitendra Kumar Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
c34cd119-877d-446d-9909-f05926648399	cmofl3ut6000hmjdmwqd3dziu	Jitendra Kumar Gupta-Raniganj	Sundry Debtors	\N	\N	0.00	Unregistered
2c2edd69-6057-4964-9bae-350dc2568cc4	cmofl3ut6000hmjdmwqd3dziu	Jitendra Kumar Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
b9c4ad3b-ff91-4ec3-980b-79890633e98f	cmofl3ut6000hmjdmwqd3dziu	Jitendra Singh	Sundry Debtors	\N	\N	0.00	Unregistered
cb32a215-6e0c-4597-8ac4-f01a6fed9703	cmofl3ut6000hmjdmwqd3dziu	Jitendra Verma	Sundry Debtors	\N	\N	0.00	\N
fc30b83e-9109-462d-a14b-cc594df567b8	cmofl3ut6000hmjdmwqd3dziu	JJ Works &amp; Services	Sundry Debtors	21AAUHA2658A1ZO	\N	0.00	Regular
8c7c9a51-c84a-4225-b332-73ca11761f82	cmofl3ut6000hmjdmwqd3dziu	J K  LOGISTICS	Sundry Creditors for Transporter	\N	\N	0.00	\N
26202994-39d8-4780-b2c2-6cc8a30fe36e	cmofl3ut6000hmjdmwqd3dziu	JMD RESEARCH &amp; DEVELOPERS	Sundry Debtors	09AAIFJ1648K1Z0	\N	0.00	Regular
39d9de2a-3893-4e2e-8eed-42bb9126dd83	cmofl3ut6000hmjdmwqd3dziu	J.M.K ASSOCIATES	Sundry Debtors	09ANVPC7995C2ZC	\N	0.00	Regular
7076dce8-ce98-47f2-8979-6f6d7cdf5a39	cmofl3ut6000hmjdmwqd3dziu	J.P.CONSTRUCTION	Sundry Debtors	09CGCPS2378R2ZE	\N	0.00	Regular
de400d10-abfd-49d2-b399-80d5d0d22841	cmofl3ut6000hmjdmwqd3dziu	J.P. LOGISTICS	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
d16d3bbc-f1ad-4179-b4f7-c80c2abb5249	cmofl3ut6000hmjdmwqd3dziu	Jyoti Engineering Works	Sundry Debtors	09ACGPL2672M1Z5	\N	0.00	Regular
ba8f7183-42df-4782-8e40-1bff4b2d4144	cmofl3ut6000hmjdmwqd3dziu	JYOTI KANAUJIYA	Sundry Debtors	\N	\N	0.00	Unregistered
158397c5-8c4b-4270-a83b-37a7b5f6fa59	cmofl3ut6000hmjdmwqd3dziu	Kailash Singh	Sundry Debtors	\N	\N	0.00	Unregistered
e55e553c-6022-4eb7-a67f-eea85aa601be	cmofl3ut6000hmjdmwqd3dziu	Kalin Engineering Works	Sundry Debtors	09AFZPA4304B1ZP	\N	0.00	Regular
7d713c2a-1783-416f-b74c-cbe5506de38c	cmofl3ut6000hmjdmwqd3dziu	Kamala	Sundry Debtors	\N	\N	0.00	\N
2a443bdc-919f-4194-9a36-dd968a3c5fc6	cmofl3ut6000hmjdmwqd3dziu	Kamal Kumar Trivedi	Sundry Debtors	\N	\N	0.00	Unregistered
8d16959a-dd52-4673-b4f0-00a5ac3b03a3	cmofl3ut6000hmjdmwqd3dziu	Kamal Singh	Sundry Debtors	\N	\N	0.00	Unregistered
8d9bb296-828d-4d00-bac2-f015aa5a03eb	cmofl3ut6000hmjdmwqd3dziu	KAMLESH KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
62f7ef3e-d715-4ff6-b0fa-b6af0f67f551	cmofl3ut6000hmjdmwqd3dziu	KANAK CONSTRUCTION &amp; SUPPLIERS	Sundry Debtors	09AQGPT2432H1ZP	\N	0.00	Regular
12a6f7f7-3cce-4734-ad00-b15d8a1f6f7e	cmofl3ut6000hmjdmwqd3dziu	KANAK TILES AND SANITARY	Sundry Debtors	09AERPG6786L1ZI	\N	0.00	Regular
e67ddd4b-b843-41dd-9ff7-869641c72d4d	cmofl3ut6000hmjdmwqd3dziu	Kanchan Gautam	Sundry Debtors	\N	\N	0.00	Unregistered
7c348cab-7676-41a8-82c5-c4214fe320de	cmofl3ut6000hmjdmwqd3dziu	Kanha Enterprise - RANIA	Sundry Debtors	09AEFPG7821Q2ZX	\N	0.00	Regular
73d866d2-f592-4152-8f56-ea77f4e6bcc2	cmofl3ut6000hmjdmwqd3dziu	Kanha Enterprises	Sundry Debtors	09DQSPS4371F1Z5	\N	0.00	Regular
56acb0da-5591-4cb3-9c0b-a7769a14fdb4	cmofl3ut6000hmjdmwqd3dziu	Kanhaiya Lal Pal	Sundry Debtors	\N	\N	0.00	Unregistered
15fac3de-0654-4d4e-abc2-e055cdad4a0c	cmofl3ut6000hmjdmwqd3dziu	Kanpur Agra Roadways	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
1f7b70a2-c305-48e8-91dc-6d8c283b3640	cmofl3ut6000hmjdmwqd3dziu	Kanpur Bangal  Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	\N
765051b3-54f8-474f-8637-e916097af0d4	cmofl3ut6000hmjdmwqd3dziu	Kanpur Cooling Service Pvt Ltd	Sundry Creditors	09AAECK3473G1ZF	\N	0.00	Regular
fed78f44-3dd7-46d9-ab1f-e21cfc949e10	cmofl3ut6000hmjdmwqd3dziu	KANPUR ECOWARE PVT.LTD	Sundry Debtors	09AAJCK4906D1ZK	\N	0.00	Regular
c2fd923c-33a8-45f7-8152-6b2f04907bec	cmofl3ut6000hmjdmwqd3dziu	Kanpur Etah Roadways	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
daef1f22-5985-45aa-a063-29729b146105	cmofl3ut6000hmjdmwqd3dziu	Kanpur Gwaliro Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	Regular
1b0882ae-0cd0-48c3-810a-4bf3397c2d68	cmofl3ut6000hmjdmwqd3dziu	KANTI  NATH MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
99e11a14-5602-4cd5-88ac-43baff1bb8d0	cmofl3ut6000hmjdmwqd3dziu	KAPISH POWER  CONSTRUCTUION PVT LTD	Sundry Debtors	20AAFCK3903J2ZV	\N	0.00	Regular
6161db7c-cc7a-4cad-a63f-dc9098eac783	cmofl3ut6000hmjdmwqd3dziu	KARTIK ENTERPRISES	Sundry Debtors	08AEJPT7860E1Z1	\N	0.00	Regular
8c63492f-ff47-4f74-a4ee-98bbea0ccc79	cmofl3ut6000hmjdmwqd3dziu	Katiyar Enterprises	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
d5210e83-df9d-415b-a17d-632bba345cf6	cmofl3ut6000hmjdmwqd3dziu	KATIYAR WELDING WORKS	Sundry Debtors	\N	\N	0.00	\N
c7ee6e9e-d910-46a4-bac4-7590e0281df6	cmofl3ut6000hmjdmwqd3dziu	KAUSHAL KISHOR MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
a1c69e23-ff05-40ed-9269-5fa6bd307369	cmofl3ut6000hmjdmwqd3dziu	Kavita Singh	Sundry Debtors	\N	\N	0.00	Unregistered
386cb881-43d3-4598-8064-146dc57d60ce	cmofl3ut6000hmjdmwqd3dziu	K.B BROTHERS	Sundry Debtors	09AGEPM4102D1ZW	\N	0.00	Regular
bd3343d7-a825-4861-a953-2ddae13a17f6	cmofl3ut6000hmjdmwqd3dziu	KENCO LOGISTICS	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
6ead8fda-f40c-4549-938d-627af7abe3c8	cmofl3ut6000hmjdmwqd3dziu	Keshri developers &amp; construction	Sundry Debtors	\N	\N	0.00	\N
beb21027-d329-4818-b607-19ea24a1a630	cmofl3ut6000hmjdmwqd3dziu	Khagesh Kumar Gautam	Sundry Debtors	\N	\N	0.00	Unregistered
1f1eec97-6526-4bba-a143-d4fba6a44b50	cmofl3ut6000hmjdmwqd3dziu	Khan Engineering Works	Sundry Debtors	09AFZPA4304B1ZP	\N	0.00	Regular
49eb358c-32fb-404d-b31a-6dc5d8226dd9	cmofl3ut6000hmjdmwqd3dziu	KHAN TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Regular
fbf24132-0db7-4b0c-bc7a-9a68bc259442	cmofl3ut6000hmjdmwqd3dziu	Khatri &amp; Manhotra	Sundry Creditors	\N	\N	0.00	Unregistered
ba04c5a8-e20b-46eb-be94-4a1d7f49886e	cmofl3ut6000hmjdmwqd3dziu	Kiran Awasthi	Sundry Debtors	\N	\N	0.00	Unregistered
d0c35155-ba95-4e92-ab0e-a6e9d8036021	cmofl3ut6000hmjdmwqd3dziu	Kishan Babu Verma /abhishek Verama	Sundry Debtors	\N	\N	0.00	Unregistered
409f0c27-8388-4778-8147-bd168ec23986	cmofl3ut6000hmjdmwqd3dziu	KISHAN LAL PAWAN KUMAR JAIN	Sundry Creditors	09AABFK2145H1ZJ	\N	0.00	Regular
1b05f9ba-feeb-458d-ab2d-79c95b6f79bd	cmofl3ut6000hmjdmwqd3dziu	K.K. Bajaj &amp; Co.	Sundry Creditors	09AAAFK8985A1Z6	\N	0.00	Regular
30b96ca0-6b17-4b04-997a-4fd9f4dbb48f	cmofl3ut6000hmjdmwqd3dziu	K.N. BAKERS PVT LTD	Sundry Debtors	09AACCK4881G1ZB	\N	0.00	Regular
51211dfe-f72a-4b84-acf6-5adb9912ad27	cmofl3ut6000hmjdmwqd3dziu	KPJ DISTRIBUTORS	Sundry Creditors	09AAHFK0727H1ZD	\N	0.00	Regular
33bf8be3-cf1e-43bc-a1b2-d6e8e48df1a3	cmofl3ut6000hmjdmwqd3dziu	Krika Enterprises	Sundry Debtors	09AALFK7944C2Z1	\N	0.00	Regular
afe198df-db3b-4663-97e8-3383301fa4bb	cmofl3ut6000hmjdmwqd3dziu	Kripashanker Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
bbd4c69a-1a0e-4f53-b726-34cbbc068c6e	cmofl3ut6000hmjdmwqd3dziu	Krishan Sharma	Sundry Debtors	\N	\N	0.00	\N
2f7b1c02-d441-49db-b9a5-67cf5f599c25	cmofl3ut6000hmjdmwqd3dziu	Krishnaa Kumar Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
f4a11876-5aa7-44e5-90a1-c67566e067c7	cmofl3ut6000hmjdmwqd3dziu	KRISHNA CONCRETE	Sundry Debtors	09AASFK3482A1Z6	\N	0.00	Regular
fe64b442-0821-4844-ad2c-e548898acca0	cmofl3ut6000hmjdmwqd3dziu	Krishna Construction Co	Sundry Debtors	09AARFK2018H1Z7	\N	0.00	Regular
0d123388-588c-47ef-a7c3-1e043db9592f	cmofl3ut6000hmjdmwqd3dziu	Krishna Devi	Sundry Debtors	\N	\N	0.00	Unregistered
b3587b90-b261-493f-9b96-6b98271c818a	cmofl3ut6000hmjdmwqd3dziu	KRISHNA ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
c270f62c-a6fe-4f1a-9393-7ae6c01f2e7a	cmofl3ut6000hmjdmwqd3dziu	KRISHNA KUMAR GUPTA	Sundry Debtors	09AASPG8171G1Z9	\N	0.00	Regular
2f816be8-7263-43e9-9991-7446e967609c	cmofl3ut6000hmjdmwqd3dziu	Krishna Kumar Srivastava	Sundry Debtors	\N	\N	0.00	\N
31a9013e-d7ed-4e67-897b-84aca320bf86	cmofl3ut6000hmjdmwqd3dziu	Krishna Ram Verma	Sundry Debtors	\N	\N	0.00	Unregistered
3a756266-84cb-46c6-944e-167e6e791c48	cmofl3ut6000hmjdmwqd3dziu	KRISHNA TRADERS-FOROZABAD	Sundry Debtors	09AIRPA3852H1Z3	\N	0.00	Regular
00e9199e-b8da-46f3-ab74-2b0219f9d6b1	cmofl3ut6000hmjdmwqd3dziu	Krishna Trading Company	Sundry Debtors	09CLZPG9562P1ZP	\N	0.00	Regular
2321f9f8-1b56-4cd1-b3b6-5c7c6a0c1310	cmofl3ut6000hmjdmwqd3dziu	K S ENTERPRISES	Sundry Debtors	09HJQPS7893H1ZW	\N	0.00	Regular
549e3435-e756-4412-ae9b-cd39105afc6e	cmofl3ut6000hmjdmwqd3dziu	Kuldeep Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
a1726a0d-2c36-4bcb-b975-4f583595ea78	cmofl3ut6000hmjdmwqd3dziu	Kuldeep Saxena	Sundry Debtors	\N	\N	0.00	Unregistered
044efb68-8470-477f-b45d-edd057775a69	cmofl3ut6000hmjdmwqd3dziu	KUNAL RETAIL	Sundry Debtors	09AALFK2026M1Z2	\N	0.00	Regular
eaf8ab24-9244-47d2-ab62-5409ac385147	cmofl3ut6000hmjdmwqd3dziu	KUNAL SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
c8dab777-7ad4-4f88-90c6-faf81f8594bc	cmofl3ut6000hmjdmwqd3dziu	KUNJ ENTERPRISES	Sundry Debtors	09BSJPP7246K1Z0	\N	0.00	Regular
c8509753-7453-457e-890f-8c4cc5daeff1	cmofl3ut6000hmjdmwqd3dziu	Kunwar Brijesh Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
88797edb-5baf-4ad7-8e22-75949be3414b	cmofl3ut6000hmjdmwqd3dziu	KUNWAR PPAL	Sundry Debtors	\N	\N	0.00	Unregistered
caa018e8-32ea-467f-8ec4-1e2b9c35111c	cmofl3ut6000hmjdmwqd3dziu	KUNWAR SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
db78ce5c-b990-4212-9171-37b556d685c3	cmofl3ut6000hmjdmwqd3dziu	Kushumkali	Sundry Debtors	\N	\N	0.00	Unregistered
a93eb84b-cf85-4889-a13a-83e0b3c37239	cmofl3ut6000hmjdmwqd3dziu	K V INTER COLLEGE	Sundry Debtors	\N	\N	0.00	Regular
a305093f-b711-4f59-8b95-5352bc8d00a2	cmofl3ut6000hmjdmwqd3dziu	LAKHAN PANDYE	Sundry Debtors	\N	\N	0.00	Unregistered
da828fa4-3b0a-4442-9e3d-0b016ed4217b	cmofl3ut6000hmjdmwqd3dziu	LAKHAN SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
9096b50a-9882-49ef-a68e-d0160d3829b4	cmofl3ut6000hmjdmwqd3dziu	Lakshmi Shankar Singh	Sundry Debtors	\N	\N	0.00	Unregistered
fa2fdf79-d321-4226-b532-e4513b461a83	cmofl3ut6000hmjdmwqd3dziu	LAKSHMI SHANKER TRIVEDI	Sundry Debtors	\N	\N	0.00	Unregistered
a165b951-28eb-48c8-9acb-61eff9d81325	cmofl3ut6000hmjdmwqd3dziu	LAL BAHADUR	Sundry Debtors	\N	\N	0.00	Unregistered
ed0c8573-9ac3-47ae-a346-54ae28e357e9	cmofl3ut6000hmjdmwqd3dziu	Lalit	Sundry Debtors	\N	\N	0.00	Unregistered
81ac2268-ccfe-4128-9a4b-82888a17ec86	cmofl3ut6000hmjdmwqd3dziu	LALIT MEDICAL STORE	Sundry Debtors	09CYDPK9528E1Z6	\N	0.00	Regular
d9da37ed-48b0-4480-9d5a-19caf1888954	cmofl3ut6000hmjdmwqd3dziu	LALU KUSHWAHA	Sundry Debtors	\N	\N	0.00	Unregistered
63494f84-7b3d-49a3-bba7-8bbb52a28668	cmofl3ut6000hmjdmwqd3dziu	LAND SHATABDI NAGAR	Investments	\N	\N	-4116032.00	\N
fd5623ea-c061-481d-a1d0-9deaf5dea702	cmofl3ut6000hmjdmwqd3dziu	Laxmi Infra Associates	Sundry Debtors	09BLXPS9976G1ZP	\N	0.00	Regular
3d365714-f76f-470f-80dd-b6500467e2b7	cmofl3ut6000hmjdmwqd3dziu	Laxmi Road Ways	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
822bd223-976c-4686-aefb-bc67a2b0b836	cmofl3ut6000hmjdmwqd3dziu	Laxmi Shanker Singh	Sundry Debtors	\N	\N	0.00	Unregistered
4c468e40-85e3-457e-8892-d99fb17e0d28	cmofl3ut6000hmjdmwqd3dziu	Laxmi Shanker Trivedi	Sundry Debtors	\N	\N	0.00	Unregistered
84eb6aad-31f7-4f3d-b1e1-dfc644a18b4f	cmofl3ut6000hmjdmwqd3dziu	Legal Expenses	Indirect Expenses	\N	\N	0.00	\N
662805d6-e9de-4e22-9a75-072d540df97a	cmofl3ut6000hmjdmwqd3dziu	Legal Expenses Payable	Current Liabilities	\N	\N	0.00	Unregistered
b94d954c-be47-42a3-97bf-8fc657b53544	cmofl3ut6000hmjdmwqd3dziu	Legal Fee	Indirect Expenses	\N	\N	0.00	\N
b2d6981b-7654-4dc7-8f52-15b7c4f524dd	cmofl3ut6000hmjdmwqd3dziu	L.I.C.	Capital Account	\N	\N	0.00	Unregistered
cac54182-a6ab-4761-9a3c-572ca8166e37	cmofl3ut6000hmjdmwqd3dziu	Lights Gallery	Sundry Creditors	09AAAFL4029Q1ZX	\N	0.00	Regular
09d3edf8-2aaa-4363-b82b-4606025c3857	cmofl3ut6000hmjdmwqd3dziu	Ling Raj Steel &amp; Power Pvt Ltd	Sundry Creditors	22AABCL1227A1ZH	\N	0.00	Regular
ab9401f3-ba40-4577-b0d2-c8177b74ff7a	cmofl3ut6000hmjdmwqd3dziu	Loading 18%	Indirect Incomes	\N	\N	0.00	\N
e9aaa965-276c-42a3-9513-5cac144b9fec	cmofl3ut6000hmjdmwqd3dziu	LOADING A\\C	Indirect Expenses	\N	\N	0.00	\N
0f333c65-23b8-47a4-8e1a-d2d4cba9ccb1	cmofl3ut6000hmjdmwqd3dziu	Loading Charges on Purchase	Indirect Expenses	\N	\N	0.00	\N
c67f4398-8446-4c22-a065-9bb30a5fa0a3	cmofl3ut6000hmjdmwqd3dziu	Loading &amp; Unloading	Indirect Expenses	\N	\N	0.00	\N
6bfcfa7d-5ba4-48aa-b282-07f464ab09fb	cmofl3ut6000hmjdmwqd3dziu	Loan Recovery	Capital Account	\N	\N	0.00	Unregistered
67762d58-80e7-4f73-bed5-5c72dd8a3684	cmofl3ut6000hmjdmwqd3dziu	Maa Barahi Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
05dee3e2-040e-406d-883a-d80058e2f803	cmofl3ut6000hmjdmwqd3dziu	MAA BHAGWATI SALES	Sundry Debtors	09ANNPD6522C1Z7	\N	0.00	Regular
90aae5d6-ed92-4502-a180-19f8e818fa92	cmofl3ut6000hmjdmwqd3dziu	Maa Bhawani Power &amp; Ispat Pvt Ltd	Sundry Creditors	22AAHCM1007H1Z2	\N	0.00	Regular
14ec646c-a5f3-44df-8830-1a9fad23afbb	cmofl3ut6000hmjdmwqd3dziu	Maa Durga Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
f504168d-1d4e-43e9-bd0f-193b812c0ecd	cmofl3ut6000hmjdmwqd3dziu	Maa Enterprises	Sundry Debtors	09LVCPS3721A1ZL	\N	0.00	Regular
3f4fc9b1-4eb6-4b4e-84a8-eaa4cede9b22	cmofl3ut6000hmjdmwqd3dziu	Maa Gayatri Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
059addb6-ea4c-4805-a402-01a0e864c370	cmofl3ut6000hmjdmwqd3dziu	MAA KELA ENTERPRISES	Sundry Debtors	09AALFM4486H1ZR	\N	0.00	Regular
9adfbb5b-8187-4dda-82e9-ef186cc3227b	cmofl3ut6000hmjdmwqd3dziu	MAA LAXMI ROADWAYS	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
ee9e1aff-ecdd-4fda-930d-df9fa27fe652	cmofl3ut6000hmjdmwqd3dziu	MAA PITAMBARA CEMENT ARTICLE	Sundry Debtors	\N	\N	0.00	\N
a8207cba-8c02-4387-8f64-a488fe097817	cmofl3ut6000hmjdmwqd3dziu	Maa Pitambra	Sundry Debtors	\N	\N	0.00	\N
8e731405-f187-4dbe-9669-2a9da3d3f1c2	cmofl3ut6000hmjdmwqd3dziu	Maa Shivalik Traders and Service	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
2e8da38e-6d39-48ae-af4f-7df32de65ecb	cmofl3ut6000hmjdmwqd3dziu	MADHAV MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
47b68193-6ec4-46f3-a59a-9e410dd0eeb3	cmofl3ut6000hmjdmwqd3dziu	MADHURI BHADAURIYA	Sundry Debtors	\N	\N	0.00	Unregistered
a1d5a06f-5a9f-4f25-a061-5933f0ca9ed1	cmofl3ut6000hmjdmwqd3dziu	MAHADEV TRANSPORT COMMISSION AGENCIES	Sundry Debtors	\N	\N	0.00	Unregistered
5c015c29-a7c7-4666-a3c2-4b15d13e4553	cmofl3ut6000hmjdmwqd3dziu	Mahakaleshwar Construction &amp; Traders	Sundry Debtors	09BHUPC9410J1ZX	\N	0.00	Regular
e304bf0f-dca1-4167-898c-e1befa6a8128	cmofl3ut6000hmjdmwqd3dziu	MAHAKALESHWAR ENTERPRISES	Sundry Debtors	09BNJPD6208E1Z7	\N	0.00	Regular
53c20695-f430-4e2d-bbed-a12481c5da8f	cmofl3ut6000hmjdmwqd3dziu	MAHAK Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
3cccf408-e06c-4450-b8ab-00d6fa308674	cmofl3ut6000hmjdmwqd3dziu	Mahendra Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
da1e053b-cacd-435e-87c7-6b6dd4f3c962	cmofl3ut6000hmjdmwqd3dziu	Mahendra Kumar Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
ad138a44-e764-4a25-91ba-95b3067d4fe3	cmofl3ut6000hmjdmwqd3dziu	Mahendra Kumar Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
f608c08c-b0a4-4a02-a3d0-a42956a982dc	cmofl3ut6000hmjdmwqd3dziu	Mahendra Pratap Singh	Sundry Debtors	\N	\N	0.00	Unregistered
86964ff4-7bcd-416f-8183-00b5ebb5b69e	cmofl3ut6000hmjdmwqd3dziu	Mahendra Singh	Sundry Debtors	\N	\N	0.00	Unregistered
9066cd77-eec2-4137-80ad-836f181a6106	cmofl3ut6000hmjdmwqd3dziu	Mahendra Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
ce5900dc-bf2a-4a5e-b9c9-d3d98a990a5d	cmofl3ut6000hmjdmwqd3dziu	Mahesh Chandra	Sundry Debtors	\N	\N	0.00	Unregistered
b52dd9dc-cba6-46c7-a005-e78b60d7f464	cmofl3ut6000hmjdmwqd3dziu	MAHESH KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
a67f0d6a-28ad-4088-8ded-9123db0b424c	cmofl3ut6000hmjdmwqd3dziu	Mahesh Pal Singh	Sundry Debtors	\N	\N	0.00	Unregistered
98e66d71-72f9-4ee0-8163-3dc152e3f9fe	cmofl3ut6000hmjdmwqd3dziu	Mahesh Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
f13c2a25-323d-4db6-b4b1-187480bb2cac	cmofl3ut6000hmjdmwqd3dziu	MAHIP KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
4e97358c-fb80-4ec6-95ea-b43f7de01ce5	cmofl3ut6000hmjdmwqd3dziu	Mahoba Allahabad Roadways	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
24b90bdd-85bb-46a7-9c52-6ad1efa7c16d	cmofl3ut6000hmjdmwqd3dziu	Makerkotla Moga Roadways	Sundry Creditors for Transporter	\N	\N	0.00	\N
35ffcb60-6397-45c3-a791-8731dcfe7541	cmofl3ut6000hmjdmwqd3dziu	Makkhan Transports Service	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
5240807f-775f-4d72-9100-a9d054f811ac	cmofl3ut6000hmjdmwqd3dziu	Malerkotla Moga Roadways	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
0b961df5-07c8-40eb-b9df-c1e940bd7f6f	cmofl3ut6000hmjdmwqd3dziu	Mangalam Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
7a1ccc4d-8098-430e-b427-f5f47a50fb15	cmofl3ut6000hmjdmwqd3dziu	Mangesh Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
79f5817d-06e6-4880-8a32-c6a264481fa9	cmofl3ut6000hmjdmwqd3dziu	Mani Enterprises	Sundry Debtors	09BYKPM9808H1ZT	\N	0.00	Regular
80dd8158-3403-4b70-87ed-2803f77d6edb	cmofl3ut6000hmjdmwqd3dziu	Mani Lal	Sundry Debtors	\N	\N	0.00	Unregistered
990efc74-ae56-4b7d-8248-501b5387ebe2	cmofl3ut6000hmjdmwqd3dziu	MANI MOHAN TIWARI	Sundry Debtors	\N	\N	0.00	Unregistered
074b9cc3-8f3c-4e34-b43a-b84c95921d1a	cmofl3ut6000hmjdmwqd3dziu	Manish	Sundry Debtors	\N	\N	0.00	Unregistered
daa11444-dbba-4038-b6bb-4a99ed3622fb	cmofl3ut6000hmjdmwqd3dziu	Manisha	Sundry Debtors	\N	\N	0.00	Unregistered
fc9f4d06-97be-4953-8a84-165e050b6270	cmofl3ut6000hmjdmwqd3dziu	MANISH KAMAL	Sundry Debtors	\N	\N	0.00	Unregistered
bf4416ae-8f09-45a2-8595-144177ac070e	cmofl3ut6000hmjdmwqd3dziu	MANISH KUMAR	Sundry Debtors	09IWWPK5267D1ZR	\N	0.00	Regular
4a9b267c-a3c0-47d5-a403-71703234501b	cmofl3ut6000hmjdmwqd3dziu	MANISH KUMAR SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
6203ffc8-9d1e-47e5-b355-b917c9c3774d	cmofl3ut6000hmjdmwqd3dziu	MANISH KUMAR SINGH-	Sundry Debtors	\N	\N	0.00	Unregistered
38e9d818-c014-416a-b950-1e5629e63ffe	cmofl3ut6000hmjdmwqd3dziu	MANISH SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
24d3919f-75ce-4b0c-8810-9cfb52889ded	cmofl3ut6000hmjdmwqd3dziu	Manjesh	Sundry Debtors	\N	\N	0.00	Unregistered
fc6b32f8-d557-44cc-9108-cdcf9262cfe5	cmofl3ut6000hmjdmwqd3dziu	MANJU VAISH	Sundry Debtors	\N	\N	0.00	Unregistered
16200c51-54a2-44ee-9591-710ab5689473	cmofl3ut6000hmjdmwqd3dziu	MANJU VERMA	Sundry Debtors	\N	\N	0.00	Unregistered
c9d34506-893d-47fb-a5d5-b35a73045361	cmofl3ut6000hmjdmwqd3dziu	MANOHAR LAL PAL	Sundry Debtors	\N	\N	0.00	Unregistered
a472b3e7-5470-40df-a454-aa79bfa61a0e	cmofl3ut6000hmjdmwqd3dziu	MANOJ AGNIHOTRI	Sundry Debtors	\N	\N	0.00	Unregistered
a3a58ad7-c3fe-469f-b01d-4d956799bfdc	cmofl3ut6000hmjdmwqd3dziu	Manoj  Gautam	Sundry Debtors	\N	\N	0.00	Unregistered
eec4eba2-5c8c-456e-8d10-54778b0d41bb	cmofl3ut6000hmjdmwqd3dziu	Manoj Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
a0c456a1-4ac4-47bf-a2c2-5c6bfa3042b5	cmofl3ut6000hmjdmwqd3dziu	Manoj Kumar Prajapati	Sundry Debtors	\N	\N	0.00	Unregistered
1c36c965-f3b9-4431-8269-487e5e30e7ea	cmofl3ut6000hmjdmwqd3dziu	Manoj Pandey	Sundry Debtors	\N	\N	0.00	Unregistered
0926e13e-8d95-461c-94d7-d0e663b28c72	cmofl3ut6000hmjdmwqd3dziu	Manoj Pathak	Sundry Debtors	\N	\N	0.00	Unregistered
371e30c7-9624-4555-a7a6-659aead54925	cmofl3ut6000hmjdmwqd3dziu	Manoj Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
1f3b8d7d-68dd-44fb-9747-d9ddc866465c	cmofl3ut6000hmjdmwqd3dziu	MANOJ SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
76a1b0ac-2bab-4546-ab63-7421fc539340	cmofl3ut6000hmjdmwqd3dziu	Manoj Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
916c53a0-7fd5-4679-b60d-c51c20feccc1	cmofl3ut6000hmjdmwqd3dziu	Manorama Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
3a162c7c-bc07-4940-b1c9-bb8b8701fd15	cmofl3ut6000hmjdmwqd3dziu	Mansarovar Transport	Sundry Creditors for Transporter	\N	\N	0.00	Regular
0c234934-e4ec-4a8f-9de1-e0b3649988b4	cmofl3ut6000hmjdmwqd3dziu	Mansing Singh Contractor	Sundry Debtors	09ASGPS2170P1Z2	\N	0.00	Regular
821681f1-60d1-4788-898b-c8298e67bbe2	cmofl3ut6000hmjdmwqd3dziu	MANU SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
1d04ea57-ef68-4bf5-8a01-04e289d49066	cmofl3ut6000hmjdmwqd3dziu	Maruti Nandan Enterprises	Sundry Debtors	09GEFPS7015C1ZF	\N	0.00	Regular
54184248-5226-4da2-a3e3-cbd1ced0e416	cmofl3ut6000hmjdmwqd3dziu	Mathura Land	Fixed Assets	\N	\N	-300000.00	\N
59f83c89-c296-403b-ad92-6508871c2b0c	cmofl3ut6000hmjdmwqd3dziu	M A Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
b6b4fe9f-196b-4d71-afaf-51b344710920	cmofl3ut6000hmjdmwqd3dziu	Maya Construction	Sundry Debtors	09AHNPV4796N1ZZ	\N	0.00	Regular
c67b25b9-f9b7-4395-bc2f-dbcc191be4ae	cmofl3ut6000hmjdmwqd3dziu	Maya Devi	Sundry Debtors	\N	\N	0.00	Unregistered
c3e49a21-48c0-47fd-a58a-066c7eadec6e	cmofl3ut6000hmjdmwqd3dziu	Mayank Singh Chauhan	Sundry Debtors	\N	\N	0.00	Unregistered
76a2f8a2-b9ae-4c2f-b38a-06d49aebe6c7	cmofl3ut6000hmjdmwqd3dziu	M D Freight Carrier	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
d87ced0b-e80c-42fc-8416-740d64515456	cmofl3ut6000hmjdmwqd3dziu	Meena Devi	Sundry Debtors	\N	\N	0.00	Unregistered
a345b4a2-81e4-4d53-a50b-ee12991c26f1	cmofl3ut6000hmjdmwqd3dziu	MEERA	Sundry Debtors	\N	\N	0.00	Unregistered
efe01506-1f2e-4f47-ac5b-bc15cc1d2393	cmofl3ut6000hmjdmwqd3dziu	METAL JUCTION	Sundry Creditors	\N	\N	0.00	Regular
fc03e89e-b6ec-4f15-9e50-3d2c5a1cc383	cmofl3ut6000hmjdmwqd3dziu	MILIND GAUTAM	Sundry Debtors	\N	\N	0.00	Unregistered
91f6f2f7-900d-46d7-a9cd-9f9b5be331c7	cmofl3ut6000hmjdmwqd3dziu	MINI SECURITY SERVICES	Sundry Debtors	09AAJFM6883A1Z2	\N	0.00	Regular
0f1bb385-514e-4575-8cda-dbdb8cc1068a	cmofl3ut6000hmjdmwqd3dziu	MINTU KUMAR DOHARE	Sundry Debtors	\N	\N	0.00	Unregistered
37911c1f-45ca-46aa-b9e8-816e449573ad	cmofl3ut6000hmjdmwqd3dziu	Mishra Iron Traders	Sundry Debtors	09AKTPM4428P1Z6	\N	0.00	Regular
b9d3e5e2-b7a7-48f9-8969-ea611327f355	cmofl3ut6000hmjdmwqd3dziu	MITHILESH YADAV	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
201a3da4-cfa4-4101-8360-1521a9a19b05	cmofl3ut6000hmjdmwqd3dziu	M K TRADERS	Sundry Debtors	09BCAPB2465F1Z0	\N	0.00	Regular
bb53f8da-923a-4042-a5d2-e70ddea18f4e	cmofl3ut6000hmjdmwqd3dziu	M M ENTERPRISES	Sundry Debtors	09FGSPM5056B1Z2	\N	0.00	Regular
20bad5d9-44fb-4a46-b925-05743e37e3db	cmofl3ut6000hmjdmwqd3dziu	M.M. PRINTS	Sundry Debtors	\N	\N	0.00	\N
38bd9bf0-5bc1-460e-b039-4ff1a38aa7f7	cmofl3ut6000hmjdmwqd3dziu	Moahn Kumar Pal	Sundry Debtors	\N	\N	0.00	Unregistered
1d45c812-704d-4f70-a759-1b950a3ae273	cmofl3ut6000hmjdmwqd3dziu	MOB HAND SET	Fixed Assets	\N	\N	-18613.30	\N
7ccba8d7-c173-4f9b-882c-7b94ccbf3648	cmofl3ut6000hmjdmwqd3dziu	Modi Brothers	Sundry Debtors	09AAEFM9737G1ZW	\N	0.00	Regular
d8fefedc-24f2-4749-9370-da8653136ae3	cmofl3ut6000hmjdmwqd3dziu	Mohammad Wahab	Sundry Debtors	\N	\N	0.00	Unregistered
cc80109d-3be7-49c1-b7bc-8fb3022e2970	cmofl3ut6000hmjdmwqd3dziu	Mohan Ram	Sundry Debtors	\N	\N	0.00	Unregistered
2c143034-c8ea-4157-bac1-61b00400fdae	cmofl3ut6000hmjdmwqd3dziu	Moh.Arif	Sundry Debtors	\N	\N	0.00	Unregistered
ea3841cf-7a4d-4695-bf06-821ecca8ec38	cmofl3ut6000hmjdmwqd3dziu	Mohit Iron Traders	Sundry Debtors	09AAXPG9701D1ZG	\N	0.00	Regular
3fa32853-feff-4474-a295-0d784080a37f	cmofl3ut6000hmjdmwqd3dziu	MOHIT KUMAR Maurya	Sundry Debtors	\N	\N	0.00	Unregistered
94962767-b90f-4aee-8a1b-94070a92fa25	cmofl3ut6000hmjdmwqd3dziu	Mohit Saini	Sundry Debtors	\N	\N	0.00	Unregistered
af2118e7-fa7a-4273-a9ab-9891be3fdda2	cmofl3ut6000hmjdmwqd3dziu	MONI DUBEY	Sundry Debtors	09CDDPD9602H1ZN	\N	0.00	Regular
0e1d7ea1-1ca1-4711-be00-6de564b4a4a1	cmofl3ut6000hmjdmwqd3dziu	Monu Srivastava	Sundry Debtors	\N	\N	0.00	Unregistered
910cbd51-6796-4947-8080-5aa2ba820c63	cmofl3ut6000hmjdmwqd3dziu	Monu Verma	Sundry Debtors	\N	\N	0.00	Unregistered
c990751c-fb73-4c0c-b99b-ae9557583ac7	cmofl3ut6000hmjdmwqd3dziu	M.P. ENTERPRISES	Sundry Debtors	09AOPPP0321L1ZN	\N	0.00	Regular
a4b747aa-e35d-41d9-bf31-992e53a374bb	cmofl3ut6000hmjdmwqd3dziu	Mr. Ashok	Sundry Debtors	\N	\N	0.00	Unregistered
81135eb5-6234-42ad-8cc1-8da619d5d308	cmofl3ut6000hmjdmwqd3dziu	Mr.Prem	Sundry Debtors	\N	\N	0.00	Unregistered
a9a0c5d5-88e2-472c-922a-dcdf8267ef31	cmofl3ut6000hmjdmwqd3dziu	M/S ADHAR CONSULTANCY AND INFRASTRUCTURE	Sundry Debtors	09AAWFA1111E2ZP	\N	0.00	Regular
ca68f896-e2f4-4cdf-86a8-a480e9df7eed	cmofl3ut6000hmjdmwqd3dziu	M/S AMAR TRADERS	Sundry Debtors	09AKLPY9640D1ZJ	\N	0.00	Regular
398b8b42-b11e-4c76-831c-a5f60c8970b7	cmofl3ut6000hmjdmwqd3dziu	M/S ANAND SALES CORPORATION	Sundry Debtors	09AGHPG9985F1ZU	\N	0.00	Regular
981ebd7c-b76e-4120-b899-ec8a5440312a	cmofl3ut6000hmjdmwqd3dziu	M/S ANKIT ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
7dfc2719-c22c-4de6-a663-ee5e12821baf	cmofl3ut6000hmjdmwqd3dziu	M/S A.S.ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
20a30d20-5a43-4709-8237-b7ec2d3df3a6	cmofl3ut6000hmjdmwqd3dziu	M/S ASHISH STEELS	Sundry Debtors	\N	\N	0.00	\N
6572e296-b0d7-42aa-8f09-ebf67c2f19a5	cmofl3ut6000hmjdmwqd3dziu	M/S AWASTHI WELDING MATERIAL AND ALUMINIUM DECORATOR	Sundry Debtors	09BBDPA8953M1Z8	\N	0.00	Regular
880b5080-b23d-477b-8fa3-298fef915e60	cmofl3ut6000hmjdmwqd3dziu	M/S BECHEY GENERATOR SERVICE	Sundry Debtors	\N	\N	0.00	\N
714e7728-bfd6-4252-81a3-aeff8d09a8a3	cmofl3ut6000hmjdmwqd3dziu	M S ENTERPRISES	Sundry Debtors	09IIIPS1598K2Z7	\N	0.00	Regular
cbdd94da-5be2-4c7f-a9e8-f07638cda94f	cmofl3ut6000hmjdmwqd3dziu	M/S GLOW PLAST	Sundry Debtors	09ADXPK7037K1ZQ	\N	0.00	Regular
6e316a8e-435b-40b9-91f4-d9d0c6e1be35	cmofl3ut6000hmjdmwqd3dziu	M/S GOKUL PHARMACEUTICALS	Sundry Debtors	\N	\N	0.00	\N
a32d522a-4bd2-48b4-a343-54b655a8e8e5	cmofl3ut6000hmjdmwqd3dziu	M/S GUARD ENGINEERS	Sundry Debtors	09ARKPS5211Q1Z2	\N	0.00	Regular
7ba8dea2-809e-4132-92dd-b55d05d5ce3e	cmofl3ut6000hmjdmwqd3dziu	M/S GUPTA ASSOCIATE	Sundry Debtors	09AJDPG9271H1Z0	\N	171229.00	Regular
52bda9a3-b000-427c-a525-32cff892d4c9	cmofl3ut6000hmjdmwqd3dziu	M/S ISHITA CONSTRUCTION	Sundry Debtors	\N	\N	0.00	\N
58b282c8-aa01-4366-86a7-70106d148899	cmofl3ut6000hmjdmwqd3dziu	M/S JAI MAA STEEL TRADERS	Sundry Debtors	09AKVPT1388D1ZH	\N	0.00	Regular
3a538403-1386-4700-b8e7-9cc1fcbe70bd	cmofl3ut6000hmjdmwqd3dziu	M/S J.K. LOGISTICS	Sundry Creditors for Transporter	\N	\N	0.00	\N
08634088-8fa2-458c-b854-5a7f0a0c95f9	cmofl3ut6000hmjdmwqd3dziu	M/S KUMAR CREATIONS PVT LTD	Sundry Debtors	\N	\N	0.00	\N
07000771-1300-47b8-8769-4b3745a64250	cmofl3ut6000hmjdmwqd3dziu	M/S MAHESH CONSTRUCTION CO	Sundry Debtors	09AELPC4023Q1Z8	\N	0.00	Regular
02bc1b32-03ba-420f-9e2a-ea5e6ccb1d3e	cmofl3ut6000hmjdmwqd3dziu	M/S MARKANDEY ENTERPRISES	Sundry Debtors	09BWPPJ7674B1Z3	\N	0.00	Regular
c378d246-eadd-4e25-94b7-34796d000ec0	cmofl3ut6000hmjdmwqd3dziu	MSME 2% INTEREST	Indirect Incomes	\N	\N	0.00	\N
32b6fae2-58ee-479a-ba9d-b0694edf0f3d	cmofl3ut6000hmjdmwqd3dziu	M/S METRO MARBLES	Sundry Debtors	09AYLPS4156N1ZJ	\N	0.00	Regular
1492d656-c1dd-4b09-ad59-1e1b657a3611	cmofl3ut6000hmjdmwqd3dziu	M/S NEELAM ENTERPRISES	Sundry Debtors	09AMHPM5526C1Z4	\N	0.00	Regular
9f7c8463-e97a-419f-a718-e2f9dc3c653e	cmofl3ut6000hmjdmwqd3dziu	M/S PATALESWAR ENTERPRISES	Sundry Debtors	09ADZPY6394B1ZJ	\N	0.00	Regular
d7b1496b-ed67-42f4-a39e-7ab6721c6348	cmofl3ut6000hmjdmwqd3dziu	M.S. POWER BRAKE SERVICE CENTRE	Sundry Debtors	09BJHPM3227J1Z0	\N	0.00	Regular
76a135be-300b-4905-afda-b77a908f6f09	cmofl3ut6000hmjdmwqd3dziu	M/S RADHEY RAMAN STEEL SUPPLIERS	Sundry Debtors	09AHWPJ2930P1ZI	\N	0.00	Regular
bdc8dd94-1091-40aa-9f5c-65e9e6764eeb	cmofl3ut6000hmjdmwqd3dziu	M/S RATAN HOUSING DEVELOPMENT LTD	Sundry Debtors	09AACCR6099R1ZB	\N	0.00	Regular
cf099484-3052-4d35-8dc7-19be1ba481dd	cmofl3ut6000hmjdmwqd3dziu	M/S R S ENTERPRISES	Sundry Debtors	09AXLPS9904K1ZL	\N	0.00	Regular
cad928b8-c8d4-4e34-aa9a-fca65eadef94	cmofl3ut6000hmjdmwqd3dziu	M/S SAANVI SALES	Sundry Debtors	09EFRPS8760H1ZF	\N	0.00	Regular
77a8fbc2-f7dc-4496-beed-9a30496e1578	cmofl3ut6000hmjdmwqd3dziu	M/S SAI CONSTRUCTION COMPANEY	Sundry Debtors	\N	\N	0.00	\N
7e627cd9-6117-406c-9cd7-a81a23f7b4e6	cmofl3ut6000hmjdmwqd3dziu	M/S SAI RAM ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
11d0131a-a054-48b4-814c-3fc0689e6220	cmofl3ut6000hmjdmwqd3dziu	M/S SALUJA STEEL &amp; POWER (P) LTD. (UNIT-II)	Sundry Creditors	\N	\N	0.00	\N
bcce8dca-060c-4a26-bd8d-1e5ea84ef9ec	cmofl3ut6000hmjdmwqd3dziu	M/S S.D.ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
d94e5e43-8e75-483c-8acc-d47c29e44c4c	cmofl3ut6000hmjdmwqd3dziu	M/S SETESH STEELS	Sundry Debtors	\N	\N	0.00	\N
a29d2af7-4b53-4893-b454-2e066ef4a5df	cmofl3ut6000hmjdmwqd3dziu	M/S SHANTI STONE MILL	Sundry Debtors	09ABGFS1595K1ZL	\N	0.00	Regular
96c52d2d-95bc-4bc8-aad0-a7ca3ca28c29	cmofl3ut6000hmjdmwqd3dziu	M/S SHIVAM ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
f2e428b3-7db2-4616-809c-78dee7c5ff96	cmofl3ut6000hmjdmwqd3dziu	M/S SHREE SAI CONTRACTOR	Sundry Debtors	\N	\N	0.00	\N
8f7ac62e-243c-4873-a73d-4607bdc5adb9	cmofl3ut6000hmjdmwqd3dziu	M/S SHREE SHIVRAM HP	Sundry Debtors	09BEPPS1929J1ZS	\N	0.00	Regular
4bf30e11-d530-4087-98db-eb0daed018b2	cmofl3ut6000hmjdmwqd3dziu	M/S SHREYA ENTERPRISES	Sundry Debtors	09AIMPT4383P1Z4	\N	0.00	Regular
264c6a04-d926-4d36-af1a-74ebe434fb64	cmofl3ut6000hmjdmwqd3dziu	M/S SHYAM INDUS POWER SOLUTIONS PVT. LTD.	Sundry Debtors	09AAICS3625E1ZD	\N	0.00	Regular
0e5abbe3-d8dc-4c14-99a4-d8a67f09a5f1	cmofl3ut6000hmjdmwqd3dziu	M/S SINGHAL STEELS	Sundry Debtors	09AANCS1729A1ZF	\N	0.00	Regular
9d99ab2b-a272-4f04-ae59-84d06598396c	cmofl3ut6000hmjdmwqd3dziu	M/S SINGH CONSTRUCTIONS &amp; SUPPLIERS	Sundry Debtors	\N	\N	0.00	\N
5c052095-e8f1-48d3-a407-159b75188c90	cmofl3ut6000hmjdmwqd3dziu	M/S SINGH TRADERS	Sundry Debtors	09FCLPS8523Q1ZE	\N	0.00	Regular
84260929-2b34-4faa-a0da-99779a0ce5eb	cmofl3ut6000hmjdmwqd3dziu	M/S SRI BABA VAIDYANATH STEELS	Sundry Creditors	\N	\N	0.00	\N
5ea1453e-50e9-472a-9a65-149acd2fa55c	cmofl3ut6000hmjdmwqd3dziu	M/S TIRUPATI ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
7aa1c60b-926f-4302-a050-a58bbb9ef12d	cmofl3ut6000hmjdmwqd3dziu	M/S VAISHNAVI STEELS	Sundry Creditors	09AGKPJ2292H1Z6	\N	0.00	Regular
9d554abe-6f55-4b69-a2a2-5d6bf3cd49c0	cmofl3ut6000hmjdmwqd3dziu	M/S V S WAREHOUSING SERVICES	Sundry Debtors	\N	\N	0.00	\N
306dbba2-c333-416b-a978-6ffc4b7ea080	cmofl3ut6000hmjdmwqd3dziu	Mukesh Pathak	Sundry Debtors	\N	\N	0.00	Unregistered
694a9538-fa1a-403f-9a59-2ab7bc6db7a7	cmofl3ut6000hmjdmwqd3dziu	Mukesh Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
de137647-8e72-47f9-9f92-167bd9363c79	cmofl3ut6000hmjdmwqd3dziu	Mukesh Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
861b95e1-0518-4443-b947-557d01f4e24c	cmofl3ut6000hmjdmwqd3dziu	MUNISH TIWARI	Sundry Debtors	\N	\N	0.00	Unregistered
289c3df2-7849-4ea8-8eff-c6ddd00021d1	cmofl3ut6000hmjdmwqd3dziu	Munni Lal	Sundry Debtors	\N	\N	0.00	Unregistered
ce79c88d-20a7-416d-8b77-76332b25361a	cmofl3ut6000hmjdmwqd3dziu	M.V. Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	Regular
d7e5b97a-b883-4ab3-807e-6d90d2153bc2	cmofl3ut6000hmjdmwqd3dziu	MY CARE SERVICES	Sundry Creditors	09AOWPV3459G1Z0	\N	0.00	Regular
3557803a-1a1e-4804-b9a0-beb01131233a	cmofl3ut6000hmjdmwqd3dziu	Nagendra Singh	Sundry Debtors	\N	\N	0.00	Unregistered
c0aeaf14-eeb9-48b1-a53d-d3a4e7606c6e	cmofl3ut6000hmjdmwqd3dziu	NANDU SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
ea2ea271-b95b-4541-861f-d1cb9a8e59cb	cmofl3ut6000hmjdmwqd3dziu	Narayan	Sundry Debtors	\N	\N	0.00	Unregistered
53cb7794-1cfe-4e2b-b731-933cfa20f238	cmofl3ut6000hmjdmwqd3dziu	NARAYAN HARI	Sundry Debtors	\N	\N	0.00	Unregistered
6d38b880-de45-45b2-a247-34b825c776b2	cmofl3ut6000hmjdmwqd3dziu	NARENDRA	Sundry Debtors	\N	\N	0.00	Unregistered
51a415be-702a-4163-84d6-f9023a67d9d7	cmofl3ut6000hmjdmwqd3dziu	NARENDRA SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
50b28498-9fb0-41df-8c41-05d5e568a8d1	cmofl3ut6000hmjdmwqd3dziu	Naresh Agbihotri	Sundry Debtors	\N	\N	0.00	Unregistered
b4d00bdd-d1f9-45b5-ac7a-782320666423	cmofl3ut6000hmjdmwqd3dziu	Naresh Pal	Sundry Debtors	\N	\N	0.00	Unregistered
01921441-9c4e-4f35-85a2-dde780c68a1d	cmofl3ut6000hmjdmwqd3dziu	NATH CORPORATION	Sundry Debtors	09AHDPG8526F1ZD	\N	0.00	Regular
4e7825df-6a8b-412e-a259-5c787309ece0	cmofl3ut6000hmjdmwqd3dziu	Nath Fertilizer and Chemicals	Sundry Creditors	09AFNPG2976F1Z5	\N	0.00	Regular
e07a4597-52b3-4df8-9099-ddf875990958	cmofl3ut6000hmjdmwqd3dziu	Nathu Ram Tripathi and Asha Tripathi	Sundry Debtors	\N	\N	0.00	Unregistered
b8de8094-d8c6-4630-abaf-fe650657a43b	cmofl3ut6000hmjdmwqd3dziu	NAV DURGA FUEL PVT LTD	Sundry Creditors	22AABCN9131F1ZU	\N	0.00	Regular
e46b7769-45f6-4016-9065-8ad1f8c94acc	cmofl3ut6000hmjdmwqd3dziu	Naveen Shiksha Samiti	Sundry Debtors	\N	\N	0.00	Unregistered
1ccc2384-9c8f-4d9d-b704-51d74bea1c72	cmofl3ut6000hmjdmwqd3dziu	Navneet Bajpai	Sundry Debtors	\N	\N	0.00	\N
452efc01-04db-4c3a-b466-47a723f1d4c4	cmofl3ut6000hmjdmwqd3dziu	Navneet Dixit	Sundry Debtors	\N	\N	0.00	Unregistered
890ff2f9-e045-4678-a829-5ebacf968d52	cmofl3ut6000hmjdmwqd3dziu	Navneet Goyal	Sundry Debtors	\N	\N	20000.00	\N
268843d6-4214-4d49-92cd-4194a5c12c5e	cmofl3ut6000hmjdmwqd3dziu	NAVNEET SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
b6853298-ec85-43ef-9b9d-8ba0f7c04315	cmofl3ut6000hmjdmwqd3dziu	NAVRATRI TRADERS	Sundry Debtors	\N	\N	0.00	Unregistered
a3f1b4eb-f690-4de5-b179-9fe21f5315dd	cmofl3ut6000hmjdmwqd3dziu	NEELAM SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
7b6a7cf4-6116-4202-b9ff-709243143712	cmofl3ut6000hmjdmwqd3dziu	NEELU KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
68159cc9-567e-4ae9-afc8-41be5af02c80	cmofl3ut6000hmjdmwqd3dziu	Neelu Pal	Sundry Debtors	\N	\N	0.00	\N
fb0fdd41-8dd3-4e6b-90da-240150999b2a	cmofl3ut6000hmjdmwqd3dziu	Neena Builders	Sundry Debtors	09CETPP2969G1ZN	\N	0.00	Regular
db878fa9-ba82-42e8-9a1a-4952d60391d1	cmofl3ut6000hmjdmwqd3dziu	Neeraj Agnihotri	Sundry Debtors	\N	\N	0.00	Unregistered
b80b6bcc-a2ba-4a8e-a665-30220e7b93a2	cmofl3ut6000hmjdmwqd3dziu	NEETA GARG	Sundry Debtors	\N	\N	0.00	Unregistered
ef8b6cf9-2af8-4d45-b8bf-92b59ee1419a	cmofl3ut6000hmjdmwqd3dziu	Neetesh Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
97ebfe1d-ad57-422c-a66b-6e663249b9d8	cmofl3ut6000hmjdmwqd3dziu	Neetu Jain	Sundry Debtors	\N	\N	0.00	Unregistered
fa31cc56-b18d-4c89-a727-a4ec487b9a5d	cmofl3ut6000hmjdmwqd3dziu	New Akhand Bharat Transport Co.	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
aed3bee3-5913-4409-a1a9-2b0a98665865	cmofl3ut6000hmjdmwqd3dziu	New A.K. Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
b2f83ca3-7b31-4dbd-b53f-b2cc7ab1cc7b	cmofl3ut6000hmjdmwqd3dziu	NEW Binod Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	\N
0b561838-8fe6-49fb-91a2-091e81e704e7	cmofl3ut6000hmjdmwqd3dziu	NEW GOEYL TRADERS	Sundry Debtors	\N	\N	0.00	Regular
ac3abd0e-6558-4d09-b820-9a53a12e0eb3	cmofl3ut6000hmjdmwqd3dziu	NEW INDIA ENTERPRISES	Sundry Debtors	09ASQPT7759M1ZC	\N	0.00	Regular
b865116e-a1b0-45a3-9465-447e610c0ad3	cmofl3ut6000hmjdmwqd3dziu	NEW JAI BHOLA ROADLINES	Sundry Creditors for Transporter	\N	\N	0.00	\N
6d20447d-e53c-4d55-9699-72de3345d463	cmofl3ut6000hmjdmwqd3dziu	New Kanpur Agra Roadways	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
8c071913-c4a4-493d-bd35-8fac5c3fbf01	cmofl3ut6000hmjdmwqd3dziu	New Kanpur Bangal  Transport	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
d9798ba7-6809-49ca-add7-e4e6fd3358ec	cmofl3ut6000hmjdmwqd3dziu	New Madhya Pradesh Bomaby Transport Co.	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
c910bc8f-45ab-4393-9d9f-bffaeaab359e	cmofl3ut6000hmjdmwqd3dziu	New Metro  Transport Service	Sundry Creditors for Transporter	\N	\N	0.00	\N
4e3a8a79-1ecf-424b-9b52-605fde623f8c	cmofl3ut6000hmjdmwqd3dziu	NEW NATIONAL TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
d3ce2d76-0fea-4186-b907-d0889fcb0497	cmofl3ut6000hmjdmwqd3dziu	New Rajdhani Transport Service	Sundry Creditors for Transporter	\N	\N	0.00	Regular
c3ca763f-ad1e-4c7e-81b7-6d534f377bec	cmofl3ut6000hmjdmwqd3dziu	New Saxena Forwarding Agency	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
363c214c-57fb-4e8d-b9ce-6f85255707c5	cmofl3ut6000hmjdmwqd3dziu	New Shri Ganpati Transports Services	Sundry Creditors for Transporter	\N	\N	0.00	\N
56098095-7fad-4eff-b338-ce6b66f78e73	cmofl3ut6000hmjdmwqd3dziu	New Shri Mahavir Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
e92d179b-5832-49a3-9f92-5ae4887b1522	cmofl3ut6000hmjdmwqd3dziu	NEW U P MAHARASHTRA ROAD LINES	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
e4f0a534-bc92-4abf-aaa0-f7dc96577f23	cmofl3ut6000hmjdmwqd3dziu	New Vikas Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
ad1b768d-2c53-4f17-b9d3-0fec178fabcc	cmofl3ut6000hmjdmwqd3dziu	Nextax Technologies Private Limited	Sundry Creditors	\N	\N	6750.00	\N
06b0bbd4-6135-4bac-96b8-ed5c20c791c3	cmofl3ut6000hmjdmwqd3dziu	N.Gupta Agarwal &amp; Associates	Current Liabilities	\N	\N	0.00	Unregistered
ddceeffb-5f29-4e97-95ca-3d1fd9bf7b84	cmofl3ut6000hmjdmwqd3dziu	NIKKI GOODS CARRIER	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
07c7ba2e-b249-4694-beab-44dca94822c8	cmofl3ut6000hmjdmwqd3dziu	NILESH KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
1de16c6f-cd7a-417e-9cc6-d2830ad466cc	cmofl3ut6000hmjdmwqd3dziu	NILKANTH CREATION	Sundry Debtors	\N	\N	0.00	Unregistered
e601701b-90e2-45d1-8a3d-463f7e35a18d	cmofl3ut6000hmjdmwqd3dziu	Nirmal Singh	Sundry Debtors	\N	\N	0.00	\N
d8b2d4db-3de4-4e5b-a4b8-8c92e435100f	cmofl3ut6000hmjdmwqd3dziu	NISHA	Sundry Debtors	\N	\N	0.00	Unregistered
4afda02f-ee83-41f0-bda4-bdc80c0320e7	cmofl3ut6000hmjdmwqd3dziu	NISHANT	Sundry Debtors	\N	\N	0.00	Unregistered
1d0a38b0-5426-4e07-a845-4c1c37487741	cmofl3ut6000hmjdmwqd3dziu	Nitin	Sundry Debtors	\N	\N	0.00	\N
af05eb5b-d758-4349-be69-c6b5ee28a72e	cmofl3ut6000hmjdmwqd3dziu	NORTHERN ALLOYS	Sundry Debtors	09AARPG1800D1Z2	\N	0.00	Regular
91703d45-0fd1-47b5-8977-5efb0b46ecb6	cmofl3ut6000hmjdmwqd3dziu	N R AGENCIES PRIVATE LIMITED	Sundry Debtors	\N	\N	0.00	Unregistered
db9f006e-e7ee-42fb-8374-3c4540fb6e0f	cmofl3ut6000hmjdmwqd3dziu	N S Pandey	Sundry Debtors	\N	\N	0.00	Unregistered
f2e35078-f585-4521-b4b2-873bf8e25f7d	cmofl3ut6000hmjdmwqd3dziu	ODISHA GHAZIABAD ROAD LINES	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
718add33-744b-445d-a402-543d982eea42	cmofl3ut6000hmjdmwqd3dziu	ODISHA SOUTH ROADWAYS	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
c0af06ef-89e2-4016-8767-989d069f5fd9	cmofl3ut6000hmjdmwqd3dziu	Office Equipment	Fixed Assets	\N	\N	-13070.18	\N
ae219cea-703b-4faf-b098-6b5da075235d	cmofl3ut6000hmjdmwqd3dziu	Office Expenses	Indirect Expenses	\N	\N	0.00	\N
5f799cb4-4ae4-40c8-9f03-2e6e4b36469c	cmofl3ut6000hmjdmwqd3dziu	Office Repair and Maintinance	Indirect Expenses	\N	\N	0.00	\N
a744f616-ee0f-46bd-a836-65b32415b80e	cmofl3ut6000hmjdmwqd3dziu	Om Narayan	Sundry Debtors	\N	\N	0.00	Unregistered
1adfcea8-4b07-4d54-8a4c-1ec20b5b30fc	cmofl3ut6000hmjdmwqd3dziu	OM PRAKASH	Sundry Debtors	\N	\N	0.00	Unregistered
af9faf28-93b7-4071-a05c-7a7d5166ec11	cmofl3ut6000hmjdmwqd3dziu	OM PRAKASH AGARWAL	Sundry Debtors	\N	\N	0.00	Unregistered
00920ab2-1bb0-4f4d-bd96-41dff52d77f2	cmofl3ut6000hmjdmwqd3dziu	OM PRAKASH ASSOCIATES	Sundry Debtors	09ACMPP6503H2ZB	\N	0.00	Regular
6c0f8024-05e8-4dce-a0e2-29e273102ffa	cmofl3ut6000hmjdmwqd3dziu	OM PRAKASH MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
c4a16ab7-7ae5-4717-b023-5ef63d203f94	cmofl3ut6000hmjdmwqd3dziu	OM PRAKASH YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
ce17fec3-862b-41f0-9307-ba80a7e2fd5c	cmofl3ut6000hmjdmwqd3dziu	OM SAI ENTERPRISES	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
f3c576d1-90a3-4b66-ba2f-670067d8db55	cmofl3ut6000hmjdmwqd3dziu	OM TRADING COMPANY	Sundry Debtors	09AAEFO8091P1ZE	\N	0.00	Regular
04c7f248-8e5d-4564-853f-4a6bf0444cf1	cmofl3ut6000hmjdmwqd3dziu	OM TRANSPORT COMMISSION AGENCY	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
e555328d-e099-4199-b2ea-a689b0cc21c6	cmofl3ut6000hmjdmwqd3dziu	OM_ PRAKASH	Sundry Debtors	\N	\N	0.00	\N
a7594c54-9239-4f13-bd24-fa0e4d33c55b	cmofl3ut6000hmjdmwqd3dziu	O.P.  Agarwal &amp; Co.	Sundry Debtors	09ABNPA4853D1ZR	\N	0.00	Regular
36739324-0640-406a-ab5a-2fac64415e46	cmofl3ut6000hmjdmwqd3dziu	Opening Stock	Stock-in-Hand	\N	\N	-10634390.00	\N
a6ecaffc-ffb5-4440-9c81-e7012452bc13	cmofl3ut6000hmjdmwqd3dziu	ORISSA STEEL &amp; POWER PRIVATE LIMITED	Sundry Creditors	\N	\N	0.00	\N
ff682595-f85a-4620-8857-114b4190304c	cmofl3ut6000hmjdmwqd3dziu	ORISSA TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
3874d86a-2039-4bba-a776-b109c605aa16	cmofl3ut6000hmjdmwqd3dziu	Oumkar	Sundry Debtors	\N	\N	0.00	Unregistered
43519200-2229-4e34-bdf1-1926ad283f12	cmofl3ut6000hmjdmwqd3dziu	Pace Infratech Pvt Ltd	Sundry Debtors	09AAGCP9099R1Z3	\N	0.00	Regular
05a7e4ac-ae91-487e-9e22-aa073a42620a	cmofl3ut6000hmjdmwqd3dziu	Pal Iron Traders	Sundry Debtors	09AJEPP4829P1ZF	\N	0.00	Regular
9a750bd5-ab86-4919-b60c-952d78a8fd6a	cmofl3ut6000hmjdmwqd3dziu	Pal Trading Company	Sundry Debtors	09FZPPP5081R1Z1	\N	0.00	Regular
30fce78d-b600-4a19-a76f-8667c0574e34	cmofl3ut6000hmjdmwqd3dziu	PANDEY TRANSPORT SERVICE	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
ad6fb27e-988e-48bd-a597-b140448fd95e	cmofl3ut6000hmjdmwqd3dziu	Panem Industries Pvt Limited	Sundry Creditors	09AAACP8592R1ZD	\N	0.00	Regular
63d19fda-3d7b-4013-80c3-0d618a8d13ea	cmofl3ut6000hmjdmwqd3dziu	PANKAJ AGARWAL	Sundry Debtors	\N	\N	0.00	Unregistered
2fa3c8c3-da2d-4a79-934d-b4f8305435be	cmofl3ut6000hmjdmwqd3dziu	Pankaj Awasthi	Sundry Debtors	\N	\N	0.00	Unregistered
6f568ab4-1201-4689-ba19-63e438a8cb40	cmofl3ut6000hmjdmwqd3dziu	PANKAJ CHOUBEY	Sundry Debtors	\N	\N	0.00	Unregistered
2f1c4f27-8b6c-4ca0-aeb3-d5220a2111a4	cmofl3ut6000hmjdmwqd3dziu	Pankaj Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
2df3a1f0-574a-4e41-86db-62469a41111e	cmofl3ut6000hmjdmwqd3dziu	PANKAJ KUMAR SRIVASTAVA	Sundry Debtors	\N	\N	0.00	Unregistered
a84f82c2-fbcc-46bb-b22a-f65f007b357d	cmofl3ut6000hmjdmwqd3dziu	Pankaj Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
17ec041f-76e6-4feb-af93-8bff2fba7575	cmofl3ut6000hmjdmwqd3dziu	PARAS CASTING  &amp; ALLOYS PVT LTD	Sundry Creditors	09AACCP9180H1Z2	\N	0.00	Regular
2d0f8761-09aa-497d-acd0-41bf8b2370f7	cmofl3ut6000hmjdmwqd3dziu	PARUL ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
ef241f8c-4421-4a2c-91b5-63c8d04ff2cb	cmofl3ut6000hmjdmwqd3dziu	Parul Jain Vansh Jain	Sundry Debtors	\N	\N	0.00	\N
68956ea1-8128-4c35-9fd1-03dd88a7953a	cmofl3ut6000hmjdmwqd3dziu	Parvejz Trading Co.	Sundry Debtors	09AEPPA3507B1ZY	\N	0.00	Regular
24478455-4781-4a77-bcd5-aa7b11937e2a	cmofl3ut6000hmjdmwqd3dziu	PARVESH MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
ed9fd3c1-ee8c-435f-b4c6-718d7b4ce9d7	cmofl3ut6000hmjdmwqd3dziu	PASSION INFRAHEIGHT LLP	Sundry Debtors	\N	\N	0.00	\N
e17a6845-12fe-478c-ac24-ea12f07701b0	cmofl3ut6000hmjdmwqd3dziu	Patanjali	Sundry Debtors	\N	\N	0.00	\N
20080f20-7ebf-4512-9787-92eda4b750da	cmofl3ut6000hmjdmwqd3dziu	Pawan Awadhiya	Sundry Debtors	\N	\N	0.00	Unregistered
0104d04d-77ec-4d23-86a8-c22640e0491e	cmofl3ut6000hmjdmwqd3dziu	PAWAN GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
02389271-4010-41e1-8aaf-65f0d883fe73	cmofl3ut6000hmjdmwqd3dziu	Pawan Jaiswal Huf	Sundry Debtors	\N	\N	0.00	Unregistered
8696685a-7dc0-4793-9749-274f88527fc1	cmofl3ut6000hmjdmwqd3dziu	Pawan Kumar Agarwal	Sundry Debtors	\N	\N	0.00	Unregistered
1e5c3c07-e2d1-42fa-9b0f-5240503a4c7f	cmofl3ut6000hmjdmwqd3dziu	Pawan Kumar Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
f43bba9c-24d7-479a-8507-f17297fff6af	cmofl3ut6000hmjdmwqd3dziu	PAWAN MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
4d263e66-5e10-44a9-9ece-3244c21816c1	cmofl3ut6000hmjdmwqd3dziu	Pawan Sharma	Sundry Debtors	\N	\N	0.00	\N
c932a943-0862-4aaf-825e-da1c4269a220	cmofl3ut6000hmjdmwqd3dziu	PAWAN SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
212a5eb8-a8ac-4d1f-b8df-48483079dbb0	cmofl3ut6000hmjdmwqd3dziu	PAWAN STEELS	Sundry Debtors	\N	\N	0.00	Regular
23d9e859-3baf-4e8a-bd5d-695d7785b889	cmofl3ut6000hmjdmwqd3dziu	Pawn Kumar Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
68a99ca0-b58e-4e43-9ab6-490b86740703	cmofl3ut6000hmjdmwqd3dziu	Pawn Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
96da8b4e-e976-4dc0-8cdc-5c337c5682dd	cmofl3ut6000hmjdmwqd3dziu	P.C. CONSTRUCTION	Sundry Debtors	09AFGPC7770Q1ZR	\N	0.00	Regular
c0f10d0f-2dd1-4eec-9c3a-ba8302607e1f	cmofl3ut6000hmjdmwqd3dziu	Perfect Enterprises	Sundry Debtors	09EOKPA5303G1Z6	\N	0.00	Regular
513b92e3-e74c-4348-a944-724f7a842845	cmofl3ut6000hmjdmwqd3dziu	PHOOL CHANDRA YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
6a71f084-6c2a-4ca4-806e-f342f06a6296	cmofl3ut6000hmjdmwqd3dziu	PINKI	Sundry Debtors	\N	\N	0.00	Unregistered
c35732b1-b96d-415a-8c2b-d4dbe256b521	cmofl3ut6000hmjdmwqd3dziu	Piysuh Awasthi	Sundry Debtors	\N	\N	0.00	Unregistered
fe6347d1-fbd2-41ca-ae48-3fd95fee1a70	cmofl3ut6000hmjdmwqd3dziu	Piyush Bajpai	Sundry Debtors	\N	\N	0.00	Unregistered
74e2c763-20a0-4c55-9bb8-e3fcc1ad75d1	cmofl3ut6000hmjdmwqd3dziu	Piyush Singh	Sundry Debtors	\N	\N	0.00	\N
7a01309e-20d3-41a6-b139-deeb6ef552be	cmofl3ut6000hmjdmwqd3dziu	PNB A/C NO. 0254000130123074	Bank Accounts	\N	\N	-151346.32	\N
d89f2182-9bb1-4492-8e4e-af6475306b94	cmofl3ut6000hmjdmwqd3dziu	PNB HOUSING FINANCE LTD	Investments	\N	\N	-1790904.00	\N
875f8ab7-cf70-4acf-80c9-b29f780a0b1f	cmofl3ut6000hmjdmwqd3dziu	Pooja Enterprises	Sundry Debtors	09ERJPS0079B1ZM	\N	0.00	Regular
4d33937d-54a4-4140-8305-1efc460b26b4	cmofl3ut6000hmjdmwqd3dziu	POONAM  KUMARI	Sundry Debtors	\N	\N	0.00	Unregistered
a6f27167-78b8-4faf-98ec-7499a03b0217	cmofl3ut6000hmjdmwqd3dziu	P P F A/c Corp Bank A/c No. 17662PPF000008	Investments	\N	\N	-531290.00	\N
287ff1d9-abf8-4f5c-bc65-13ba745ac0fa	cmofl3ut6000hmjdmwqd3dziu	Prabhujee Divilling	Sundry Debtors	09ABCFP5148F1Z6	\N	0.00	Regular
379592b5-6bd1-4115-90d7-8e74192303c5	cmofl3ut6000hmjdmwqd3dziu	PRABHU KRIPA TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
3be189a0-725a-463a-b561-ee0f711603fe	cmofl3ut6000hmjdmwqd3dziu	Prachi Leather Pvt Ltd	Sundry Debtors	09AAACP8242N1ZY	\N	0.00	Regular
82a8736f-e579-4c01-8fa2-ff2954054a40	cmofl3ut6000hmjdmwqd3dziu	Pradeep Arora	Sundry Debtors	\N	\N	0.00	Unregistered
49810d51-6f5d-4db0-921d-6c272a248c4a	cmofl3ut6000hmjdmwqd3dziu	Pradeep Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
24c3f193-f5b9-4f9c-ada0-f2355f0fa562	cmofl3ut6000hmjdmwqd3dziu	Pradeep Kumarrr	Sundry Debtors	\N	\N	0.00	\N
66db2cde-f5a7-46ee-8ba5-03d352d37919	cmofl3ut6000hmjdmwqd3dziu	Pradeep Kumar Shukla	Sundry Debtors	\N	\N	0.00	Unregistered
592bff50-91c6-4cf6-99a7-70a66d2fce5c	cmofl3ut6000hmjdmwqd3dziu	Pradeep Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
f673d4c0-2d26-4f82-bc0d-7d92ccfa3371	cmofl3ut6000hmjdmwqd3dziu	Pradeep Singh	Sundry Debtors	\N	\N	0.00	Unregistered
dff4fa05-eb99-4ddc-b209-df94603609c7	cmofl3ut6000hmjdmwqd3dziu	Pradeep Singhh	Sundry Debtors	\N	\N	0.00	Unregistered
c6f96b18-428e-41ba-a7b3-bc3af624a164	cmofl3ut6000hmjdmwqd3dziu	Pradeep  Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
4e4869f7-147d-4f44-9038-f1d9263e6c7c	cmofl3ut6000hmjdmwqd3dziu	Pradeep_kumar	Sundry Debtors	\N	\N	0.00	Unregistered
66c46d46-1e55-4640-9fef-f5f6fb92312c	cmofl3ut6000hmjdmwqd3dziu	PRAKASH KUMAR TRIVEDI	Sundry Debtors	\N	\N	0.00	Unregistered
c26f63a1-855c-4129-9007-eefc1cd7b514	cmofl3ut6000hmjdmwqd3dziu	Prakash Traders and Construction	Sundry Debtors	09AIFPB5090A2ZP	\N	0.00	Regular
c5bb429d-db5b-472b-a920-88419e1b31ec	cmofl3ut6000hmjdmwqd3dziu	Praksh Chandra Gupts	Sundry Debtors	\N	\N	0.00	Unregistered
467f4ac0-a467-4eb9-a592-98a35b0edd0a	cmofl3ut6000hmjdmwqd3dziu	Pramod Kumar Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
9d1ced75-1bb9-4f21-88cc-b8bf069e0b24	cmofl3ut6000hmjdmwqd3dziu	Pramod Kumar Shukla	Sundry Debtors	\N	\N	0.00	Unregistered
4f3c623c-1bcd-4c24-bc57-d925a96012a9	cmofl3ut6000hmjdmwqd3dziu	Prashan Kumar Singh	Sundry Debtors	\N	\N	0.00	Unregistered
e06992f0-1b95-4f06-8ad3-773135d74a2c	cmofl3ut6000hmjdmwqd3dziu	PRASHANT	Sundry Debtors	\N	\N	0.00	Unregistered
5a99430c-86f0-4154-848b-49b3dd98461c	cmofl3ut6000hmjdmwqd3dziu	PRASHANT MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
e38a9271-14cd-4984-9640-fec04622a806	cmofl3ut6000hmjdmwqd3dziu	PRASHANT SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
b04d65d0-164a-403c-aed1-e5dc8a4d63cf	cmofl3ut6000hmjdmwqd3dziu	PRASHANT YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
7dd41bdd-d7ec-469a-ac80-4ba216bcf8c6	cmofl3ut6000hmjdmwqd3dziu	Prateek Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
37606e3a-14dd-4f0c-b18a-0b7e849689ab	cmofl3ut6000hmjdmwqd3dziu	PRAVEEN KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
9dd3ae8b-6277-4baf-bb0d-764cecab32b7	cmofl3ut6000hmjdmwqd3dziu	PRAVESH MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
b7da7bb1-fe89-471d-b6e9-e2857bded701	cmofl3ut6000hmjdmwqd3dziu	Preetam	Sundry Debtors	\N	\N	0.00	Unregistered
bb719514-d890-43c0-8e34-2babe2640e7e	cmofl3ut6000hmjdmwqd3dziu	PREMIER ISPAT LIMITED	Sundry Creditors	09AABCP9915D1ZC	\N	0.00	Regular
0afe3355-973b-4944-926b-0b183481615c	cmofl3ut6000hmjdmwqd3dziu	Prepaid Insurance	Loans & Advances (Asset)	\N	\N	-493.00	Unregistered
5314aaa0-4cd7-4db0-8673-6d94a421198c	cmofl3ut6000hmjdmwqd3dziu	Printing  and Stationery	Indirect Expenses	\N	\N	0.00	\N
3e67d950-31a7-4d6f-8af8-3ec66e46b6c7	cmofl3ut6000hmjdmwqd3dziu	PRITU PAL	Sundry Debtors	\N	\N	0.00	Unregistered
4ef901ea-da97-4eee-a897-05770898d73c	cmofl3ut6000hmjdmwqd3dziu	Priya	Sundry Debtors	\N	\N	0.00	\N
9df716a8-f5a1-4e7e-99dc-093fbe6b12df	cmofl3ut6000hmjdmwqd3dziu	Priya Construction	Sundry Debtors	\N	\N	0.00	\N
5427407b-2a31-4bff-9896-d79d57815c6e	cmofl3ut6000hmjdmwqd3dziu	Priyanka Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
07975098-ef89-408f-b4c9-e36250e7f5df	cmofl3ut6000hmjdmwqd3dziu	Priyanka Katheria	Sundry Debtors	\N	\N	0.00	Unregistered
3e717f76-73a4-4688-b293-9cd0d58fc9e2	cmofl3ut6000hmjdmwqd3dziu	Priyanka Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
55b7505e-428c-4365-b291-f39b6efc4544	cmofl3ut6000hmjdmwqd3dziu	PRIYANKA SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
1264f867-eb82-43ee-9519-0fb34bb440b0	cmofl3ut6000hmjdmwqd3dziu	PRIYANSHU ROAD LINES	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
3d00b255-1a47-44f6-acdd-db5dba420ad6	cmofl3ut6000hmjdmwqd3dziu	Priyanshu Saini	Sundry Debtors	\N	\N	0.00	Unregistered
63a4f14f-cfc7-4423-acaa-e52121629861	cmofl3ut6000hmjdmwqd3dziu	PRMILA SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
242350fe-6f84-45c4-b0af-839800118b5b	cmofl3ut6000hmjdmwqd3dziu	Profit &amp; Loss A/c	&#4; Primary	\N	\N	0.00	\N
07e5a0cf-a536-4846-829e-509d7923344c	cmofl3ut6000hmjdmwqd3dziu	Property insurance	Capital Account	\N	\N	0.00	Unregistered
d47f101d-46fa-4d25-a41a-5a7884bf1e9f	cmofl3ut6000hmjdmwqd3dziu	Protean eGov Technologies Limited&#13;&#10;	Sundry Creditors	27AAACN2082N1Z8&#13;&#10;	\N	0.00	Regular
91aeba10-c37f-4008-a46c-1406e7970dea	cmofl3ut6000hmjdmwqd3dziu	P.S.U.D ACADEMY ITER COLLEGE	Sundry Debtors	\N	\N	0.00	\N
a28f00aa-4f76-4aec-9f24-1790bf3938e5	cmofl3ut6000hmjdmwqd3dziu	Punam Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
8f929793-72ea-42cb-8d8f-4e3095ed16e8	cmofl3ut6000hmjdmwqd3dziu	Punjab Banglore Road Linse	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
bbd85839-f166-4f82-a12c-325292c91380	cmofl3ut6000hmjdmwqd3dziu	Punjab Transport Service	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
151e8f82-27b2-436c-8620-b9fab2d3d882	cmofl3ut6000hmjdmwqd3dziu	PURCHASE	Purchase Accounts	\N	\N	0.00	\N
21a77b1d-f3ac-4491-9096-534155496b05	cmofl3ut6000hmjdmwqd3dziu	PURCHASE GST LOCAL 28%	Purchase Accounts	\N	\N	0.00	\N
eff73956-dc5e-408b-81f1-ede179fea241	cmofl3ut6000hmjdmwqd3dziu	PURCHASE GST LOCAL@18%	Purchase Accounts	\N	\N	0.00	\N
cf8c0e3f-c4a8-4dd9-9375-e276afafa9e1	cmofl3ut6000hmjdmwqd3dziu	PURCHASE IGST-CENTRAL@18%	Purchase Accounts	\N	\N	0.00	\N
ee8fc73f-d300-4e1b-906f-2be480beb09d	cmofl3ut6000hmjdmwqd3dziu	Purchase Not Reflect in 3b	Purchase Accounts	\N	\N	0.00	\N
f4e54447-2064-4361-a82f-d5fa906087d8	cmofl3ut6000hmjdmwqd3dziu	Purchase Returned	Purchase Accounts	\N	\N	0.00	\N
936b6dea-40a8-40c2-8ad4-a29adc88e12f	cmofl3ut6000hmjdmwqd3dziu	Pushpa Katiyar	Sundry Debtors	\N	\N	0.00	Unregistered
f80d36c7-08b9-45e4-9837-ee241364a019	cmofl3ut6000hmjdmwqd3dziu	PUSHPANJALI BHARTI	Sundry Debtors	\N	\N	0.00	Unregistered
97e75537-3c5a-4e5f-b36e-d8543897e580	cmofl3ut6000hmjdmwqd3dziu	PUSHPA RAJ SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
fc376f3d-94b5-47cb-860e-d25d9b727e9e	cmofl3ut6000hmjdmwqd3dziu	PUSHP LATA	Sundry Debtors	\N	\N	0.00	Unregistered
3ed91de9-d2ad-4513-b15c-c1e7f3ce6bce	cmofl3ut6000hmjdmwqd3dziu	QAMAR Alam Khan	Sundry Debtors	\N	\N	0.00	Unregistered
a3934bbb-a7d4-4081-a31d-6ec7e23a695d	cmofl3ut6000hmjdmwqd3dziu	QUICK TRANS SOLUTION	Sundry Creditors for Transporter	\N	\N	0.00	\N
6698404d-7074-4fdc-b388-78f288c513d1	cmofl3ut6000hmjdmwqd3dziu	RABINDRA SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
07c1b2da-d534-45ed-8634-dcb4e5a3634a	cmofl3ut6000hmjdmwqd3dziu	Rachan Agarwal	Sundry Debtors	\N	\N	0.00	Unregistered
f7073d0a-730a-4406-b1e3-276be1670555	cmofl3ut6000hmjdmwqd3dziu	Radha Cycle Repairing and Battery	Sundry Debtors	\N	\N	0.00	Unregistered
db703719-2917-4874-b04c-9518708a4c75	cmofl3ut6000hmjdmwqd3dziu	Radha Krishna Transport	Sundry Creditors for Transporter	\N	\N	0.00	Regular
d9674b83-ea07-47de-a849-e896985b574c	cmofl3ut6000hmjdmwqd3dziu	Radha Krishna Tripathi	Sundry Debtors	\N	\N	0.00	Unregistered
a49d1c7d-e42c-43ec-a982-8b19c06f8d6a	cmofl3ut6000hmjdmwqd3dziu	RADHA MOHAN SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
84ad22c6-436c-43c1-bdf9-7a4399661ed7	cmofl3ut6000hmjdmwqd3dziu	Radhey Jha	Sundry Debtors	\N	\N	0.00	Unregistered
1e370404-641e-4bb5-8003-bc1b5339e771	cmofl3ut6000hmjdmwqd3dziu	Radhey Radhey Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
6460c015-dbd3-4ddc-a4bf-300514c9a239	cmofl3ut6000hmjdmwqd3dziu	RADHEY RADHEY TRANSPORT COMPANY	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
e5fd53b3-2f56-45db-b63c-15943453ab1a	cmofl3ut6000hmjdmwqd3dziu	Radheyshyam Road Carrier	Sundry Creditors for Transporter	\N	\N	0.00	Regular
d279bee8-9270-412b-bfc8-532f9da4161f	cmofl3ut6000hmjdmwqd3dziu	RADHEY SHYAM TIWARI	Sundry Debtors	\N	\N	0.00	Unregistered
f7683149-56a3-4aed-aa87-4c5c49f02db4	cmofl3ut6000hmjdmwqd3dziu	RAGHVENDRA KAMAL	Sundry Debtors	\N	\N	0.00	Unregistered
e5a0dbc7-b643-485c-82ca-26f8ec065b25	cmofl3ut6000hmjdmwqd3dziu	RAGHVENDRA SINGH YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
10b21499-3989-4cfb-a8b8-15164eb311aa	cmofl3ut6000hmjdmwqd3dziu	RAG STEELS	Sundry Creditors	09ABKPV1221D1ZT	\N	0.00	Regular
11915e6e-c147-49b4-92eb-c6387aa5f30e	cmofl3ut6000hmjdmwqd3dziu	RAHUL BHASKAR	Sundry Debtors	\N	\N	0.00	Unregistered
55f6bbc8-c564-4ab5-aff5-50d4e7251921	cmofl3ut6000hmjdmwqd3dziu	Rahul Dev	Sundry Debtors	\N	\N	0.00	Unregistered
f23cc8c5-b54f-4aeb-8b2e-66f2d4c86994	cmofl3ut6000hmjdmwqd3dziu	RAHUL PAL	Sundry Debtors	\N	\N	0.00	Unregistered
52373bf3-c635-4ac1-a84c-57a8d05b3d9d	cmofl3ut6000hmjdmwqd3dziu	Rahul Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
053dcafd-5d88-419a-9faf-4bf817940771	cmofl3ut6000hmjdmwqd3dziu	RAI BROTHER	Sundry Debtors	\N	\N	0.00	Unregistered
740464f1-0ffd-4868-ba86-8b2065e9d602	cmofl3ut6000hmjdmwqd3dziu	RAJ AGENCIES	Sundry Debtors	09AYUPS6507Q1Z5	\N	0.00	Regular
3649209a-a94f-408d-933e-73e9d13c646f	cmofl3ut6000hmjdmwqd3dziu	RAJ AND SONS ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
92c5ccf3-0648-4396-9902-d4eee2ba63a7	cmofl3ut6000hmjdmwqd3dziu	RAJAN GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
72a0e357-47de-4c43-9811-1fd65f266fab	cmofl3ut6000hmjdmwqd3dziu	RAJANI AWASTHI	Sundry Debtors	\N	\N	0.00	Unregistered
045e11a7-c673-4981-8c86-21974e4d4660	cmofl3ut6000hmjdmwqd3dziu	Rajan Paper Core Industries	Sundry Debtors	09AALFR1926K1ZS	\N	0.00	Regular
4074d130-04a9-421a-927d-06dc4060e8ac	cmofl3ut6000hmjdmwqd3dziu	Raja Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
d0f87364-40b5-4e82-83b0-6cdad2656591	cmofl3ut6000hmjdmwqd3dziu	Rajasthan Haryana Transport Company	Sundry Creditors for Transporter	20BMHPR9555H1ZR	\N	0.00	Regular
99da8602-5332-4a88-8066-1350ee5c493b	cmofl3ut6000hmjdmwqd3dziu	Rajdhani Transport	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
2fbdd89d-1c7a-41af-998a-43b719e50f9d	cmofl3ut6000hmjdmwqd3dziu	Rajeev  Jain ----------Huf	Unsecured Loans	\N	\N	1527874.00	Unregistered
f64125c7-f785-4e3e-9c6e-29488152bff5	cmofl3ut6000hmjdmwqd3dziu	Rajeev Verma	Sundry Debtors	\N	\N	0.00	Unregistered
13537d80-f1a6-42f5-8637-b1a614acf28f	cmofl3ut6000hmjdmwqd3dziu	RAJENDRA AGARWAL AND ASSOCIATE	Sundry Debtors	09AABFR3137J1Z5	\N	0.00	Regular
4ffdabd7-e054-43c2-988c-8f5a4d6475e2	cmofl3ut6000hmjdmwqd3dziu	Rajendra Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
a2962d1b-744f-43ce-abac-8641ab92d6ee	cmofl3ut6000hmjdmwqd3dziu	Rajendra Kumar Dixit	Sundry Debtors	\N	\N	0.00	Unregistered
9055255a-5955-4d13-be99-1b53c2e101ab	cmofl3ut6000hmjdmwqd3dziu	Rajendra Kumar Kanojiya	Sundry Debtors	\N	\N	0.00	Unregistered
415cf73f-b47a-4508-8b84-efb5b69c7560	cmofl3ut6000hmjdmwqd3dziu	RAJENDRA SINGH YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
df81279a-5477-42c2-b03b-6a143e2f9706	cmofl3ut6000hmjdmwqd3dziu	RAJENDRA VERMA	Sundry Debtors	\N	\N	0.00	Unregistered
ecae0d8f-e747-41a4-871a-33c1273750f0	cmofl3ut6000hmjdmwqd3dziu	RAJESH GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
19a4a3a1-5d24-4a6e-a46e-07744e7d4fd4	cmofl3ut6000hmjdmwqd3dziu	Rajesh Kumar GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
d1f5a70d-6d6e-4a0b-9250-fad25c142326	cmofl3ut6000hmjdmwqd3dziu	Rajesh Kumar Maurya	Sundry Debtors	\N	\N	0.00	Unregistered
8f864424-8250-495a-b5e5-3cb3cbc5186d	cmofl3ut6000hmjdmwqd3dziu	Rajesh Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
5cd32090-8c85-4f34-b420-cbf5d1ef722e	cmofl3ut6000hmjdmwqd3dziu	RAJESH  PAL	Sundry Debtors	\N	\N	0.00	Unregistered
35e670f2-8d72-4e3e-a651-960f74459c8d	cmofl3ut6000hmjdmwqd3dziu	Rajesh Pandey	Sundry Debtors	\N	\N	0.00	\N
a5d6e72d-a58c-4e8a-8248-e376b4ac9d72	cmofl3ut6000hmjdmwqd3dziu	RAJESH PRATAP SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
ceedd50d-ef4e-453a-b654-766fb0f64533	cmofl3ut6000hmjdmwqd3dziu	Rajesh Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
45eb30e0-fca6-4845-8802-635a1b5b1a2d	cmofl3ut6000hmjdmwqd3dziu	RAJESH SRIVASTAVA	Sundry Debtors	\N	\N	0.00	Unregistered
527443ba-d7b1-45a6-8e45-848fb99d57c8	cmofl3ut6000hmjdmwqd3dziu	RAJESH YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
0fa0071c-a4ed-4564-abae-1a70f4d96aa4	cmofl3ut6000hmjdmwqd3dziu	RAJ GURU SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
20b6956b-5136-44de-86d5-bacaf69cc6de	cmofl3ut6000hmjdmwqd3dziu	Rajiv Jain U/L	Unsecured Loans	\N	\N	5077332.00	Unregistered
93020b60-d5c9-48e8-955c-72cff31a0e4c	cmofl3ut6000hmjdmwqd3dziu	RAJ KISHOR	Sundry Debtors	\N	\N	0.00	Unregistered
7e295306-72b0-4ec6-89e1-094b1a19407c	cmofl3ut6000hmjdmwqd3dziu	RAJ KISHOR SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
7637ecb3-e16d-491c-b189-bd9499593f9d	cmofl3ut6000hmjdmwqd3dziu	RAJ KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
f2fbb751-5049-4057-b137-3e9ed4618fb3	cmofl3ut6000hmjdmwqd3dziu	RAJ KUMAR DIWEDI	Sundry Debtors	\N	\N	0.00	Unregistered
7918b6f7-c859-4e96-8e65-6ee645a7ef52	cmofl3ut6000hmjdmwqd3dziu	Raj Kumari	Sundry Debtors	\N	\N	0.00	Unregistered
da6eb353-dae8-44c6-bdea-f07f06b160c3	cmofl3ut6000hmjdmwqd3dziu	RAJ KUMARR	Sundry Debtors	\N	\N	0.00	Unregistered
0554b953-3406-4cf8-aef4-040a152f7b7d	cmofl3ut6000hmjdmwqd3dziu	Raj Kumar Rajpoot	Sundry Debtors	\N	\N	0.00	Unregistered
3cada1c6-c655-482f-8311-1dd3ec4d600a	cmofl3ut6000hmjdmwqd3dziu	RAJ NANDINI ELECTRICALS	Sundry Debtors	09DMPPK9435R2ZR	\N	0.00	Regular
ee1a6256-09ea-466b-844e-b8f7d68de185	cmofl3ut6000hmjdmwqd3dziu	Rajnikant Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
946a0574-3ece-4d56-ab66-ec2d1cae8578	cmofl3ut6000hmjdmwqd3dziu	RAJPOOT ENTERPRISES	Sundry Debtors	09AIUPR8446H1ZB	\N	1005.00	Regular
c97ba4c4-992b-438d-81f7-625cef631eba	cmofl3ut6000hmjdmwqd3dziu	RAJ RADHE INFRATECH	Sundry Debtors	\N	\N	0.00	\N
7129cb1d-fcf1-4fab-b362-45af8834a509	cmofl3ut6000hmjdmwqd3dziu	RAJU SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
f056782c-90ad-4cab-8dbc-eb1431a20f56	cmofl3ut6000hmjdmwqd3dziu	RAJU SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
f7c69023-3d6e-44a9-a29f-12994c2a15d2	cmofl3ut6000hmjdmwqd3dziu	RAJU YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
3ff8d1e6-2134-482c-9fd6-9440ad42d582	cmofl3ut6000hmjdmwqd3dziu	RAJVEER SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
53418b42-3b50-4188-9c24-ed8078182006	cmofl3ut6000hmjdmwqd3dziu	Rakesh Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
0bd89170-7ab7-4520-834f-fb9f002c9e4e	cmofl3ut6000hmjdmwqd3dziu	Rakesh Kumar Contractor	Sundry Debtors	09AGCPK3941J3Z8	\N	0.00	Regular
8d38f391-d554-40fa-a5a9-d2290472be3e	cmofl3ut6000hmjdmwqd3dziu	RAKESH KUMAR GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
4f3f04b3-f6c2-4751-b71d-2df3e10c1e46	cmofl3ut6000hmjdmwqd3dziu	Rakesh Kumar Pal	Sundry Debtors	\N	\N	0.00	Unregistered
d454f53f-6890-4dcd-a0f6-69a4320e4c4d	cmofl3ut6000hmjdmwqd3dziu	RAKESH KUMAR TRIVEDI	Sundry Debtors	\N	\N	0.00	Unregistered
30776470-c944-4924-8f40-9038f2cc2d2d	cmofl3ut6000hmjdmwqd3dziu	Rakesh Kumar Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
0303b064-0432-4b94-86f4-f9d40e14fce7	cmofl3ut6000hmjdmwqd3dziu	Rakesh Singh	Sundry Debtors	\N	\N	0.00	\N
917d3911-ec2e-4e49-bc1f-e35f3137146a	cmofl3ut6000hmjdmwqd3dziu	RAKESH SINGH RATHOR	Sundry Debtors	\N	\N	0.00	Unregistered
ca4a663d-c037-4f26-b0eb-6b51df6045b2	cmofl3ut6000hmjdmwqd3dziu	Raksh Pal Singh	Sundry Debtors	\N	\N	0.00	Unregistered
48fbe82b-c7e8-4ec3-8dc1-ca6d00e515c1	cmofl3ut6000hmjdmwqd3dziu	Ram	Sundry Debtors	\N	\N	0.00	Unregistered
a63ae158-e3a0-4567-beaf-cd5b1a574996	cmofl3ut6000hmjdmwqd3dziu	RAMA DEVI	Sundry Debtors	\N	\N	0.00	Unregistered
4749f9f8-5131-4ee2-a677-f91b491914b1	cmofl3ut6000hmjdmwqd3dziu	RAM ADHAR	Sundry Debtors	\N	\N	0.00	Unregistered
816e8964-665d-46ef-95d7-4ed43b61368a	cmofl3ut6000hmjdmwqd3dziu	RAM ADHAR PRAJAPATI	Sundry Debtors	\N	\N	0.00	Unregistered
81cf837f-0fa9-47a8-9d1b-ab495c918057	cmofl3ut6000hmjdmwqd3dziu	Rama Pandey	Sundry Debtors	\N	\N	0.00	Unregistered
378d513e-82c7-492c-acb4-0c855fe1315c	cmofl3ut6000hmjdmwqd3dziu	Ramashanker	Sundry Debtors	\N	\N	0.00	Unregistered
bc63a980-ea1f-4c78-82ab-6565838dbc16	cmofl3ut6000hmjdmwqd3dziu	Ram Babu	Sundry Debtors	\N	\N	0.00	Unregistered
5df627aa-8378-40ac-a90a-7693dbba975b	cmofl3ut6000hmjdmwqd3dziu	Ram Babu Kamal	Sundry Debtors	\N	\N	0.00	Unregistered
6b09592e-d932-4d17-9bc8-3114d27a71a4	cmofl3ut6000hmjdmwqd3dziu	Ram Bahadur Ram	Sundry Debtors	\N	\N	0.00	Unregistered
c529c2ec-bceb-4a1d-be0a-4bc8a5b86db6	cmofl3ut6000hmjdmwqd3dziu	RAM BALI AND SONS	Sundry Debtors	\N	\N	0.00	\N
af94277e-d5bc-45b6-be5a-4c0d073f67dc	cmofl3ut6000hmjdmwqd3dziu	Ram Baran	Sundry Debtors	\N	\N	0.00	Unregistered
bf6dd0b6-bf5b-41e1-93ef-1ea8678a82d2	cmofl3ut6000hmjdmwqd3dziu	RAMCHNADRA DUBEY	Sundry Debtors	\N	\N	0.00	Unregistered
fd6a4f7b-50db-4cf6-a7ae-ab42021df68a	cmofl3ut6000hmjdmwqd3dziu	Ramendra	Sundry Debtors	\N	\N	0.00	\N
b543dbe1-7d7e-487b-8a53-4e0327db2721	cmofl3ut6000hmjdmwqd3dziu	Ramesh Chandra Arya	Sundry Debtors	\N	\N	0.00	Unregistered
5f3f971a-25cd-4d30-ad3f-1d9b7502dc30	cmofl3ut6000hmjdmwqd3dziu	Ramesh Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
628d576b-5846-437f-8525-63e7e6afee5e	cmofl3ut6000hmjdmwqd3dziu	RAMESH KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
3f4eb5b4-2f85-4b96-b910-6597975dcb83	cmofl3ut6000hmjdmwqd3dziu	Ramesh Singh	Sundry Debtors	\N	\N	0.00	Unregistered
89577a97-8210-4126-814d-1f0a12d1faf2	cmofl3ut6000hmjdmwqd3dziu	RAM JI GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
fc629093-4286-4074-bade-a4d517b617f6	cmofl3ut6000hmjdmwqd3dziu	RAM KARAN YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
c66090b1-c34d-4160-b52c-8cd331edb326	cmofl3ut6000hmjdmwqd3dziu	Ram Kishore	Sundry Debtors	\N	\N	0.00	Unregistered
e8276276-7865-44f0-bc92-c6747fee8cdc	cmofl3ut6000hmjdmwqd3dziu	Ram Kishor Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
1a3231b6-b06a-43a6-b19d-65d479d6cd7d	cmofl3ut6000hmjdmwqd3dziu	Ram Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
aa3ef03d-fc4d-4803-ad78-26e055d8fe8c	cmofl3ut6000hmjdmwqd3dziu	Ram Kumar Savita	Sundry Debtors	\N	\N	0.00	Unregistered
d0ec2b70-9006-49e6-ae9c-88e32e003fc8	cmofl3ut6000hmjdmwqd3dziu	Ram Kumar Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
f0b57dd5-f807-47ae-ba10-20b6ba6d41dd	cmofl3ut6000hmjdmwqd3dziu	Ram Kumar Singh	Sundry Debtors	\N	\N	0.00	Unregistered
a4c71f2c-1cf6-4db8-8dfb-c7f99947cb5f	cmofl3ut6000hmjdmwqd3dziu	Ramlakhan	Sundry Debtors	\N	\N	0.00	Unregistered
21b25d25-1fd2-431e-beec-75aa03841e26	cmofl3ut6000hmjdmwqd3dziu	Ram Manohar Tripathi	Sundry Debtors	\N	\N	0.00	Unregistered
159b4a12-5ac1-40e2-a60c-ff5f5e11c2df	cmofl3ut6000hmjdmwqd3dziu	RAM NARAYAN KABIR	Sundry Creditors	09AGRPJ9847P1Z3	\N	0.00	Regular
05683606-72d2-4fb2-a429-7c49e4983ba4	cmofl3ut6000hmjdmwqd3dziu	Ram Narayan Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
b5649577-1b86-4aad-8002-223bb9c358e6	cmofl3ut6000hmjdmwqd3dziu	Ram Naresh	Sundry Debtors	\N	\N	0.00	Unregistered
bb2eff2f-da6a-4c12-a1e8-8a522e8d808b	cmofl3ut6000hmjdmwqd3dziu	Ram Naresh Savita	Sundry Debtors	\N	\N	0.00	Unregistered
0d9e7606-20c8-452a-8b29-7e1e6ed7f45d	cmofl3ut6000hmjdmwqd3dziu	RAM PRAKASH	Sundry Debtors	\N	\N	0.00	Unregistered
50b01859-843a-4ad0-98e8-a2d750deb111	cmofl3ut6000hmjdmwqd3dziu	RAM PRAKASH KASHYAP	Sundry Debtors	\N	\N	0.00	Unregistered
4019e5e0-f13c-42a2-a275-11a09ca25c7b	cmofl3ut6000hmjdmwqd3dziu	RAM PRATAP SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
977c3ff2-9395-4273-8a37-50b16fcf7111	cmofl3ut6000hmjdmwqd3dziu	Ram Sagar	Sundry Debtors	\N	\N	0.00	Unregistered
6d6ac232-ee7e-4446-a315-18f86b00b235	cmofl3ut6000hmjdmwqd3dziu	RAM SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
cca9c53f-2fb6-44af-aa81-34be0c450f39	cmofl3ut6000hmjdmwqd3dziu	RAM SINGH PAL	Sundry Debtors	\N	\N	0.00	Unregistered
5a39e8c5-9c9c-4048-991d-8097a58494e0	cmofl3ut6000hmjdmwqd3dziu	Ramu Sai	Sundry Debtors	\N	\N	0.00	\N
fb336295-f3e6-4815-8767-a61fd74e7eb2	cmofl3ut6000hmjdmwqd3dziu	Rana Enterprises	Sundry Creditors for Transporter	\N	\N	0.00	\N
76ba53f4-5f7c-4ac1-902e-e84dfc713c7d	cmofl3ut6000hmjdmwqd3dziu	RANI DEVI	Sundry Debtors	\N	\N	0.00	Unregistered
129aa32f-8deb-45a5-af11-963944754174	cmofl3ut6000hmjdmwqd3dziu	Ranjana Dixit	Sundry Debtors	\N	\N	0.00	Unregistered
3e71eb7c-b6fd-4367-b485-7ce867cba0a8	cmofl3ut6000hmjdmwqd3dziu	Ranjit	Sundry Debtors	\N	\N	0.00	Unregistered
72540c4f-c02f-4237-8bdc-7017a29b306f	cmofl3ut6000hmjdmwqd3dziu	RANJNA VERMA	Sundry Debtors	09AJWPV2306D1ZW	\N	0.00	Regular
784a60ff-3af5-48a0-901d-0e1f150cd9a3	cmofl3ut6000hmjdmwqd3dziu	Ranveer	Sundry Debtors	\N	\N	0.00	Unregistered
89088147-e7cb-4486-8daf-17ee7e3d6de6	cmofl3ut6000hmjdmwqd3dziu	Ratan Chand Khatri S.V.M Inter College	Sundry Debtors	\N	\N	0.00	Unregistered
e19f7304-6d18-4adf-aab2-602f90ae716c	cmofl3ut6000hmjdmwqd3dziu	Rate Difference(Purchase)	Direct Expenses	\N	\N	0.00	\N
b087c859-b61a-4e66-8d7e-c3592c78fc6e	cmofl3ut6000hmjdmwqd3dziu	RAVI CONSTRUCTION COMPANY	Sundry Debtors	09ASQPS2223M1Z4	\N	0.00	Regular
b53631fd-5063-463e-87a2-e2c13d75991c	cmofl3ut6000hmjdmwqd3dziu	RAVI GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
2cf2d25f-c919-49d8-b6fd-2de4b0935d8e	cmofl3ut6000hmjdmwqd3dziu	Ravii Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
dd3375f1-e324-414a-beb7-586f0ac9736e	cmofl3ut6000hmjdmwqd3dziu	Ravikant	Sundry Debtors	\N	\N	0.00	Unregistered
e21f601d-fb6d-4fef-b3c3-515b8d29d14c	cmofl3ut6000hmjdmwqd3dziu	Ravi Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
3cf77e2d-31ee-4334-a4af-b8a9c0784cba	cmofl3ut6000hmjdmwqd3dziu	RAVINDA KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
25e50ee1-2101-401e-89ce-ea9146ea4f4e	cmofl3ut6000hmjdmwqd3dziu	RAVINDRA SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
a43b3fa4-6b99-48b4-8d8d-256eb4150ca9	cmofl3ut6000hmjdmwqd3dziu	RAVI SANKER DIXIT DEVELOPERS	Sundry Debtors	09ADSPD2908F1ZJ	\N	-71357.00	Regular
c7b45db2-6114-4cf0-808e-600632614af0	cmofl3ut6000hmjdmwqd3dziu	Ravi Shanker Gautam	Sundry Debtors	\N	\N	0.00	Unregistered
ea5c29c4-0220-4b60-9f10-978274711ec7	cmofl3ut6000hmjdmwqd3dziu	Ravi Shanker Gowam	Sundry Debtors	\N	\N	0.00	Unregistered
c3726e43-0a31-4e80-9fcb-ec369b2da3d6	cmofl3ut6000hmjdmwqd3dziu	RAVI SHANKER SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
e3d2b326-a1ef-4c86-a8a0-a7b926221acb	cmofl3ut6000hmjdmwqd3dziu	RAVI SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
c478d640-8666-4b07-8460-d0feb0537541	cmofl3ut6000hmjdmwqd3dziu	Ravi Singh	Sundry Debtors	\N	\N	0.00	Unregistered
95bf14c6-5d3c-4e07-a6c1-9c1f008a0040	cmofl3ut6000hmjdmwqd3dziu	RAVI VERMA	Sundry Debtors	\N	\N	0.00	Unregistered
dfbccf22-d990-4975-a540-867f23bdb2ab	cmofl3ut6000hmjdmwqd3dziu	RCCPL PVT LTD	Deposits (Asset)	\N	\N	0.00	Unregistered
23b06df9-a5d6-4663-90a1-253ed71cf056	cmofl3ut6000hmjdmwqd3dziu	R.C. FOOD PRODUCTS	Sundry Debtors	\N	\N	0.00	Unregistered
43c90865-8394-45f1-a635-431ec55b1e91	cmofl3ut6000hmjdmwqd3dziu	R&amp;C INFRAENGINEERS PRIVATE LIMITED	Sundry Debtors	09AAGCR4846L1ZS	\N	0.00	Regular
558d337a-e227-43eb-9cf2-c6cbb356b776	cmofl3ut6000hmjdmwqd3dziu	R C M  ON  LOCAL FREIGHT	Provisions	\N	\N	0.00	\N
74ff02bc-3d47-4864-8561-35a4c8853fc5	cmofl3ut6000hmjdmwqd3dziu	RCM PAYABLE	Provisions	\N	\N	0.00	\N
fb126e6e-14e6-4ea8-bfc6-3d8e5b60f478	cmofl3ut6000hmjdmwqd3dziu	Rebate and Discount	Indirect Incomes	\N	\N	0.00	\N
d30eddb6-3bb9-4f48-a3b4-abceade4e8fa	cmofl3ut6000hmjdmwqd3dziu	Reema Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
d2455e06-5c14-43e4-a907-f6398b2b4ef6	cmofl3ut6000hmjdmwqd3dziu	Rekha Aghinotri	Sundry Debtors	\N	\N	0.00	Unregistered
9b14ebdb-ee38-4e47-8f7b-8147abb7e282	cmofl3ut6000hmjdmwqd3dziu	RELIANCE	Investments	\N	\N	-120000.00	\N
cdce660b-5e1b-409f-9868-35c4db01db80	cmofl3ut6000hmjdmwqd3dziu	Reliance Cement Co. Pvt Ltd	Sundry Debtors	\N	\N	0.00	Regular
c6f9b12f-ed57-47c1-9b80-e09abc8ec729	cmofl3ut6000hmjdmwqd3dziu	Renewal Fees(Tally)	Indirect Expenses	\N	\N	0.00	\N
39863c84-fe99-479b-8425-9886f6452b68	cmofl3ut6000hmjdmwqd3dziu	RENU DEVI	Sundry Debtors	\N	\N	0.00	Unregistered
952395c5-c815-4ff7-87ad-27047427d5f5	cmofl3ut6000hmjdmwqd3dziu	REPAIR AND MAINTINANCE	Indirect Expenses	\N	\N	0.00	\N
fd54052e-86b6-4937-8792-e2314e40b27a	cmofl3ut6000hmjdmwqd3dziu	Repair and Maintinance Gst	Indirect Expenses	\N	\N	0.00	\N
701eb428-9ef7-4b90-97ab-cdc843b8d734	cmofl3ut6000hmjdmwqd3dziu	Repair &amp;Maintenance 18 %	Indirect Expenses	\N	\N	0.00	\N
09aca816-b602-458a-afae-3a45b3a728f1	cmofl3ut6000hmjdmwqd3dziu	RICHA ENTERPRISES	Sundry Debtors	\N	\N	0.00	Regular
23223dd4-b12a-4c45-8ccf-e4a354325590	cmofl3ut6000hmjdmwqd3dziu	RICHESH  SALES CORPORATION	Sundry Creditors	09ACZPG3832B1ZI	\N	0.00	Regular
aeab8935-0442-412e-8b50-99392ab58595	cmofl3ut6000hmjdmwqd3dziu	Riddhi Siddhi Industries	Sundry Debtors	09ABGFR9166F1ZQ	\N	0.00	Regular
b989217c-3caf-4302-be53-c4cbe57b370c	cmofl3ut6000hmjdmwqd3dziu	Ridhi Sidhi Company	Sundry Debtors	09FPWPK1139A1ZR	\N	0.00	Regular
7cfbd4d7-3e18-4d1c-8ed1-3c1662032d54	cmofl3ut6000hmjdmwqd3dziu	Rishab Sonker 2	Sundry Debtors	\N	\N	0.00	Unregistered
1e92d8e9-d975-4d33-906d-127c28c4de27	cmofl3ut6000hmjdmwqd3dziu	Rishi Kant Shukla	Sundry Debtors	\N	\N	0.00	Unregistered
fd679211-75b2-4a80-89e8-0677221b841f	cmofl3ut6000hmjdmwqd3dziu	RISHI PANDEY	Sundry Debtors	\N	\N	0.00	Unregistered
24933264-c3b5-4efb-af2f-8813d3863d74	cmofl3ut6000hmjdmwqd3dziu	RITA DHUPAR	Sundry Debtors	\N	\N	0.00	Unregistered
0db9cdb3-8d6d-47df-933a-b60de504bc63	cmofl3ut6000hmjdmwqd3dziu	RITESH BHATACHARYA	Sundry Debtors	\N	\N	0.00	Unregistered
9a1c4714-66e9-4f41-adbd-da837c9628ec	cmofl3ut6000hmjdmwqd3dziu	Ritesh Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
c52e7a4a-ea08-491e-976a-8b9b5add64cb	cmofl3ut6000hmjdmwqd3dziu	RITHINK DESIGN AND CONSTRUCTION	Sundry Debtors	\N	\N	0.00	\N
5e6b07de-9899-416e-aac1-5b215c8f52c3	cmofl3ut6000hmjdmwqd3dziu	Ritik Roadways	Sundry Creditors for Transporter	\N	\N	0.00	\N
9e7483e5-c381-4138-989b-baa608251db8	cmofl3ut6000hmjdmwqd3dziu	R.K. GOLDEN TRANSPORT COMPANY	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
1bea34fa-b6ff-4533-9019-6ef21411f6c7	cmofl3ut6000hmjdmwqd3dziu	R K H Ispat	Sundry Debtors	09AARPG1759R1ZR	\N	0.00	Regular
15632e7e-0d44-403f-839a-dd6055220b3f	cmofl3ut6000hmjdmwqd3dziu	R.K. YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
0ee71303-3f9d-4ee0-b394-0f3ed6e1a20e	cmofl3ut6000hmjdmwqd3dziu	RNK ENTERPRISES	Sundry Debtors	\N	\N	-39528.00	\N
1a265665-b97a-4e6b-9d8d-cc6cb0f0eae7	cmofl3ut6000hmjdmwqd3dziu	Rochak Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
36744df0-5fd4-4b5a-b5a6-7d718f5fa8ec	cmofl3ut6000hmjdmwqd3dziu	Rohit	Sundry Debtors	\N	\N	0.00	Unregistered
d54fa13d-132c-4102-ac3c-8966262c59c3	cmofl3ut6000hmjdmwqd3dziu	ROHIT CONSTRUCTION AND TRADERS	Sundry Debtors	09DQDPS1002Q2ZI	\N	0.00	Regular
e5d78fbe-62de-431c-b508-7a2d7b324882	cmofl3ut6000hmjdmwqd3dziu	ROHIT KATIYA	Sundry Debtors	\N	\N	0.00	Unregistered
908ab3da-7dcf-4c34-b756-9deba3cba95e	cmofl3ut6000hmjdmwqd3dziu	ROHIT Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
c4f3a47b-3b9a-4810-acf6-a875b80a8725	cmofl3ut6000hmjdmwqd3dziu	ROHIT KUMAR DIWEDI	Sundry Debtors	\N	\N	0.00	Unregistered
432c319d-aff5-4ff9-9c16-79c5bf9730ee	cmofl3ut6000hmjdmwqd3dziu	ROOP NARAYIN GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
fb7522a9-9737-43b1-8edf-9313982c152c	cmofl3ut6000hmjdmwqd3dziu	ROUNDED OFF	Indirect Expenses	\N	\N	0.00	\N
fde64156-99be-4af5-8389-954830838742	cmofl3ut6000hmjdmwqd3dziu	ROYAL TRADERS	Sundry Debtors	09ACTPI2971H1Z4	\N	0.00	Regular
222ecf21-25f7-4f3c-a8cf-d7a042f06e2a	cmofl3ut6000hmjdmwqd3dziu	R.P. CONSTRUCTION	Sundry Debtors	09AAPFR3487F1ZN	\N	0.00	Regular
ae3a7cf1-91d3-4ae9-bb37-31a7623030e9	cmofl3ut6000hmjdmwqd3dziu	R P Traders	Sundry Creditors	\N	\N	0.00	\N
cb3e3da8-d69e-4e9f-b20a-07296476989d	cmofl3ut6000hmjdmwqd3dziu	R.P. Trading Company	Sundry Creditors	09AALPA9779M1ZT	\N	0.00	Regular
ebed7738-8536-41c0-aed7-b9ca044db486	cmofl3ut6000hmjdmwqd3dziu	RSP METALIKS PVT LTD	Sundry Creditors	20AAGCR2942D1ZW	\N	0.00	Regular
525d509d-36c5-4bda-9684-5d0b19a1e065	cmofl3ut6000hmjdmwqd3dziu	Ruchi	Sundry Debtors	\N	\N	0.00	\N
a13ccd08-dea2-4a83-9353-a38d863c73f6	cmofl3ut6000hmjdmwqd3dziu	RUCHI TRADING COMPANY	Sundry Creditors	09AFAPB7536F1ZP	\N	0.00	Regular
437e4ddf-75a0-4d63-ad57-a4d3f7abd0b1	cmofl3ut6000hmjdmwqd3dziu	RUCHI  TRADING CORPORATION	Sundry Debtors	\N	\N	0.00	Regular
19b359fb-f66f-40a0-8fe2-8c16ecbd49ee	cmofl3ut6000hmjdmwqd3dziu	Rudrani Infra Solutions Pvt. Ltd	Sundry Debtors	09AAHCR4756Q1ZG	\N	0.00	Regular
5dee3162-33e5-4ed8-9135-a533dcea526b	cmofl3ut6000hmjdmwqd3dziu	Rupal	Sundry Debtors	\N	\N	0.00	\N
96b4bcf1-ebdb-48c0-bada-83c7524960c2	cmofl3ut6000hmjdmwqd3dziu	RUPESH KUMAR	Sundry Debtors	\N	\N	0.00	\N
e9abe4a0-ff31-4d34-85d3-3303c4a72cfb	cmofl3ut6000hmjdmwqd3dziu	SAAHAS INFRABUILD	Sundry Debtors	09AFHFS3453D1ZY	\N	0.00	Regular
e50e48f9-8a41-4cbb-aa01-1b47a106aa7b	cmofl3ut6000hmjdmwqd3dziu	Saahas Infratech	Sundry Debtors	09AENFS9484B1ZF	\N	0.00	Regular
bc1d9e44-a62c-4f04-96f6-72698a58a90b	cmofl3ut6000hmjdmwqd3dziu	Saanjay	Sundry Debtors	\N	\N	0.00	Unregistered
82a6d378-0db7-4158-b118-c29e86418efa	cmofl3ut6000hmjdmwqd3dziu	SACHENDRA SINGH CHAUHAN	Sundry Debtors	09AAKPC1504B1ZG	\N	0.00	Regular
b70b364b-4815-4e24-a79f-ca3bb2d65b6e	cmofl3ut6000hmjdmwqd3dziu	Sachin Singh	Sundry Debtors	\N	\N	0.00	Unregistered
46085674-de52-443f-9012-ba2523f2bb6c	cmofl3ut6000hmjdmwqd3dziu	Sachin Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
cda99a59-c2d0-4245-87c1-4f79744138a3	cmofl3ut6000hmjdmwqd3dziu	SADAB TRADERS	Sundry Debtors	\N	\N	0.00	Regular
04654830-cb3c-42f7-9c59-bb064f20fed2	cmofl3ut6000hmjdmwqd3dziu	Sahnis Constructions LLP	Sundry Debtors	09ADUFS3189D1ZG	\N	0.00	Regular
8bd83391-af20-45c0-9860-a6b896f472c3	cmofl3ut6000hmjdmwqd3dziu	SAINIK TRADERS	Sundry Debtors	09BEIPS4065Q1ZK	\N	0.00	Regular
f5e82cc5-2066-45f6-b55e-d6e7c8dc4724	cmofl3ut6000hmjdmwqd3dziu	SAI RAM ENTERPRISES	Sundry Debtors	09AKVPY0392G1ZC	\N	0.00	Regular
b97987b6-2f44-49da-91bd-0f0bec8ffae0	cmofl3ut6000hmjdmwqd3dziu	Salary	Indirect Expenses	\N	\N	0.00	\N
747f971f-ea58-426e-bd6a-492488dc71d8	cmofl3ut6000hmjdmwqd3dziu	Salary-Abhijeet  Jain	Current Liabilities	\N	\N	-20000.00	Unregistered
04677173-ee8b-4358-8f04-61c3fef7c64a	cmofl3ut6000hmjdmwqd3dziu	SALARY-ANIL KUMAR AGARWAL	Current Liabilities	\N	\N	0.00	Regular
7f9d8efb-7902-4fdf-9aee-648687467f75	cmofl3ut6000hmjdmwqd3dziu	SALARY- VIKRANT	Current Liabilities	\N	\N	0.00	Unregistered
22acbcbd-dcd2-43fd-a0fd-cdf06baf1fb1	cmofl3ut6000hmjdmwqd3dziu	SALES GST 28%	Sales Accounts	\N	\N	0.00	\N
9c81991a-7825-473d-9c72-1dc714a77bae	cmofl3ut6000hmjdmwqd3dziu	SALES GST LOCAL @ 18%	Sales Accounts	\N	\N	0.00	\N
8b983d0b-9d8f-4f28-a91a-3026f5e6114a	cmofl3ut6000hmjdmwqd3dziu	SALES IGST	Sales Accounts	\N	\N	0.00	\N
b4f53842-5f2f-4db9-a180-c6f40abd7634	cmofl3ut6000hmjdmwqd3dziu	Samar	Sundry Debtors	\N	\N	0.00	\N
eaf8f5fd-2ec7-43bf-80a1-34c15cf52dc6	cmofl3ut6000hmjdmwqd3dziu	SAMARPAN STEELS AND COMPANY	Sundry Debtors	09AECPG5861P1ZZ	\N	0.00	Regular
b471c5be-6cdf-4a4b-9e23-04f4eaf835fb	cmofl3ut6000hmjdmwqd3dziu	Sameer Kumar Katiyar	Sundry Debtors	\N	\N	0.00	Unregistered
4fd8bbe7-b7c6-4a4f-afc8-b03354aa8168	cmofl3ut6000hmjdmwqd3dziu	SAMEER PANDEY	Sundry Debtors	\N	\N	0.00	Unregistered
ab1f41f2-3867-49d7-9033-c3e20a46aa0f	cmofl3ut6000hmjdmwqd3dziu	SAMRIDHI STEELS AND CEMENT	Sundry Creditors	09AGSPA3722F1ZI	\N	0.00	Regular
66304dc7-5439-4982-bef2-e1e0d3c37912	cmofl3ut6000hmjdmwqd3dziu	SAMSUL HAQUE	Sundry Debtors	\N	\N	0.00	Unregistered
bda49466-42ec-4e48-b4ec-2f819c38edbc	cmofl3ut6000hmjdmwqd3dziu	Sandeep Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
267ef59f-f3fd-4078-8fba-f5f535f95116	cmofl3ut6000hmjdmwqd3dziu	SANDEEP KUMAR MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
27b8071b-bfa8-431d-a904-1338f5a81183	cmofl3ut6000hmjdmwqd3dziu	Sandeep Kushwaha	Sundry Debtors	\N	\N	0.00	Unregistered
5ec41c7a-528f-439e-9479-60e059fb49d5	cmofl3ut6000hmjdmwqd3dziu	SANDEEP SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
6c650517-a377-4b24-bc2e-00cfa7c58450	cmofl3ut6000hmjdmwqd3dziu	SANDHYA	Sundry Debtors	\N	\N	0.00	Unregistered
ab3fe7dc-befd-4184-a757-f55295ca7089	cmofl3ut6000hmjdmwqd3dziu	Sangeeta Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
692119ed-34a1-4047-ad96-b4fe34aafdcf	cmofl3ut6000hmjdmwqd3dziu	Sanjay	Sundry Debtors	\N	\N	0.00	Unregistered
a065bcd5-f702-4ce3-8992-33576346f509	cmofl3ut6000hmjdmwqd3dziu	Sanjay Kirti	Sundry Debtors	\N	\N	0.00	Unregistered
f62198ec-c6c2-4fd3-9610-364f3defd6e0	cmofl3ut6000hmjdmwqd3dziu	Sanjay Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
559d613c-9ef6-4943-ba03-abedfa5da4b9	cmofl3ut6000hmjdmwqd3dziu	Sanjay Kumar Tiwari	Sundry Debtors	\N	\N	0.00	Unregistered
883d6205-11b8-4094-a76d-f9e8d93a5f59	cmofl3ut6000hmjdmwqd3dziu	Sanjay Pal	Sundry Debtors	\N	\N	0.00	Unregistered
fb890de8-c30a-4115-839e-ff8c90c8c546	cmofl3ut6000hmjdmwqd3dziu	Sanjay Singh	Sundry Debtors	\N	\N	0.00	Unregistered
14364ebf-ba4b-4e79-abd8-5db6cec8eb5f	cmofl3ut6000hmjdmwqd3dziu	SANJAY SRIVASTAVA	Sundry Debtors	\N	\N	0.00	Unregistered
81b7553d-4ba1-4021-947b-01c87997fc29	cmofl3ut6000hmjdmwqd3dziu	SANJAY VYAS	Sundry Debtors	\N	\N	0.00	Unregistered
cce8fb87-5e1e-4c36-acb8-d302b4074757	cmofl3ut6000hmjdmwqd3dziu	SANJEEV KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
f4947e62-2c82-434c-b4d1-85c038d5ea0d	cmofl3ut6000hmjdmwqd3dziu	Sanjeev Sengar	Sundry Debtors	\N	\N	0.00	\N
600f694a-99e5-4f88-b99b-6ad3a8063b4c	cmofl3ut6000hmjdmwqd3dziu	Santoshi	Sundry Debtors	\N	\N	0.00	Unregistered
a3dbbc12-42e0-42a7-af42-24f7c37e9ace	cmofl3ut6000hmjdmwqd3dziu	Santoshi Kumari	Sundry Debtors	\N	\N	0.00	Unregistered
eed0c447-6eeb-4b62-be00-bff73e919e24	cmofl3ut6000hmjdmwqd3dziu	SANTOSHI  SHAKYA	Sundry Debtors	\N	\N	0.00	Unregistered
681f44dc-27c4-469a-a623-c5545cd6720e	cmofl3ut6000hmjdmwqd3dziu	SANTOSHI SJAKYA	Sundry Debtors	\N	\N	0.00	Unregistered
a8ce6833-04c8-4a45-9b88-865068cfdd16	cmofl3ut6000hmjdmwqd3dziu	SANTOSH KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
a33bf163-c84d-4272-86b0-c76086706531	cmofl3ut6000hmjdmwqd3dziu	SANTOSH KUMAR AGNIHOTRI	Sundry Debtors	\N	\N	0.00	Unregistered
c98f5b72-2059-428b-b7aa-824adffc3d92	cmofl3ut6000hmjdmwqd3dziu	SANTOSH SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
fc8b073d-1271-47c6-8c80-8c23266922ff	cmofl3ut6000hmjdmwqd3dziu	SANTOSH SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
c14fda57-1697-459f-af15-9483f4a18a12	cmofl3ut6000hmjdmwqd3dziu	Santram Maurya	Sundry Debtors	\N	\N	0.00	\N
fb67b553-c644-4d8c-9c92-037584f14fd2	cmofl3ut6000hmjdmwqd3dziu	SARAF COOLING CORPORATION	Sundry Creditors	09AACCS6308Q1ZS	\N	0.00	Regular
928cba31-a03d-4c1b-843a-438fa317e4af	cmofl3ut6000hmjdmwqd3dziu	Sarashwati  Transport	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
44344e95-fc36-482e-9ded-3a27f46af8ff	cmofl3ut6000hmjdmwqd3dziu	SARDAR SINGH &amp; COMPANY	Sundry Debtors	09DLBPS7150E1ZZ	\N	0.00	Regular
48984d8c-a2d2-4e5d-97bd-1b6e42f6cb08	cmofl3ut6000hmjdmwqd3dziu	Sarita Pal	Sundry Debtors	\N	\N	0.00	Unregistered
7e84d3e6-3b40-4e5a-b105-5343d80db766	cmofl3ut6000hmjdmwqd3dziu	SARVAN KUMAR DIVIDI	Sundry Debtors	\N	\N	0.00	Unregistered
6240ffa2-f38a-427a-82f7-6755f3f6332d	cmofl3ut6000hmjdmwqd3dziu	SARVAN KUMAR SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
1638d242-68a9-4beb-acb1-92b05c35d778	cmofl3ut6000hmjdmwqd3dziu	SARVESH GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
cbfaeed9-728d-4fac-b979-a7533e100bb6	cmofl3ut6000hmjdmwqd3dziu	Sarveshh	Sundry Debtors	\N	\N	0.00	Unregistered
a401cdfd-bc13-4106-8c03-2c2560826d7d	cmofl3ut6000hmjdmwqd3dziu	Sarvesh Kumar Pal	Sundry Debtors	\N	\N	0.00	Unregistered
b82c7cd9-8e92-4326-9d74-65d626506843	cmofl3ut6000hmjdmwqd3dziu	SARVESH KUMAR YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
4b0a732f-0237-4904-b166-5a6501fe44b5	cmofl3ut6000hmjdmwqd3dziu	SATENDRA KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
c9ab5d06-6791-49a3-9332-3e003433296b	cmofl3ut6000hmjdmwqd3dziu	SATENDRA  Kumar Shukla	Sundry Debtors	\N	\N	0.00	Unregistered
d28e1d13-30f3-416f-8c4a-d800e800ac9c	cmofl3ut6000hmjdmwqd3dziu	Satendra Pal	Sundry Debtors	\N	\N	0.00	Unregistered
419f6aab-e677-492f-8d74-62bf15244d88	cmofl3ut6000hmjdmwqd3dziu	SATENDRA SHARMA F/O AMAN SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
a06ef793-5ac1-4ece-8161-cfa2775bd70a	cmofl3ut6000hmjdmwqd3dziu	Satendra Singh Kushwaha	Sundry Debtors	\N	\N	0.00	Unregistered
ac8f35e7-91d4-4066-bc82-1324e340b78f	cmofl3ut6000hmjdmwqd3dziu	SATISH CHANDRA  SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
9788c0e4-5faa-40bd-9294-0eeb5559d942	cmofl3ut6000hmjdmwqd3dziu	SATISH KUMAR AWASTHI	Sundry Debtors	09AGAPA4575A1ZX	\N	0.00	Regular
96b20954-5c0d-473c-9961-6b174fe36c71	cmofl3ut6000hmjdmwqd3dziu	Satish Pal	Sundry Debtors	\N	\N	0.00	Unregistered
3385e8d9-1a78-4298-8fc3-935982d008d0	cmofl3ut6000hmjdmwqd3dziu	Satish Singh	Sundry Debtors	\N	\N	0.00	Unregistered
ab8bd452-d5a9-44b8-b45a-b2f46dd8ade6	cmofl3ut6000hmjdmwqd3dziu	Satna Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
4e05f891-9684-48e9-badd-f4e72cbb98d6	cmofl3ut6000hmjdmwqd3dziu	Satyabhan Singh Rathore	Sundry Debtors	\N	\N	0.00	Unregistered
5b1e99ee-2248-4039-9710-278628c756a0	cmofl3ut6000hmjdmwqd3dziu	SATYA ENGINEERING	Sundry Debtors	\N	\N	0.00	Regular
985835da-caec-4ed7-bb0f-000037eb4a13	cmofl3ut6000hmjdmwqd3dziu	SATYA GENERATOR SERVICE	Sundry Debtors	09CJEPS9850B2ZV	\N	0.00	Regular
335caee9-2ff4-4c02-9418-287e1706709c	cmofl3ut6000hmjdmwqd3dziu	SATYAKALA MANDAP	Sundry Debtors	09DUIPD8307L1Z9	\N	0.00	Regular
23f244c8-d745-4676-9825-fad80fd99a44	cmofl3ut6000hmjdmwqd3dziu	Satyam Chauhan	Sundry Debtors	\N	\N	0.00	\N
58626d0e-b392-4601-822e-526502b69219	cmofl3ut6000hmjdmwqd3dziu	Satyam Kumar Shukla	Sundry Debtors	\N	\N	0.00	Unregistered
424d33e4-bc27-4fdc-93d7-2fedb9685a2b	cmofl3ut6000hmjdmwqd3dziu	Satyan Narain	Sundry Debtors	\N	\N	0.00	Unregistered
f9239423-ce4a-4ebc-8232-b87d8dc226e0	cmofl3ut6000hmjdmwqd3dziu	Satyaom	Sundry Debtors	\N	\N	0.00	Unregistered
1c453400-6f5f-42e6-bcfa-389bd8e00eef	cmofl3ut6000hmjdmwqd3dziu	Satyendr	Sundry Debtors	\N	\N	0.00	\N
d81f3600-f86d-4726-bef0-0976464e2dc5	cmofl3ut6000hmjdmwqd3dziu	Saumya  Enterprises	Sundry Debtors	09AYNPA2203J1ZN	\N	0.00	Regular
09729337-0be1-4465-8892-3aee65b41ae6	cmofl3ut6000hmjdmwqd3dziu	Saurabh Kunwar Chandel	Sundry Debtors	\N	\N	0.00	Unregistered
0d0fdbea-e7fa-4cce-9061-8488dc55a2fc	cmofl3ut6000hmjdmwqd3dziu	Saurabh Shukla	Sundry Debtors	\N	\N	0.00	Unregistered
1b8d7636-e64f-4430-8ed1-d207d4d40f4e	cmofl3ut6000hmjdmwqd3dziu	Saurabh Singh	Sundry Debtors	\N	\N	0.00	Unregistered
6d3cee5a-6823-4582-a555-6e0029cadb37	cmofl3ut6000hmjdmwqd3dziu	Saurav Porwal	Sundry Debtors	\N	\N	0.00	\N
2bf0a821-04f7-44d2-82a4-5decc6ec898d	cmofl3ut6000hmjdmwqd3dziu	SBI PPF	Investments	\N	\N	0.00	\N
78a6f739-ea72-4434-92c3-4163ef6799fe	cmofl3ut6000hmjdmwqd3dziu	Scooty	Fixed Assets	\N	\N	-18532.55	\N
aebe8dfb-56bf-483e-9ace-b4531896a118	cmofl3ut6000hmjdmwqd3dziu	SECURITY AND PENALTY GST A/C	Deposits (Asset)	\N	\N	0.00	Unregistered
4bb5e3ab-ffc8-43e8-80a4-a81a4e3f3b56	cmofl3ut6000hmjdmwqd3dziu	Seema Verma	Sundry Debtors	\N	\N	0.00	Unregistered
da302335-4a35-466b-9959-cb927c77a43d	cmofl3ut6000hmjdmwqd3dziu	SERVESHARI ENTERPRISES	Sundry Debtors	09BQBPK7468L1ZN	\N	0.00	Regular
b56f7808-a4d2-44af-8656-c453f512a030	cmofl3ut6000hmjdmwqd3dziu	SETHI SALES	Sundry Creditors	09AUOPS0500R1Z0	\N	0.00	Regular
bad44f96-53f2-45ce-98e4-158b921ff7ed	cmofl3ut6000hmjdmwqd3dziu	SETHI TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
f0c74608-7d8c-4ad9-8b28-34f64272bdd8	cmofl3ut6000hmjdmwqd3dziu	Sethpal Construction Company	Sundry Debtors	09AFQPC6005C2ZR	\N	-246653.00	Regular
168e1bb0-f636-4ec4-a232-a4097d2a0e8e	cmofl3ut6000hmjdmwqd3dziu	SGST	Duties & Taxes	\N	\N	0.00	\N
a17eda38-dd61-4007-98eb-8771351f44a2	cmofl3ut6000hmjdmwqd3dziu	Sgst Cash Ledger	Duties & Taxes	\N	\N	0.00	\N
0070fee2-1531-498d-bbee-9a5e95a8c988	cmofl3ut6000hmjdmwqd3dziu	SGST EXCESS CLAIMED	Duties & Taxes	\N	\N	0.00	\N
b7294017-185d-4d1a-a458-8b1d6f3171f4	cmofl3ut6000hmjdmwqd3dziu	SGSTINWARD @14%	Duties & Taxes	\N	\N	0.00	\N
56ca8a3c-2695-4d4c-99d5-f89064cfc96f	cmofl3ut6000hmjdmwqd3dziu	SGSTINWARD @9%	Duties & Taxes	\N	\N	0.00	\N
12edf3e5-c635-4d14-bb05-2076bb1ba5fc	cmofl3ut6000hmjdmwqd3dziu	SGST OUT WARD @14%	Duties & Taxes	\N	\N	0.00	\N
22047423-e7e2-40c9-8564-b1f009ef6a3b	cmofl3ut6000hmjdmwqd3dziu	SGST OUTWARD @ 9%	Duties & Taxes	\N	\N	0.00	\N
b8be86bb-7a59-4546-8df3-812f04415ddb	cmofl3ut6000hmjdmwqd3dziu	SGST PAID T Over TaX	Duties & Taxes	\N	\N	0.00	\N
95f57fdc-f2ba-4d18-9194-13f942cc2d62	cmofl3ut6000hmjdmwqd3dziu	Sgst Payable	Provisions	\N	\N	0.00	\N
b02e4cb2-434f-42c2-aa9a-39a2095fa7b6	cmofl3ut6000hmjdmwqd3dziu	SGST PB	Duties & Taxes	\N	\N	0.00	\N
a93ed2ac-353e-437e-9501-e055c00ba662	cmofl3ut6000hmjdmwqd3dziu	SGST RCM	Duties & Taxes	\N	\N	0.00	\N
a4cd694c-f2fc-4b55-b806-ead3012f2ae1	cmofl3ut6000hmjdmwqd3dziu	SGST RCM PAYBLE	Provisions	\N	\N	0.00	\N
7d7efec6-0742-40bf-a8c9-3dc07147633a	cmofl3ut6000hmjdmwqd3dziu	SGST TO BE CLAIMED	Duties & Taxes	\N	\N	0.00	\N
55376352-c868-4b78-922d-2757c141f8e0	cmofl3ut6000hmjdmwqd3dziu	Shadab Traders	Sundry Debtors	\N	\N	0.00	Unregistered
a3408a88-cc16-4dd2-965c-39dbf815d1f9	cmofl3ut6000hmjdmwqd3dziu	SHAHJAD KURAISHREE	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
9697d4fa-9367-48e6-a83e-76a1c312f9d2	cmofl3ut6000hmjdmwqd3dziu	SHAILENDRA KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
b826d661-db09-4a84-841f-5f8866ca8778	cmofl3ut6000hmjdmwqd3dziu	SHAMA TRADERS	Sundry Debtors	09ADGPI2875L1Z3	\N	0.00	Regular
f34e1b26-92d2-4e43-b468-3fe50a0d79db	cmofl3ut6000hmjdmwqd3dziu	Shankar Lal	Sundry Debtors	\N	\N	0.00	Unregistered
9c568ff5-8433-4f9f-b82e-362f77d0605c	cmofl3ut6000hmjdmwqd3dziu	Shankatha Prasad	Sundry Debtors	\N	\N	0.00	Unregistered
fedfaca8-448f-4f64-9892-a1a51c5c0a81	cmofl3ut6000hmjdmwqd3dziu	SHANTI  GUPTA W/O LATE R K GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
7328a35a-b258-4b2b-8032-65596be7bcf1	cmofl3ut6000hmjdmwqd3dziu	Shanti Shukal and Anil Kumar Shukla	Sundry Debtors	\N	\N	0.00	Unregistered
db3ca84d-3cb3-4426-bcf1-a8c49bb5c701	cmofl3ut6000hmjdmwqd3dziu	SHANVI ENTERPRISES	Sundry Debtors	09DFMPA1298J1Z3	\N	0.00	Regular
f48076de-bdc0-4857-b671-fccddd4c10d8	cmofl3ut6000hmjdmwqd3dziu	SHARAD BRUSHES PRIVATE LIMITED	Sundry Debtors	09AAMCS1006K1Z9	\N	0.00	Regular
a1555036-ba72-4099-a9c4-226cf5a00477	cmofl3ut6000hmjdmwqd3dziu	Sharad Pratap Singh	Sundry Debtors	\N	\N	0.00	Unregistered
6024dd8e-f786-40a0-879b-c2dfe6638e2a	cmofl3ut6000hmjdmwqd3dziu	Sharad Singh Chauhan	Sundry Debtors	\N	\N	0.00	\N
61203bee-ce94-411b-aaf0-b129551fa680	cmofl3ut6000hmjdmwqd3dziu	SHARDA ENTERPRISES	Sundry Debtors	09DFFPM0238P1Z0	\N	0.00	Regular
b28c72a1-d5b3-4d91-b83d-75a8c3658b9f	cmofl3ut6000hmjdmwqd3dziu	SHARDA TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
33a8a516-e0e5-4d8b-a913-50c36ddd1971	cmofl3ut6000hmjdmwqd3dziu	SHARES	Investments	\N	\N	-165734.54	\N
9424cc04-d986-4afb-9f7d-0f8756e8ffd5	cmofl3ut6000hmjdmwqd3dziu	Shashi	Sundry Debtors	\N	\N	0.00	Unregistered
2f0dc0a8-849e-4b3d-bedd-a58db22d4ca4	cmofl3ut6000hmjdmwqd3dziu	SHASHI KANT DUBEY	Sundry Debtors	\N	\N	0.00	Unregistered
5e022242-f8ab-4d77-9a63-aacba281c8b0	cmofl3ut6000hmjdmwqd3dziu	SHATRUSHAL SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
cbcbb8f8-ae17-4e45-ae32-75cfba0b1b4d	cmofl3ut6000hmjdmwqd3dziu	SHEELA MARBLE	Sundry Debtors	09ABAPA1917B1ZH	\N	0.00	Regular
a572a5b8-f1c7-4fe5-80cd-203013e1eb3f	cmofl3ut6000hmjdmwqd3dziu	Sheoran	Sundry Debtors	\N	\N	0.00	Unregistered
8c241e1a-0f5d-4ce6-a81c-43104b49d611	cmofl3ut6000hmjdmwqd3dziu	SHIKHA SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
013800d5-b48a-4daa-ad9a-1ba802fa9ced	cmofl3ut6000hmjdmwqd3dziu	SHILPA AGENCY	Sundry Debtors	09AAJFS7957H1ZH	\N	0.00	Regular
2b8cfec2-e2d7-432b-b78f-72b70285bd22	cmofl3ut6000hmjdmwqd3dziu	SHIVAM	Sundry Debtors	\N	\N	0.00	Unregistered
792320f6-42c4-4b5c-ae10-0accba5dbd71	cmofl3ut6000hmjdmwqd3dziu	Shivam Dixit	Sundry Debtors	\N	\N	0.00	Unregistered
5144eb7f-f6c4-4342-a568-4fef1a86d462	cmofl3ut6000hmjdmwqd3dziu	SHIVAM ENTERPRISES	Sundry Debtors	09CYJPK5307B1ZL	\N	0.00	Regular
50f25501-2ad1-44b7-bc21-eba3a0dd0e7c	cmofl3ut6000hmjdmwqd3dziu	SHIVAM PRAJAPATI	Sundry Debtors	\N	\N	0.00	Unregistered
27d58d28-3167-4f0f-a1c8-6d37f6e20e0b	cmofl3ut6000hmjdmwqd3dziu	SHIVAM TIWARI	Sundry Debtors	\N	\N	0.00	Unregistered
78ebc19c-958f-4ad0-b85d-9c3098079f2c	cmofl3ut6000hmjdmwqd3dziu	Shivanan Infra Private Limited	Sundry Debtors	\N	\N	0.00	Unregistered
59874f63-2686-4e90-a89a-30b3874ab6b7	cmofl3ut6000hmjdmwqd3dziu	Shiva Traders	Sundry Debtors	09AABCS0355R1Z2	\N	0.00	Regular
b428f950-fde4-4229-82d8-597563ed6488	cmofl3ut6000hmjdmwqd3dziu	Shivay Construction	Sundry Debtors	09BJNPK0260R2ZK	\N	0.00	Regular
88852317-0e47-49bd-a2f0-20492a268002	cmofl3ut6000hmjdmwqd3dziu	Shiv Charan Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
27927993-bf90-4677-941c-fbda14cc76a4	cmofl3ut6000hmjdmwqd3dziu	Shivendra Pratap Singh Chauhan	Sundry Debtors	\N	\N	0.00	Unregistered
c5e4f55a-8b6d-48d4-96ae-87b2a69d5a3e	cmofl3ut6000hmjdmwqd3dziu	Shiv Enterprises	Sundry Debtors	\N	\N	0.00	Unregistered
99b609a8-f27a-4704-b8e9-699e83051ffd	cmofl3ut6000hmjdmwqd3dziu	SHIV ISPAT	Sundry Debtors	09AIWPG8930D1ZV	\N	0.00	Regular
b9d8a8fa-c07b-41df-95f2-02cde09c7a36	cmofl3ut6000hmjdmwqd3dziu	SHIV KRIPA	Sundry Debtors	09AODPJ3345J1ZV	\N	0.00	Regular
4580e12f-9d03-43b9-8364-19a07554d7c7	cmofl3ut6000hmjdmwqd3dziu	Shiv Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
753a1b39-f9b7-446f-ace2-77c19f56c2c5	cmofl3ut6000hmjdmwqd3dziu	SHIV MOHAN SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
854499ac-4f59-4c96-9788-54d0036e2242	cmofl3ut6000hmjdmwqd3dziu	Shiv Narayan	Sundry Debtors	\N	\N	0.00	Unregistered
8259f59c-49d6-4b8f-93e7-93d200ec302e	cmofl3ut6000hmjdmwqd3dziu	SHIV PRAKASH SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
7b00ae47-f95f-41ab-8e10-bd3b7d387fbb	cmofl3ut6000hmjdmwqd3dziu	SHIV RAJ TRADING CO.	Unsecured Loans	\N	\N	0.00	Unregistered
8e1434e1-0e3f-4aa9-8e4d-ddbdf70a8831	cmofl3ut6000hmjdmwqd3dziu	Shiv Road Lines	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
56d9932d-4d21-4f1f-b500-c90a87a75330	cmofl3ut6000hmjdmwqd3dziu	Shiv Shakti Parivahan	Sundry Creditors for Transporter	22BEQPP8019B1ZK	\N	0.00	Regular
73afe9b0-5b93-42ef-8368-c4cb22576cb5	cmofl3ut6000hmjdmwqd3dziu	Shiv Shankar Dwivedi	Sundry Debtors	\N	\N	0.00	Unregistered
c4282706-0f50-4ecc-830c-a6cceb2154dd	cmofl3ut6000hmjdmwqd3dziu	Shiv Shanker Lal Kamal	Sundry Debtors	\N	\N	0.00	Unregistered
77db9ec9-0267-476b-a4fe-2bdb1f91b666	cmofl3ut6000hmjdmwqd3dziu	SHIV SHANKER VERMA	Sundry Debtors	\N	\N	0.00	Unregistered
b1a46c44-206c-4fd6-93da-5e65e076d974	cmofl3ut6000hmjdmwqd3dziu	SHOBHIT SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
fc13c0fa-44ee-4b55-a2ec-f7b080beee06	cmofl3ut6000hmjdmwqd3dziu	SHOBHIT SRIVASTAVA	Sundry Debtors	\N	\N	0.00	Unregistered
4e570beb-dd93-4149-95ea-6495d5f0b0b9	cmofl3ut6000hmjdmwqd3dziu	Shown in Books in August	Duties & Taxes	\N	\N	0.00	\N
049ac68b-dcb7-4587-86a8-1fc228f1443c	cmofl3ut6000hmjdmwqd3dziu	Shravan Kumar Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
be700b3f-8d0d-4960-ab8d-6d6278ddce36	cmofl3ut6000hmjdmwqd3dziu	SHREE ASR CAR MOTOCORP PVT LTD	Sundry Debtors	\N	\N	0.00	Unregistered
a4c389e1-abc4-4d45-8325-59c5de1650ba	cmofl3ut6000hmjdmwqd3dziu	SHREE BALAJI INTERNATIONAL	Sundry Debtors	09ACKPG3527G1ZN	\N	0.00	Regular
8dc3cffe-e9ea-401c-b5ac-ddd859fad078	cmofl3ut6000hmjdmwqd3dziu	Shree Bala Ji Traders	Sundry Debtors	09BXFPK4986G1ZZ	\N	0.00	Regular
8d1676ad-afc1-4173-81e2-4d2c38eccfbf	cmofl3ut6000hmjdmwqd3dziu	Shree Bihari Ji Rubber Ind.Pvt.Ltd	Sundry Debtors	09AACCS0084K1Z7	\N	0.00	Regular
0038a366-45b4-442e-a321-5d161cc0629f	cmofl3ut6000hmjdmwqd3dziu	Shree Concreate Pvt Ltd	Sundry Debtors	09AADCS3671H1Z6	\N	1014.00	Regular
e320c742-f5f7-4d28-a944-7f16ad636b77	cmofl3ut6000hmjdmwqd3dziu	Shree Ganesh Corporation	Sundry Debtors	09BDBPJ2103E1Z8	\N	0.00	Regular
30265484-de01-4fb9-9e0f-fb09c5041ece	cmofl3ut6000hmjdmwqd3dziu	Shree Ganesh  Metalics Lts	Sundry Creditors	21AAHCS1277R1ZX	\N	0.00	Regular
08fc1626-a1a3-4e72-abfb-9a5377eb1fb4	cmofl3ut6000hmjdmwqd3dziu	SHREE HANUMAN ENTERPRISES	Sundry Creditors	21ANTPK3004C1ZL	\N	0.00	Regular
bae6ce8c-5c5e-49df-9255-26a4ae92f88b	cmofl3ut6000hmjdmwqd3dziu	SHREE HANUMAN TRADING AGENCY	Sundry Creditors	09AFGPB0844L1ZH	\N	0.00	Regular
338f6264-c86f-478b-be4a-3d9759c5c0c8	cmofl3ut6000hmjdmwqd3dziu	Shree Jee Steels	Sundry Creditors	09ABWFS9160Q1ZS	\N	0.00	Regular
2258ffc6-065f-4aa9-bf1e-630c78984fca	cmofl3ut6000hmjdmwqd3dziu	Shree Krishna Traders	Sundry Creditors	09BJLPG7249A1Z7	\N	0.00	Regular
b5a0e891-7b97-4373-8cfd-e18d2db5bb18	cmofl3ut6000hmjdmwqd3dziu	Shree Lakshman Rolling  Mill (India) LLP	Sundry Creditors	09ADRFS8987L1ZM	\N	-1267.00	Regular
290d3985-eef7-4cb3-be4b-43056a8e1c03	cmofl3ut6000hmjdmwqd3dziu	Shree Madhuraj Steels	Sundry Creditors	09AASPG8192K1ZV	\N	0.00	Regular
41d87030-773b-4e10-aaab-9399ea207135	cmofl3ut6000hmjdmwqd3dziu	Shree Madhuraj Steels LLP	Sundry Creditors	09AEQFS1826L1ZD	\N	-135653.50	Regular
a0919122-5d0d-422e-9426-b0ff259ab9a0	cmofl3ut6000hmjdmwqd3dziu	Shree Mahavir Transport	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
a3014ad5-573e-443b-9d94-0cab2e866729	cmofl3ut6000hmjdmwqd3dziu	Shree Parsv Nath Trading Company	Sundry Debtors	09ADIPJ6287F1Z7	\N	0.00	Regular
4cba99b7-8e45-47e5-9ced-812a18a03ca4	cmofl3ut6000hmjdmwqd3dziu	SHREE RADHEY KRISHNA STEELS	Sundry Creditors	09ARVPD0653L1ZC	\N	0.00	Regular
5268cc45-3d6c-4304-88ab-033fa68a7f91	cmofl3ut6000hmjdmwqd3dziu	Shree Radhey Residancy	Sundry Debtors	09AEHFS4769P1ZY	\N	0.00	Regular
e2afab6c-4b64-4f99-a3cc-eb80f2446e4a	cmofl3ut6000hmjdmwqd3dziu	Shree Radhey Steel Traders	Sundry Debtors	09EWHPM0964C1ZG	\N	0.00	Regular
1a0ed23e-54f3-436b-99f1-84fc82649f5f	cmofl3ut6000hmjdmwqd3dziu	Shree Radhy Radhey Ispat Pvt Ltd	Sundry Creditors	09AACCR8078B1ZI	\N	0.00	Regular
3fc54974-70f5-41d2-a07b-96cca6db072b	cmofl3ut6000hmjdmwqd3dziu	Shree Samadha Builders	Sundry Debtors	09AZEPK9055G1Z3	\N	0.00	Regular
4e9a7ef5-bf82-41a8-93b4-097212952772	cmofl3ut6000hmjdmwqd3dziu	Shree suman ceramics	Sundry Debtors	\N	\N	0.00	\N
6bc0c35f-ad14-4654-b998-53869f8a8877	cmofl3ut6000hmjdmwqd3dziu	Shree Swami Traders	Sundry Debtors	09AIQPC6753Q1ZD	\N	0.00	Regular
1422f988-e198-4f30-bd4e-8859c975f33d	cmofl3ut6000hmjdmwqd3dziu	SHREYASH INFRATECH COMPANY	Sundry Debtors	09ATIPT2376B1ZI	\N	0.00	Regular
eddee3d6-e3ef-4a52-a1a9-6062cab27c95	cmofl3ut6000hmjdmwqd3dziu	SHRI ASHTEEK INFRATECH	Sundry Debtors	09CWZPS4974C1ZK	\N	0.00	Regular
06c6c401-5c59-4356-8113-302d681a24c4	cmofl3ut6000hmjdmwqd3dziu	SHRI BABA ANANDESWAR BATTERY	Sundry Debtors	09EONPK2654P1Z2	\N	36780.00	Regular
3dfc49b8-dcfe-41bd-8bf0-ac7981377580	cmofl3ut6000hmjdmwqd3dziu	Shri Balaji Enterprises	Sundry Debtors	09CSJPK8928G1Z6	\N	0.00	Regular
7bfa25b7-a439-4175-beff-96a662809466	cmofl3ut6000hmjdmwqd3dziu	SHRI BALAJI STEELS	Sundry Debtors	09AHAPG2684H1ZD	\N	0.00	Regular
05adce01-9d97-4994-9895-fa5ba7b5aa68	cmofl3ut6000hmjdmwqd3dziu	Shri Bankey Behari Iron Traders	Sundry Debtors	09ANHPP0031G1Z9	\N	0.00	Regular
c574b8ef-2bc3-4dce-83c9-55e15ef52275	cmofl3ut6000hmjdmwqd3dziu	Shri Kanha Ji Road Linse	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
b95afbc1-7dd0-431e-ae15-735f7ba46e37	cmofl3ut6000hmjdmwqd3dziu	SHRI KANT SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
d111a45c-38ae-412b-bcc9-2b18d54aec4e	cmofl3ut6000hmjdmwqd3dziu	Shri Krishna Enterprises	Sundry Debtors	09AJUPM1373K1ZJ	\N	0.00	Regular
e2df788b-d7ce-4129-a97e-b323dfbd940d	cmofl3ut6000hmjdmwqd3dziu	Shrimati Smriti Bajpai	Sundry Debtors	\N	\N	0.00	Unregistered
9a053f57-9843-4633-adce-8c29435b17ab	cmofl3ut6000hmjdmwqd3dziu	Shrinath Pal	Sundry Debtors	\N	\N	0.00	\N
d15a7a71-7b3e-48d6-9925-bce90613e1c7	cmofl3ut6000hmjdmwqd3dziu	SHRI NIRMAL KUMAR JAIN &amp; CO	Sundry Creditors	09AAOPJ4618H1ZG	\N	0.00	Regular
acfcec60-862c-451d-a8e1-97d282e1241c	cmofl3ut6000hmjdmwqd3dziu	Shri Niwas	Sundry Debtors	\N	\N	0.00	Unregistered
b0e47136-d8de-4853-b734-a47e1e2a4777	cmofl3ut6000hmjdmwqd3dziu	SHRI PAL	Sundry Debtors	\N	\N	0.00	Unregistered
80d23963-cc5b-4407-8335-69ab9079c133	cmofl3ut6000hmjdmwqd3dziu	Shriram General Insurance Company Limited	Sundry Creditors	09AAKCS2509K1Z1	\N	0.00	Regular
723dfbdc-d7a9-42a7-b0f4-bbde7bdd4457	cmofl3ut6000hmjdmwqd3dziu	Shri Ram Traders	Sundry Debtors	09AWVPP6647H1ZL	\N	0.00	Regular
ee4d0fa7-8ec8-41cd-85f3-2074f65da592	cmofl3ut6000hmjdmwqd3dziu	SHRI SHIV GOODS CARRIER	Sundry Creditors	09AMXPN2496A1ZK	\N	0.00	Regular
86df25a9-7b09-4640-8b5b-6c3eeeeb8ae9	cmofl3ut6000hmjdmwqd3dziu	Shri Siddhivinayak Enterprises	Sundry Creditors	09AHAPT5818N1ZP	\N	0.00	Regular
bd77f462-621b-4f28-8758-050f18478879	cmofl3ut6000hmjdmwqd3dziu	SHRI SRI MAHAVIR LOGISTICS	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
d51cbed0-dca9-4a99-b1f8-2ce9909c700e	cmofl3ut6000hmjdmwqd3dziu	Shruti Enterprises	Sundry Debtors	\N	\N	0.00	\N
a17ab2f1-c31c-405e-a718-04cdd4fa983b	cmofl3ut6000hmjdmwqd3dziu	Shubham Diwakar	Sundry Debtors	\N	\N	0.00	Unregistered
dd1307f0-ded9-452a-a0eb-3c52056f8844	cmofl3ut6000hmjdmwqd3dziu	Shubham Diwivedi	Sundry Debtors	\N	\N	0.00	Unregistered
1a04afe5-3235-48c4-a265-2564fe126269	cmofl3ut6000hmjdmwqd3dziu	Shubham  Dwevdi	Sundry Debtors	\N	\N	0.00	Unregistered
0b5e9928-1cf7-4036-91e9-b5dbb5c6eb38	cmofl3ut6000hmjdmwqd3dziu	Shubhamveer	Sundry Debtors	\N	\N	0.00	Unregistered
b97e1627-f33c-4256-b3f7-672443cd73c2	cmofl3ut6000hmjdmwqd3dziu	ShUBHAM YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
46c8fdac-c9b7-4b10-9774-9e2bad604e8b	cmofl3ut6000hmjdmwqd3dziu	SHUKLA  TRADERS	Sundry Debtors	09FVNPK1622P1ZX	\N	0.00	Regular
90f9286c-c428-4b1e-9438-8f9f3f4d4fc3	cmofl3ut6000hmjdmwqd3dziu	Shyam Kishor Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
bcaa1720-847e-485b-b0d0-dc8c89eef4a3	cmofl3ut6000hmjdmwqd3dziu	SHYAM SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
ccc4760e-973f-4241-a3c4-a6eaf51dd01e	cmofl3ut6000hmjdmwqd3dziu	Shyam Sunder Saini	Sundry Debtors	\N	\N	0.00	Unregistered
7aa469c9-c3d7-4f11-b853-e64ffd862fb0	cmofl3ut6000hmjdmwqd3dziu	SHYAMU KASHYAP	Sundry Debtors	\N	\N	0.00	Unregistered
f7e5b459-0203-47cf-b0b0-7b692572307b	cmofl3ut6000hmjdmwqd3dziu	SIDDHARTH PANDEY	Sundry Debtors	\N	\N	0.00	Unregistered
5d1248b8-b1e4-43c3-ac15-5995760cfc3b	cmofl3ut6000hmjdmwqd3dziu	Sidharth Pandey	Sundry Debtors	\N	\N	0.00	Unregistered
95a621e6-3cc3-4f81-83b9-c8db9f12445e	cmofl3ut6000hmjdmwqd3dziu	SIDHI SALES CORPORATION	Sundry Debtors	\N	\N	0.00	Regular
7b5038b5-cb77-43ca-bd83-42c1e04b638f	cmofl3ut6000hmjdmwqd3dziu	SINGHAL TUBES	Sundry Debtors	09AXSPS1410P1ZR	\N	0.00	Regular
19b6697a-b4e1-4733-bef9-3169103c0595	cmofl3ut6000hmjdmwqd3dziu	Singh Traders	Sundry Debtors	09BQIPS0450F2ZS	\N	0.00	Regular
bf42f842-74da-4747-9ada-032956beacd8	cmofl3ut6000hmjdmwqd3dziu	SINGH TRADERS-GORAKHPUR	Sundry Debtors	09AVFPS5065D1ZE	\N	0.00	Regular
ae95f171-f380-4033-ac01-c0c5335387e1	cmofl3ut6000hmjdmwqd3dziu	SINGH TRADERS-K NAGAR	Sundry Debtors	09EVHPS1772K1ZV	\N	0.00	Regular
0b914d9e-b1ef-40c9-864f-cb407274d76a	cmofl3ut6000hmjdmwqd3dziu	Singh Transport	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
5b7dd643-791f-4ac9-bde9-fcf7f233818d	cmofl3ut6000hmjdmwqd3dziu	SINGHWANI TELECOM	Sundry Creditors	09ALIPS5723M1ZF	\N	0.00	Regular
20cd8949-eb30-4e76-add6-0050c58a22c1	cmofl3ut6000hmjdmwqd3dziu	Sita Ram Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
4327cd1b-0480-446b-a981-3eaaed8b5c90	cmofl3ut6000hmjdmwqd3dziu	Siwansi Concrete Products	Sundry Debtors	09APWPP7073F1Z4	\N	0.00	Regular
7e70b204-b2e5-4680-9cf0-89895d26d83c	cmofl3ut6000hmjdmwqd3dziu	S K A Steel and Power  Pvt Ltd	Sundry Creditors	22ABECS9269D1Z9	\N	0.00	Regular
d48c5eea-51e5-43a9-aee0-f3747228c2c7	cmofl3ut6000hmjdmwqd3dziu	S K D SUPPLIERS AND TRADING CO.	Sundry Debtors	09DJTPD9864G1ZF	\N	0.00	Regular
78530b53-bc67-4b05-ba2e-f06d417ca4c3	cmofl3ut6000hmjdmwqd3dziu	S.K. TRADERS	Sundry Debtors	09IKIPS3999L1ZT	\N	0.00	Regular
60f1a78e-79b8-4570-b98f-4e28bcd663cc	cmofl3ut6000hmjdmwqd3dziu	S.K. TRADERS-KANPUR	Sundry Debtors	09JNBPK2171P1ZF	\N	0.00	Regular
e5f2f55c-30bc-4e63-b678-1f8fd21f823b	cmofl3ut6000hmjdmwqd3dziu	S K Traders New	Sundry Debtors	09JNBPK2171P1ZF	\N	-115532.00	Regular
05023ad3-e2cb-4359-bee6-7e4a62263960	cmofl3ut6000hmjdmwqd3dziu	S.K. Trading Company	Sundry Debtors	\N	\N	0.00	Unregistered
c87b7a90-0233-4bbd-94c0-7f72da1543b7	cmofl3ut6000hmjdmwqd3dziu	S KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
3201cd67-a83a-4bf4-a644-99d7e7e94cae	cmofl3ut6000hmjdmwqd3dziu	S L  R Boiler  Contractor Co.	Sundry Debtors	09CCHPK0147F2ZR	\N	0.00	Regular
a417300d-a59d-428d-a4d6-958db9196d1f	cmofl3ut6000hmjdmwqd3dziu	Smt  Bina Jain (Capital A/c)	Capital Account	\N	\N	12527466.01	Unregistered
c8f7f535-ad3e-4e43-9694-d59edf3409c7	cmofl3ut6000hmjdmwqd3dziu	SMT RANJU SRIVASTAVA	Sundry Debtors	\N	\N	0.00	Unregistered
b1188680-e903-4ced-9b1e-e4a9d5bf8da6	cmofl3ut6000hmjdmwqd3dziu	Smt Saroj Mohan	Sundry Debtors	\N	\N	0.00	Unregistered
f271e48b-3ed7-4741-b4f7-369592ab827d	cmofl3ut6000hmjdmwqd3dziu	Sneha Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	\N
9a711392-f21b-4bb7-a5e8-0ce959788264	cmofl3ut6000hmjdmwqd3dziu	SOLITAIRE DIAMOND BOUTIQUE	Sundry Debtors	09AFXPJ0734N1ZR	\N	0.00	Regular
a757434c-82f7-4f28-8b44-2137cbbd031d	cmofl3ut6000hmjdmwqd3dziu	Soltech Global	Sundry Debtors	\N	\N	0.00	\N
3e8d4578-eaa0-47e3-acc6-af83a813af40	cmofl3ut6000hmjdmwqd3dziu	SONAL	Sundry Debtors	\N	\N	0.00	Unregistered
549075b8-1e69-4d62-8c70-1abbe2256328	cmofl3ut6000hmjdmwqd3dziu	SONI	Sundry Debtors	\N	\N	0.00	Unregistered
02edf17b-7ed6-4e24-9878-053a0d0542f5	cmofl3ut6000hmjdmwqd3dziu	SONI SALES CORPORATION	Sundry Creditors	09AAVFM1560A1ZA	\N	0.00	Regular
500291f5-b9ae-41d7-89dc-a4695052b48e	cmofl3ut6000hmjdmwqd3dziu	Sonu Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
2ea51251-1af9-4fa9-9523-1b1987db1acb	cmofl3ut6000hmjdmwqd3dziu	SONU PAL	Sundry Debtors	\N	\N	0.00	Unregistered
296ad618-7103-4b24-90f1-1df66b0a9eb8	cmofl3ut6000hmjdmwqd3dziu	SONU STEELS	Sundry Creditors	22AADHS9804D1ZD	\N	0.00	Regular
e0c047fb-30fd-47df-b39b-95e23ea7b81d	cmofl3ut6000hmjdmwqd3dziu	SPACE SOLUATION	Sundry Debtors	09BLVPK9494H1Z0	\N	0.00	Regular
3b8f9bf5-d344-45f7-a679-9f86e576da42	cmofl3ut6000hmjdmwqd3dziu	S.P AND COMPANY	Sundry Debtors	09AEFPA1924C1Z5	\N	0.00	Regular
f97978cd-824b-4f30-90f8-15c883b0e598	cmofl3ut6000hmjdmwqd3dziu	Sratvan Infratech Pvt Ltd	Sundry Debtors	09ABBCS4360G1ZC	\N	0.00	Regular
b15861ee-a92e-46fc-81cd-4a673df1f5ac	cmofl3ut6000hmjdmwqd3dziu	S R CONSTRUCTION	Sundry Creditors	09AHYPM0136A1ZE	\N	0.00	Regular
2df82855-789e-46bc-a668-f4e6e82b6f84	cmofl3ut6000hmjdmwqd3dziu	SRD CONSTRUCTION	Sundry Debtors	23ABUFS3019G2Z2	\N	0.00	Regular
f3db5d20-1e6b-4130-bd4d-f80e48502c58	cmofl3ut6000hmjdmwqd3dziu	SRI M K CONSTRUCTION	Sundry Debtors	09BFHPL0596R1ZK	\N	0.00	Regular
8db47c66-b665-495b-a632-0c6f05eac4e1	cmofl3ut6000hmjdmwqd3dziu	Sri Shri Mahavir Logistics	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
d295b97f-1ed0-42ec-9fe0-401c7b8a1bf2	cmofl3ut6000hmjdmwqd3dziu	SRMB SRIJAN PRIVATE LIMITED	Sundry Creditors	19AAHCS0616C1ZO	\N	0.00	Regular
d0fb9542-a1b7-4fc2-815a-5a82112a2e70	cmofl3ut6000hmjdmwqd3dziu	SRS TRADERS	Sundry Creditors	22ALEPJ8478Q1ZE	\N	0.00	Regular
56577be8-a9e0-4ec3-a010-97a183c2b2c9	cmofl3ut6000hmjdmwqd3dziu	S S A ASSOCIATES	Sundry Debtors	09AMRPA2904N1ZR	\N	0.00	Regular
4bd7fc92-c389-413d-a968-98c52a57bcf8	cmofl3ut6000hmjdmwqd3dziu	S S Beverages	Sundry Debtors	09BQHPG9760P1ZY	\N	0.00	Regular
e4d61061-911a-4cb3-88bc-e1f8a1ddf48a	cmofl3ut6000hmjdmwqd3dziu	S.S Enterprises	Sundry Creditors	09AVRPB6074D1ZG	\N	0.00	Regular
b378cb13-c6ed-4e50-b923-db7689ca2db8	cmofl3ut6000hmjdmwqd3dziu	S S MARKETING	Sundry Creditors	09ABTFS7998B1Z8	\N	-3423.00	Regular
dd55e8b6-4a38-4d94-8722-65c4e82bfbfd	cmofl3ut6000hmjdmwqd3dziu	STABLIZER	Fixed Assets	\N	\N	0.00	\N
9d4ad072-138b-4f17-a604-e3bb10c386a3	cmofl3ut6000hmjdmwqd3dziu	STAR UNION DALICHI LIFE INSURANCE	Sundry Debtors	\N	\N	0.00	Regular
e201bbe4-0d52-45e3-9ca0-8264f12c9104	cmofl3ut6000hmjdmwqd3dziu	Steel N Steel	Sundry Debtors	09ACXFS1155M1ZA	\N	0.00	Regular
92613271-153d-4274-8798-7b0105ae799f	cmofl3ut6000hmjdmwqd3dziu	Stock Insurance	Indirect Expenses	\N	\N	0.00	\N
e461b759-523a-4c88-94b5-895cfcb083ec	cmofl3ut6000hmjdmwqd3dziu	Subhash Chandra Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
20cada3c-7a6a-4afa-913a-8f0667f5f682	cmofl3ut6000hmjdmwqd3dziu	Sudga Singh	Sundry Debtors	\N	\N	0.00	Unregistered
03c38fe3-9f70-40c8-a0d9-0bb4e30389d2	cmofl3ut6000hmjdmwqd3dziu	Sudha Devi/ W/o Ashok	Sundry Debtors	\N	\N	0.00	Unregistered
dc1eeed4-88d0-4885-96cc-787311ef9fdd	cmofl3ut6000hmjdmwqd3dziu	SUDHESH INDUSTRIES PRIVATE LIMITED	Sundry Creditors	09ABDCS1756L1ZX	\N	0.00	Regular
03709ced-64ad-4dad-90f7-4746382dabe8	cmofl3ut6000hmjdmwqd3dziu	Sudhir Ahuja	Sundry Debtors	\N	\N	0.00	Unregistered
e9d5099d-b4d0-4532-9635-41739db5df10	cmofl3ut6000hmjdmwqd3dziu	Sudhir Mishra	Sundry Debtors	\N	\N	0.00	Unregistered
d078bb4d-43cc-42f4-907f-76114f1f3d05	cmofl3ut6000hmjdmwqd3dziu	SUDHIR PANDEY	Sundry Debtors	\N	\N	0.00	Unregistered
b02b4d4c-52c8-4c41-ad54-3fb4483ebf11	cmofl3ut6000hmjdmwqd3dziu	SUDHIR YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
8b466d60-b83b-4b49-83b0-9a4ccd1c467d	cmofl3ut6000hmjdmwqd3dziu	SUJATA INTERNATIONAL	Sundry Debtors	09AFKPC9631A1Z0	\N	0.00	Regular
5b3aa6ea-47ca-4b70-bc49-73192adaef9d	cmofl3ut6000hmjdmwqd3dziu	SUJLAM ONE INDUSTRIES	Sundry Debtors	\N	\N	0.00	\N
daf90781-d718-494c-813b-82681969445c	cmofl3ut6000hmjdmwqd3dziu	Sultan Ul Hind Logistics	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
e98b5fa3-0f00-4d1d-a1aa-1a2c4c60643a	cmofl3ut6000hmjdmwqd3dziu	SUMAN LATA	Sundry Debtors	\N	\N	0.00	Unregistered
d17bd3e5-2549-48f1-92a4-c2cca943e287	cmofl3ut6000hmjdmwqd3dziu	Suman Plastic Corporation	Sundry Debtors	09AALPA8191K1Z9	\N	0.00	Regular
7a1d6334-6af1-4a7b-be60-8324f3647183	cmofl3ut6000hmjdmwqd3dziu	Suman_Lata	Sundry Debtors	\N	\N	0.00	Unregistered
33322fa1-4c8e-4d62-aece-6c0b8a41ebb4	cmofl3ut6000hmjdmwqd3dziu	Sumeet Pawa	Sundry Debtors	\N	\N	0.00	Unregistered
b80618f6-1754-46af-9084-0bde9c07f327	cmofl3ut6000hmjdmwqd3dziu	Sumit Biswas	Sundry Debtors	\N	\N	0.00	Unregistered
961dee75-42cd-4432-8e76-36e8252a88ac	cmofl3ut6000hmjdmwqd3dziu	Sumit Dwivedi	Sundry Debtors	\N	\N	0.00	Unregistered
8a57977f-6e7c-4570-b95d-03f2189b38a3	cmofl3ut6000hmjdmwqd3dziu	SUMIT  KAUR  ROAD LINSE	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
80372487-42f2-4412-80f4-a73edde5676d	cmofl3ut6000hmjdmwqd3dziu	Sumit Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
abacfcab-a8f5-42e6-bf73-693c84c4e854	cmofl3ut6000hmjdmwqd3dziu	Suneel Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
6abfa1b8-f4b7-4ede-9a81-de8e0df2582a	cmofl3ut6000hmjdmwqd3dziu	SUNEEL TIWARI	Sundry Debtors	\N	\N	0.00	Unregistered
a7def838-fb9f-47b8-907b-f7b3ab1414a9	cmofl3ut6000hmjdmwqd3dziu	Suneet Chaudhary	Sundry Debtors	\N	\N	0.00	Unregistered
ca8bc70c-fbb4-43d0-a6a8-370b28f521e1	cmofl3ut6000hmjdmwqd3dziu	Sunil Dixit	Sundry Debtors	\N	\N	0.00	Unregistered
0c7bde31-d383-4bcd-b480-fd353baa6c55	cmofl3ut6000hmjdmwqd3dziu	Sunil Katiyar	Sundry Debtors	\N	\N	0.00	Unregistered
77482e28-b7b5-4079-837f-64d380bcd276	cmofl3ut6000hmjdmwqd3dziu	SUNIL KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
a312ca1d-5a12-401f-bd53-cacf86a230d3	cmofl3ut6000hmjdmwqd3dziu	SUNIL KUMAR DIWAKAR	Sundry Debtors	\N	\N	0.00	Unregistered
31b1e9b1-6edd-4630-ae6a-b2d7ff59f0d4	cmofl3ut6000hmjdmwqd3dziu	SUNIL KUMAR SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
8401deaa-9134-49e5-913f-87257cb48ac9	cmofl3ut6000hmjdmwqd3dziu	SUNIL KUMAR SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
0bb705e4-b2a9-482c-aae0-2b0369c77af4	cmofl3ut6000hmjdmwqd3dziu	SUNIL KUMAR VERMA	Sundry Debtors	\N	\N	0.00	Unregistered
2b91798f-7dfe-4eff-a39d-be092e92b7f3	cmofl3ut6000hmjdmwqd3dziu	SUNIL SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
b441214a-2048-4db8-b0bc-d26d5ba6977a	cmofl3ut6000hmjdmwqd3dziu	Sunil Sharma-Panki	Sundry Debtors	\N	\N	0.00	Unregistered
4ef95b3d-cc2d-4a4e-b33f-6493ad0c285f	cmofl3ut6000hmjdmwqd3dziu	Sunita	Sundry Debtors	\N	\N	0.00	Unregistered
a668ca11-e6a1-4b31-9817-1875e65310b4	cmofl3ut6000hmjdmwqd3dziu	SUNITA BAIS	Sundry Debtors	\N	\N	0.00	Unregistered
af0abae1-b840-46d6-a3c8-ddd0c6fb3d1d	cmofl3ut6000hmjdmwqd3dziu	SUNITA  CHANDRA	Sundry Debtors	\N	\N	0.00	Unregistered
498ac89c-c8c4-4808-aa90-d81c896f47ff	cmofl3ut6000hmjdmwqd3dziu	SUNITA GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
ccde934a-6a47-4515-a614-7b831d262903	cmofl3ut6000hmjdmwqd3dziu	Sunny Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
5c79a89c-3ac5-4da1-b615-edc5b567fa25	cmofl3ut6000hmjdmwqd3dziu	SUPER ENTERPRISES	Sundry Debtors	09AFQPI8251N1ZN	\N	0.00	Regular
5bb33aad-4879-4ce0-a960-afef3a8c306a	cmofl3ut6000hmjdmwqd3dziu	Super India Transport &amp; Comm Agent	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
d91218f2-f860-43ad-8ee1-97a2911d25d6	cmofl3ut6000hmjdmwqd3dziu	Superman Tailor	Sundry Debtors	\N	\N	0.00	\N
d35573f1-b191-422f-ba7a-72cfb482f08c	cmofl3ut6000hmjdmwqd3dziu	Super Metro Transport Service	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
15d83d66-f897-4ef7-b152-f7b2f404440c	cmofl3ut6000hmjdmwqd3dziu	Super Thons Logistics	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
1f333cf3-e45e-4507-a7a7-f47f7cef0091	cmofl3ut6000hmjdmwqd3dziu	Surajeet Pal	Sundry Debtors	\N	\N	0.00	Unregistered
f326aeb7-5761-4340-968f-249c16802512	cmofl3ut6000hmjdmwqd3dziu	Suraj Pandey	Sundry Debtors	\N	\N	0.00	\N
bc3fb617-4fd6-47bb-aad9-affff1abd0b4	cmofl3ut6000hmjdmwqd3dziu	SURAJ ROLLING PVT LTD	Sundry Creditors	22AAJCS0211K1ZR	\N	0.00	Regular
0e711f06-1afc-4b86-8567-63adc6f43818	cmofl3ut6000hmjdmwqd3dziu	Surbhi Dwivedi	Sundry Debtors	\N	\N	0.00	Unregistered
af2a1268-bd9a-4948-ac2a-022add36b5be	cmofl3ut6000hmjdmwqd3dziu	Surendra	Sundry Debtors	\N	\N	0.00	Unregistered
7923487e-8190-4397-a452-a6cdc21187b7	cmofl3ut6000hmjdmwqd3dziu	SURENDRA KUMAR PAL	Sundry Debtors	\N	\N	0.00	Unregistered
346baa8b-3af3-4cc4-89df-33a805a5c61f	cmofl3ut6000hmjdmwqd3dziu	SURESH CHANDRA	Sundry Debtors	\N	\N	0.00	Unregistered
1fef2d20-96e8-4d25-ad1c-1ee8df7b0c4a	cmofl3ut6000hmjdmwqd3dziu	Suresh Dixit	Sundry Debtors	\N	\N	0.00	Unregistered
a303c097-87fb-4d2b-9a4e-a83c2a5e7d1c	cmofl3ut6000hmjdmwqd3dziu	SURESH KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
68dc7cd1-502e-4d9d-93e4-f51869de1f86	cmofl3ut6000hmjdmwqd3dziu	Suresh Pathak	Sundry Debtors	\N	\N	0.00	Unregistered
c7b62f6b-209f-4ed6-8b8d-a747252c6762	cmofl3ut6000hmjdmwqd3dziu	Surjeet Singh	Sundry Debtors	\N	\N	0.00	Unregistered
b2cd0553-35b1-4c14-b6bd-3474f5992745	cmofl3ut6000hmjdmwqd3dziu	Surya Ujjain Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
5bf51af5-e7d1-4cf1-ae09-aee461acd2ef	cmofl3ut6000hmjdmwqd3dziu	SUSHANT BUILDERS	Sundry Debtors	\N	\N	0.00	\N
bfa17b34-4431-4baf-8461-66ce3e940dd8	cmofl3ut6000hmjdmwqd3dziu	Sushil Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
7ab6adfb-9283-4938-9f71-63270d0cd6db	cmofl3ut6000hmjdmwqd3dziu	Sushil Singh	Sundry Debtors	\N	\N	0.00	Unregistered
823351fc-7579-4855-aae2-d4f4ef1258cc	cmofl3ut6000hmjdmwqd3dziu	Suspence A\\c	Suspense A/c	\N	\N	0.00	\N
0f7e9b3c-6965-46e6-8baa-66e2efbc50ec	cmofl3ut6000hmjdmwqd3dziu	SWASTIC VENTURES	Sundry Debtors	09AEDFS0761F1Z3	\N	0.00	Regular
88ae87e7-daca-44b8-a091-93e8a78a0718	cmofl3ut6000hmjdmwqd3dziu	Swastic Vible Secure Soluation	Sundry Creditors	09AFAPC1367B1Z3	\N	0.00	Regular
a84a9382-d880-4a1b-b8dc-8d3d1bdeb853	cmofl3ut6000hmjdmwqd3dziu	Swati Bulk Carriers	Sundry Debtors	\N	\N	0.00	\N
cf47f528-d198-467b-97a8-be20b9bc4a65	cmofl3ut6000hmjdmwqd3dziu	Sweta Devi	Sundry Debtors	\N	\N	0.00	Unregistered
a1bdf0ac-7881-437c-8f8a-c5d57d671fd5	cmofl3ut6000hmjdmwqd3dziu	SWETA SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
03c7eb29-50b0-4dfb-a594-0f546dbcfb72	cmofl3ut6000hmjdmwqd3dziu	TAIMOOR TRADERS	Sundry Debtors	09CBFPN0175F1ZP	\N	0.00	Regular
bf56ced3-599e-4cdd-b7e5-36d0714be560	cmofl3ut6000hmjdmwqd3dziu	TAJ TRANSPORT	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
d697d23a-d9de-4251-ba38-757736a18142	cmofl3ut6000hmjdmwqd3dziu	TALLY(INDIA) PRIVATE LIMITED&#13;&#10;&#13;&#10;	Sundry Creditors	29AACCT3705E1ZJ	\N	0.00	Regular
a223ae08-8409-4806-adb4-067f7d5c6ed3	cmofl3ut6000hmjdmwqd3dziu	TARA	Sundry Debtors	\N	\N	0.00	Unregistered
5833d69b-2447-400c-be2d-45eb531b4267	cmofl3ut6000hmjdmwqd3dziu	TARA DEVI	Sundry Debtors	\N	\N	0.00	Unregistered
c487725f-4bfa-4c9c-8ec4-07b89000c7b4	cmofl3ut6000hmjdmwqd3dziu	Tara Singh	Sundry Debtors	\N	\N	0.00	\N
4a60911e-fcea-4799-b6fd-a270ae4e5763	cmofl3ut6000hmjdmwqd3dziu	TASMIA ENGINEERING AND FABRICATION	Sundry Debtors	09BWOPK0914Q1ZV	\N	0.00	Regular
c77b3c8a-9fee-47d6-b2ae-f3dd503817b2	cmofl3ut6000hmjdmwqd3dziu	Tastay Oil Products Pvt Ltd	Sundry Debtors	09AAHCT6057F1Z5	\N	0.00	Regular
18605b3b-b33d-4e5a-8d6e-d6a6efd20abe	cmofl3ut6000hmjdmwqd3dziu	T.C.S ON PURCHASE	Deposits (Asset)	\N	\N	0.00	\N
60e688a3-8a6b-4e1d-9900-ab845b923b5b	cmofl3ut6000hmjdmwqd3dziu	T.C.S. ON PURCHASE 1-10-2020	Deposits (Asset)	\N	\N	0.00	\N
66d36139-2b0f-4cf2-b575-03d2e8b27aa8	cmofl3ut6000hmjdmwqd3dziu	T C S ON PURCHASE-2022-2023	Deposits (Asset)	\N	\N	0.00	Unregistered
749ee4ab-2176-4dc1-9558-3e52345587b0	cmofl3ut6000hmjdmwqd3dziu	TCS ON PURCHASE -2023-2024	Loans & Advances (Asset)	\N	\N	0.00	\N
d2ee57df-1fee-4fab-bb58-307f93ece09b	cmofl3ut6000hmjdmwqd3dziu	TCS ON PURCHASE RECEIVED	Deposits (Asset)	\N	\N	0.00	Unregistered
2d534fa7-e177-4986-9582-5469a3998daf	cmofl3ut6000hmjdmwqd3dziu	TCS ON SALE	Loans & Advances (Asset)	\N	\N	0.00	Unregistered
26f0fedd-140e-4ee9-bef3-85fe998225a8	cmofl3ut6000hmjdmwqd3dziu	TCS Payble	Current Liabilities	\N	\N	2177.00	\N
8978e255-52bf-421c-b76b-6f7a00ca71a7	cmofl3ut6000hmjdmwqd3dziu	TCS Receivable	Loans & Advances (Asset)	\N	\N	-3960.00	\N
6400f97e-a8a5-4a3a-b168-4ccee0c2dbed	cmofl3ut6000hmjdmwqd3dziu	TDS	Loans & Advances (Asset)	\N	\N	0.00	Unregistered
33e09c9c-1f5e-4809-a114-411de32a8d5b	cmofl3ut6000hmjdmwqd3dziu	TDS DEDUCTED ON PURCHASE -194Q	Current Liabilities	\N	\N	4363.00	Regular
906af530-d2ba-45ec-943b-d34af21a6f67	cmofl3ut6000hmjdmwqd3dziu	TDS Deduction on Contractor-94-C	Current Liabilities	\N	\N	1516.00	Unregistered
27ed6393-bec7-4615-93f2-c450a9e8869e	cmofl3ut6000hmjdmwqd3dziu	TDS ON CAR PURCHASE U/S 206CL	Deposits (Asset)	\N	\N	0.00	\N
602108cc-a9a4-43f5-9450-8af00cfc6e8e	cmofl3ut6000hmjdmwqd3dziu	TDS ON INTEREST (94-A)	Current Liabilities	\N	\N	35575.00	Unregistered
8c886196-0b82-4bfd-bd23-ddef6edbf424	cmofl3ut6000hmjdmwqd3dziu	TDS ON PNB+HDFC INTEREST EARN	Deposits (Asset)	\N	\N	0.00	Unregistered
81c73186-720e-43ae-b36e-fc99923d7c7a	cmofl3ut6000hmjdmwqd3dziu	TDS on Professional Charges(194J)	Current Liabilities	\N	\N	750.00	\N
97dca733-049d-40dd-8489-cc0c35de33d0	cmofl3ut6000hmjdmwqd3dziu	TDS ON PURCHASE -194Q	Deposits (Asset)	\N	\N	0.00	Regular
8f43254e-3814-423b-b8ed-562bb05f3484	cmofl3ut6000hmjdmwqd3dziu	TDS  PNB A/C	Deposits (Asset)	\N	\N	0.00	Regular
304e8577-5574-4761-8de6-f42274e0602b	cmofl3ut6000hmjdmwqd3dziu	TDS Receivable(24-25)	Loans & Advances (Asset)	\N	\N	-32375.00	Unregistered
fd6635d8-b1b5-43ab-928b-2f7175f641df	cmofl3ut6000hmjdmwqd3dziu	Techno Electro	Sundry Debtors	\N	\N	0.00	Unregistered
99404c1d-798c-49ca-8f1a-02ed4bfaccd6	cmofl3ut6000hmjdmwqd3dziu	Tej Singh Adhikari	Sundry Debtors	\N	\N	0.00	Unregistered
b4cb236e-54ae-44e4-b308-ddfffd951f94	cmofl3ut6000hmjdmwqd3dziu	Telephone Expenses	Indirect Expenses	\N	\N	0.00	\N
774a32d4-c7b0-43b6-ad7a-da70e783482f	cmofl3ut6000hmjdmwqd3dziu	THE INTERIOR DOCTOR	Sundry Debtors	\N	\N	0.00	\N
2583b3fe-a104-4e9e-a836-edd89d612575	cmofl3ut6000hmjdmwqd3dziu	THE K.D. RESORTS	Sundry Debtors	09AAOFT6288R1ZS	\N	0.00	Regular
f1432314-19ef-43c3-8724-6d556ba07116	cmofl3ut6000hmjdmwqd3dziu	The Prayag Packegers	Sundry Debtors	09AOYPG3074N1Z3	\N	0.00	Regular
01547af0-678a-474c-9f79-68918ecd911d	cmofl3ut6000hmjdmwqd3dziu	THERMOTECH ENGINEERS	Sundry Debtors	09AAOFT4170C1Z2	\N	0.00	Regular
f36cc8c4-93bc-4dba-93dc-2b51f6e403a9	cmofl3ut6000hmjdmwqd3dziu	TIMEXO FASTENERS INDIA PRIVATE LIMITED	Sundry Creditors	\N	\N	0.00	\N
af3b73f0-f99f-4da0-9012-f2ba9a96dcbe	cmofl3ut6000hmjdmwqd3dziu	TIWARI TRADERS	Sundry Debtors	09AFFPT0952E2ZD	\N	0.00	Regular
a1c32066-a59c-453d-8665-1141a429c3e3	cmofl3ut6000hmjdmwqd3dziu	Trade Discount	Indirect Incomes	\N	\N	0.00	\N
3143110a-48cf-4d66-8e1d-47a523bae0f5	cmofl3ut6000hmjdmwqd3dziu	TRADE STONE LIMITED	Sundry Debtors	09AAACL2544H1ZM	\N	0.00	Regular
6ad22ca9-a616-4319-aefc-683e8150cd67	cmofl3ut6000hmjdmwqd3dziu	TRANS ENTERPRISES PVT LTD	Sundry Debtors	\N	\N	0.00	\N
b5d79abc-64e6-4528-9b10-9c232d8d4353	cmofl3ut6000hmjdmwqd3dziu	Transport  Carriers of India Logistics	Sundry Creditors for Transporter	09KKGPK2255H1ZV	\N	0.00	Regular
d2430cd6-57c0-49bc-9f8f-4490271d4cf8	cmofl3ut6000hmjdmwqd3dziu	Travelling Expenses	Indirect Expenses	\N	\N	0.00	\N
fef4c8e8-9866-4050-8028-b04746375277	cmofl3ut6000hmjdmwqd3dziu	Trilokesh Transport	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
c4eba52d-1440-47a6-99f8-b5b04f8ec092	cmofl3ut6000hmjdmwqd3dziu	Tripuresh Singh	Sundry Debtors	\N	\N	0.00	Unregistered
6518f037-7e47-42ee-8eaf-f81c6d10dec1	cmofl3ut6000hmjdmwqd3dziu	TULSIRAM KASHYAP	Sundry Debtors	\N	\N	0.00	Unregistered
6bcd7ce2-e5a4-4aa4-8bc4-1a175acf9d44	cmofl3ut6000hmjdmwqd3dziu	Twelve Spaces  Pvt Ltd	Sundry Debtors	\N	\N	0.00	Regular
f16b8bd6-323a-4ee0-9b3e-05f5b581df2f	cmofl3ut6000hmjdmwqd3dziu	UBI  A/C NO. 176626650000002	Secured Loans	\N	\N	251814.00	Regular
fbdf2a2b-f90a-4ca3-8363-e76250cd89f9	cmofl3ut6000hmjdmwqd3dziu	UBI  A/C NO. 176626650000002  Home Loan	Secured Loans	\N	\N	0.00	Regular
70f97208-63a5-4ccd-9681-d22071d0b9b0	cmofl3ut6000hmjdmwqd3dziu	UBI A/C NO-510101001815571	Bank Accounts	\N	\N	0.00	\N
3df189fb-d90c-4658-ba5b-d4c538f10477	cmofl3ut6000hmjdmwqd3dziu	UBI Bank H Loan-560631000112667	Bank OD A/c	\N	\N	0.00	\N
f6661a14-609f-4244-aad9-bac2db099024	cmofl3ut6000hmjdmwqd3dziu	UBI LOAN A/C-5607610011191131( CAR LOAN)	Bank OD A/c	\N	\N	0.00	\N
e77dfd45-8e69-46f7-b97a-a5a7d7d12176	cmofl3ut6000hmjdmwqd3dziu	UBI S/B A/C NO. 520361001693349	Bank Accounts	\N	\N	-28099.00	\N
7f5d8a5a-dc1b-4449-9c96-a82735a309bc	cmofl3ut6000hmjdmwqd3dziu	UDAI	Sundry Debtors	\N	\N	0.00	Unregistered
35d7bfc5-89b8-4973-9dda-2bea6f96c6ed	cmofl3ut6000hmjdmwqd3dziu	UJJAWAL KUMAR ASTHANA	Sundry Debtors	\N	\N	0.00	Unregistered
b3ff48c4-d423-4838-9110-f04b37a87d50	cmofl3ut6000hmjdmwqd3dziu	Ujjual Singh	Sundry Debtors	\N	\N	0.00	Unregistered
1af08198-9b61-4d5b-8a29-d17e6a47defa	cmofl3ut6000hmjdmwqd3dziu	UMA DEVI	Sundry Debtors	\N	\N	0.00	Unregistered
ebba85e0-034a-45cc-acf0-49512f62e6db	cmofl3ut6000hmjdmwqd3dziu	UMA SHANKER	Sundry Debtors	\N	\N	0.00	Unregistered
d345a1da-7451-4781-83d3-4e9a64691421	cmofl3ut6000hmjdmwqd3dziu	Umesh Chanda Srivastava	Current Liabilities	\N	\N	0.00	Unregistered
46444a46-25a6-4ba3-aded-260a4e08358e	cmofl3ut6000hmjdmwqd3dziu	UNION BANK OF INDIA	Bank OD A/c	\N	\N	579019.65	\N
6ce45c65-832e-4016-b62e-e124ac96434d	cmofl3ut6000hmjdmwqd3dziu	UNIQUE TRADERS	Sundry Debtors	09HZOPK0993L1ZE	\N	0.00	Regular
9b53b848-e7e5-4ddc-8954-223fbc5653e6	cmofl3ut6000hmjdmwqd3dziu	United Mercantile Bank Saving A\\c	Bank Accounts	\N	\N	0.00	\N
3208edd0-ee6c-479b-a78c-9fe6920133db	cmofl3ut6000hmjdmwqd3dziu	Unloading Out Ward on Sale	Indirect Expenses	\N	\N	0.00	\N
383adac5-02a2-4616-a6ed-eb4de9c5ad54	cmofl3ut6000hmjdmwqd3dziu	Unloading Paid	Direct Expenses	\N	\N	0.00	\N
3944207a-6a03-4f33-baa6-850323888fec	cmofl3ut6000hmjdmwqd3dziu	Upendra Singh	Sundry Debtors	\N	\N	0.00	Unregistered
1dd3452a-41ec-4cfb-a58e-83d491980b44	cmofl3ut6000hmjdmwqd3dziu	U.P. MAHARASHTRA ROADWAYS	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
eaa163be-1756-4437-a1a4-770e7ca990e5	cmofl3ut6000hmjdmwqd3dziu	USHA DEVI	Sundry Debtors	\N	\N	0.00	Unregistered
04639741-cfca-4308-96b9-898b5daddf5a	cmofl3ut6000hmjdmwqd3dziu	USHA WIRON	Sundry Creditors	09BDNPC3156L1Z9	\N	0.00	Regular
6dd4085a-ca34-4b4c-80c0-d84d7f72cd59	cmofl3ut6000hmjdmwqd3dziu	Utkarsh	Sundry Debtors	\N	\N	0.00	\N
0f243c4a-bafa-46e6-a426-a408544ab813	cmofl3ut6000hmjdmwqd3dziu	UTTAM KUSHWAHA	Sundry Debtors	\N	\N	0.00	Unregistered
daf30022-72c2-4946-8ad7-ece185065dff	cmofl3ut6000hmjdmwqd3dziu	Vaibhav Agnihotri	Sundry Debtors	\N	\N	0.00	Unregistered
ab1e3cb6-9b3c-4dd5-9341-6d1f6df20938	cmofl3ut6000hmjdmwqd3dziu	Vaibhav Gangwar	Sundry Debtors	\N	\N	0.00	Unregistered
00f78cc3-8d3f-407a-afe6-2999330b73c6	cmofl3ut6000hmjdmwqd3dziu	Vaibhav Singh	Sundry Debtors	\N	\N	0.00	Unregistered
8de033b9-fd0c-4d5d-9cbe-1be2c5ddb970	cmofl3ut6000hmjdmwqd3dziu	Vaibhav Traders	Sundry Debtors	09GQGPS4752B1ZL	\N	0.00	Regular
4750db77-2c3f-4efc-953b-8f64312250c1	cmofl3ut6000hmjdmwqd3dziu	Vaishno Construction and Trading Company	Sundry Debtors	09BDKPS4505E1ZG	\N	0.00	Regular
2ce1a88b-e3bd-40f4-9457-e35caef5932b	cmofl3ut6000hmjdmwqd3dziu	VAJRANGI INFRATECH SERVICES	Sundry Debtors	\N	\N	0.00	\N
40a7e780-496a-45f3-a2ea-b5c1d8584b80	cmofl3ut6000hmjdmwqd3dziu	Vandana	Sundry Debtors	\N	\N	0.00	Unregistered
b397f420-97c1-4bf9-b19f-aa4c2b5c9d59	cmofl3ut6000hmjdmwqd3dziu	Vandana Mushkan	Sundry Debtors	\N	\N	0.00	Unregistered
54ea8020-0f4f-46ed-a0ec-e07d43c882b0	cmofl3ut6000hmjdmwqd3dziu	VANDAN TEXTILES	Sundry Debtors	\N	\N	0.00	\N
e54ac270-15d3-4b23-92cc-9a7dd5b22cb8	cmofl3ut6000hmjdmwqd3dziu	Vande  Bharat Transports	Sundry Creditors for Transporter	\N	\N	0.00	\N
a93be40a-1a4c-4ac8-a1c3-1ceec54c45c3	cmofl3ut6000hmjdmwqd3dziu	VANDHANA RAJPUT	Sundry Debtors	\N	\N	0.00	Unregistered
51774989-95b5-430a-88a6-5030c2e1a139	cmofl3ut6000hmjdmwqd3dziu	VANYA TRANSPORT	Sundry Creditors for Transporter	09ASQPA0174K1ZK	\N	0.00	Regular
55e62f43-8cc6-456d-90ab-491fd7ed12a8	cmofl3ut6000hmjdmwqd3dziu	Vardhamn Industries	Sundry Debtors	09AAFFV9550P1Z8	\N	0.00	Regular
c9265057-f1a6-4ddf-9f87-dacedc50672b	cmofl3ut6000hmjdmwqd3dziu	VARUN KUMAR SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
1114a06b-7822-441e-bb13-2d8d9b84ea14	cmofl3ut6000hmjdmwqd3dziu	Varun Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
6584244f-17b1-4e93-8bcf-f31a358046d5	cmofl3ut6000hmjdmwqd3dziu	VATSYA INFRASTRUCTURE PVT LTD	Sundry Debtors	09AADCV5201E1ZN	\N	0.00	Regular
c94d302f-1601-4247-8088-ea1ae97430b1	cmofl3ut6000hmjdmwqd3dziu	VEDATMANE ASSOCIATES	Sundry Debtors	\N	\N	0.00	\N
a8a002e3-2dcd-4505-b8ca-8d44a59b47b0	cmofl3ut6000hmjdmwqd3dziu	Vehicle Running and Maintinance	Indirect Expenses	\N	\N	0.00	\N
8d0ff5df-7828-4e88-b7d8-cfd88f78e04e	cmofl3ut6000hmjdmwqd3dziu	VERMA ENTERPRISES	Sundry Debtors	09AGDPV8524D1Z6	\N	0.00	Regular
8201e2e4-eba0-4270-aebe-fdb5c6b813de	cmofl3ut6000hmjdmwqd3dziu	VG HOUSING DEVELOPERS	Sundry Debtors	09CHVPG3278E1ZW	\N	0.00	Regular
6c3402d0-ae67-49bc-b354-7698205d649d	cmofl3ut6000hmjdmwqd3dziu	Vijaya	Capital Account	\N	\N	0.00	Unregistered
57a041fd-ee04-429c-9c79-d52f49740eac	cmofl3ut6000hmjdmwqd3dziu	Vijay Kumar Pal	Sundry Debtors	\N	\N	0.00	Unregistered
6f4759fd-0f76-4e3b-b61c-725d4f8dab60	cmofl3ut6000hmjdmwqd3dziu	VIJAY KUMAR SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
bcfb3211-b96a-4cbb-a0c5-c4349896067a	cmofl3ut6000hmjdmwqd3dziu	Vijay Pal Singh	Sundry Debtors	\N	\N	0.00	Unregistered
b6929297-0751-435f-a102-5b38bea7e6e2	cmofl3ut6000hmjdmwqd3dziu	VIJAY SHANKER SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
4b52edde-af8d-48a8-aa22-64743ccaada2	cmofl3ut6000hmjdmwqd3dziu	Vijay Singh-Brajesh	Sundry Debtors	\N	\N	0.00	Unregistered
2152b120-7125-4ad5-ad37-141b8dd6e7d2	cmofl3ut6000hmjdmwqd3dziu	VIJAY SINGH RATHOR	Sundry Debtors	\N	\N	0.00	Unregistered
db5ae819-c0ab-4a31-992e-587e48d3cfe2	cmofl3ut6000hmjdmwqd3dziu	VIJAY SINGH YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
ee003744-36a6-4e47-8383-39d50716e3c8	cmofl3ut6000hmjdmwqd3dziu	Vijay Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
37d70233-b0c0-4413-8c5a-bd131a1a0ec5	cmofl3ut6000hmjdmwqd3dziu	VIKARAM SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
566458dc-b5b4-4dfc-8b7f-27769b88d529	cmofl3ut6000hmjdmwqd3dziu	VIKASH  KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
9505e53c-afc9-4294-8fc8-382e6705ca69	cmofl3ut6000hmjdmwqd3dziu	VIKASH KUMAR YADAV	Sundry Debtors	\N	\N	0.00	Unregistered
38e88baf-b4a8-432d-83d8-b35b9c7e2919	cmofl3ut6000hmjdmwqd3dziu	VIKASH SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
d15ee429-06f7-42be-9819-c06ad8dac757	cmofl3ut6000hmjdmwqd3dziu	Vikash Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
3374de2e-12f7-403f-99a1-dfc6c841b045	cmofl3ut6000hmjdmwqd3dziu	Vikas Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
5d1a7045-5ab1-45cc-8386-1d0890223a5e	cmofl3ut6000hmjdmwqd3dziu	Vikram Construction Company	Sundry Debtors	09COJPS0695J2Z6	\N	0.00	Regular
14bc512c-9489-4d24-bfdb-7c64ec428f31	cmofl3ut6000hmjdmwqd3dziu	VIKRAM PRAJAPATI	Sundry Debtors	\N	\N	0.00	Unregistered
bfe96c96-f36f-4ded-b5ae-ab9ca97d0174	cmofl3ut6000hmjdmwqd3dziu	Vikram Pratap Singh	Sundry Debtors	\N	\N	0.00	Unregistered
56cfbfc7-f9a8-478a-885a-0c8bfde3fa38	cmofl3ut6000hmjdmwqd3dziu	VIKRAM SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
a719bcc7-91e4-4d20-8f39-c33fd33aa9d7	cmofl3ut6000hmjdmwqd3dziu	VIKRANT SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
5c567347-0721-46e6-a043-8f3b2494b228	cmofl3ut6000hmjdmwqd3dziu	Vimal Awasthi	Sundry Debtors	\N	\N	0.00	Unregistered
dde6afaf-9c8d-4bce-b3b7-3a01033631fc	cmofl3ut6000hmjdmwqd3dziu	VIMAL ENTERPRISES	Sundry Debtors	\N	\N	0.00	Unregistered
16830036-86aa-468e-a259-a774688ebc48	cmofl3ut6000hmjdmwqd3dziu	Vimal Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
9f638b67-9c1b-4313-a6ad-b5261467bfd0	cmofl3ut6000hmjdmwqd3dziu	VIMAL KUMAR PAL	Sundry Debtors	\N	\N	0.00	Unregistered
64b1bffd-2138-43b0-93e4-6d51cc8d6913	cmofl3ut6000hmjdmwqd3dziu	VIMAL KUMAR SHUKLA	Sundry Debtors	\N	\N	0.00	Unregistered
873ea7eb-4aa4-4338-99fa-16219a572e40	cmofl3ut6000hmjdmwqd3dziu	Vimla Enterprises	Sundry Debtors	09CVAPS7784L1ZM	\N	0.00	Regular
8357fa2b-35b9-4fb1-ad2c-cb3a6204415c	cmofl3ut6000hmjdmwqd3dziu	Vimlesh Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
b1eec47c-ea02-4c16-863f-a509d989b3a9	cmofl3ut6000hmjdmwqd3dziu	VINAYAK BUILDERS &amp; SUPPLIERS	Sundry Debtors	09AAGFV8017J1ZR	\N	0.00	Regular
5f42f593-b497-42bc-ae04-22eb79a38c78	cmofl3ut6000hmjdmwqd3dziu	VINAY CONSTRUCTION AND DEVELOPERS	Sundry Debtors	09AGYPG1326K1ZZ	\N	0.00	Regular
199d888d-b1a9-4fc8-aa2d-dcaf2bd4bb7c	cmofl3ut6000hmjdmwqd3dziu	Vinay Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
41d306b3-cd48-4961-b597-dbd3227ecf2a	cmofl3ut6000hmjdmwqd3dziu	Vinay Kumar Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
e0489ce5-afa9-43dc-bf07-dd883da85a48	cmofl3ut6000hmjdmwqd3dziu	VINAY KUMAR KATIYA	Sundry Debtors	\N	\N	0.00	Unregistered
4aae117a-7b9e-47d6-963f-14dccd2bdf59	cmofl3ut6000hmjdmwqd3dziu	Vinay Kumar Pal	Sundry Debtors	\N	\N	0.00	Unregistered
02875e9f-af97-4abe-bdc5-48c0283ba9c1	cmofl3ut6000hmjdmwqd3dziu	VINAY KUMAR SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
660f142f-c201-4d8c-8e9b-2cc9ed83bb9e	cmofl3ut6000hmjdmwqd3dziu	VINAY KUMAR SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
19eb6aa7-5a21-47f2-817d-e00392fe7fd2	cmofl3ut6000hmjdmwqd3dziu	Vinay Prakash	Sundry Debtors	\N	\N	0.00	Unregistered
0a747a9e-a31b-4596-858b-c8fb8229eab4	cmofl3ut6000hmjdmwqd3dziu	VINAY SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
35a3e02f-f57d-489c-8d43-712c0ed6e838	cmofl3ut6000hmjdmwqd3dziu	Vinay Singh Chauhan	Sundry Debtors	\N	\N	0.00	Unregistered
5928051e-1dda-472a-8817-ae9d42f7b908	cmofl3ut6000hmjdmwqd3dziu	VINEETA VERMA	Sundry Debtors	\N	\N	0.00	Unregistered
502c0ba7-29a6-44c6-afca-fb19d7314525	cmofl3ut6000hmjdmwqd3dziu	Vineet Saraswat	Sundry Debtors	\N	\N	0.00	\N
1e6b1f53-2084-4f3e-b4ed-c9aa0e2003c6	cmofl3ut6000hmjdmwqd3dziu	Vinod Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
cbe2474d-d695-41c3-b336-01343e1674b1	cmofl3ut6000hmjdmwqd3dziu	Vinod Kumar-Sarvodya Nagar	Sundry Debtors	\N	\N	0.00	Unregistered
504ed996-6327-453c-8f65-b4bcc16738f4	cmofl3ut6000hmjdmwqd3dziu	VINOD KUMAR SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
d11af0bd-29db-491d-b188-1177f7eb4d03	cmofl3ut6000hmjdmwqd3dziu	Vinod Kumar Sharmaa	Sundry Debtors	\N	\N	0.00	Unregistered
8fc5a87b-135f-4591-b14f-b992f60b2a30	cmofl3ut6000hmjdmwqd3dziu	Vinod Kumar Yadav	Sundry Debtors	\N	\N	0.00	Unregistered
6f0fda64-edc7-4b44-87c5-eae73eb7b9ab	cmofl3ut6000hmjdmwqd3dziu	Vinod Singh	Sundry Debtors	\N	\N	0.00	\N
64b5515e-aeb7-417a-9948-08ef384fcc3e	cmofl3ut6000hmjdmwqd3dziu	Vipin Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
3d60cd9d-79de-4265-a357-5b379849d3ec	cmofl3ut6000hmjdmwqd3dziu	VIPIN SHARMA	Sundry Debtors	\N	\N	0.00	Unregistered
eab22cfa-0a3c-4c2c-861c-f309a236bb71	cmofl3ut6000hmjdmwqd3dziu	VIRAJ INFRA	Sundry Debtors	09BANPC1399C1ZP	\N	0.00	Regular
90e1da7e-e547-4d55-974b-d091c52cf84b	cmofl3ut6000hmjdmwqd3dziu	VIRENDRA KUMAR GAUTAM	Sundry Debtors	\N	\N	0.00	Unregistered
e7d3b53c-9db7-45c7-8b7a-33b9890e1dad	cmofl3ut6000hmjdmwqd3dziu	VIRENDRA SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
3757c1b4-7821-4022-90d6-f8a976c13b07	cmofl3ut6000hmjdmwqd3dziu	Vishal	Sundry Debtors	\N	\N	0.00	Unregistered
1174eb41-c59b-4c33-ac32-b2d653c4458c	cmofl3ut6000hmjdmwqd3dziu	VISHAL GUPTA	Sundry Debtors	\N	\N	0.00	Unregistered
a3681fde-609a-4bfa-88e6-9d20858589f3	cmofl3ut6000hmjdmwqd3dziu	VISHAL PANDEY	Sundry Debtors	\N	\N	0.00	Regular
d178ce4d-1a94-4e39-a395-96c62c8ce8af	cmofl3ut6000hmjdmwqd3dziu	VISHAL ROAD LINES	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
e478a45d-4df9-4b0a-8963-74794a5a84a0	cmofl3ut6000hmjdmwqd3dziu	Vishal Sharma	Sundry Debtors	\N	\N	0.00	Unregistered
59cac109-9214-4e7e-b2d8-beb421968383	cmofl3ut6000hmjdmwqd3dziu	Vishal Singh	Sundry Debtors	\N	\N	0.00	\N
f2e6daa6-7f63-4857-9c50-98d170e71134	cmofl3ut6000hmjdmwqd3dziu	VISHAL TRADERS	Sundry Debtors	09DHRPP5541N1ZD	\N	71614.00	Regular
f3f76902-5608-48ee-9b0f-454c17dc7dcc	cmofl3ut6000hmjdmwqd3dziu	VISHAL TRADERS DOOL	Sundry Debtors	09FODPS5508R1Z0	\N	0.00	Regular
05542780-9471-4d01-af23-de1673a8412d	cmofl3ut6000hmjdmwqd3dziu	VISHESH INFRASTRUCTURE PRIVATE LIMITED	Sundry Debtors	09AACCV4079M1ZP	\N	0.00	Regular
024e45c1-9077-451e-8744-afdffab2fc02	cmofl3ut6000hmjdmwqd3dziu	VISHNU KAUSHAL	Sundry Debtors	\N	\N	0.00	Unregistered
eb496ed0-395d-4eae-9438-80d5eb64fada	cmofl3ut6000hmjdmwqd3dziu	Vishnu Rathour	Sundry Debtors	\N	\N	0.00	Unregistered
52645211-ec7c-44c5-90f7-a515436828c2	cmofl3ut6000hmjdmwqd3dziu	VISHWAHARI STEELS	Sundry Creditors	20AATFV3154B1ZF	\N	0.00	Regular
d5944733-c17d-4992-830f-dd0e9a97a580	cmofl3ut6000hmjdmwqd3dziu	Vivek Kumar	Sundry Debtors	\N	\N	0.00	Unregistered
5c92a041-859f-4d98-9d62-833558e768b5	cmofl3ut6000hmjdmwqd3dziu	Vivek Kumar Gupta	Sundry Debtors	\N	\N	0.00	Unregistered
92ccf3dd-73a1-429f-bcb0-c9d826d9ec53	cmofl3ut6000hmjdmwqd3dziu	VIVEK KUMAR S/O SUBH NATH PRASAD	Sundry Debtors	\N	\N	0.00	Unregistered
8778e85f-59ee-4907-8609-80b7b5f4dd6c	cmofl3ut6000hmjdmwqd3dziu	VIVEK SAXENA	Sundry Debtors	\N	\N	0.00	Unregistered
a760224e-f968-4679-8745-ec1de0ba4ed5	cmofl3ut6000hmjdmwqd3dziu	VIVIEK MISHRA	Sundry Debtors	\N	\N	0.00	Unregistered
6b38011c-2155-4080-85aa-429d7b8b2788	cmofl3ut6000hmjdmwqd3dziu	V K T ENTERPRISES	Sundry Debtors	09ACFPT0399G1Z7	\N	0.00	Regular
96d8033a-f67d-44f3-b674-1ffbf6f4a842	cmofl3ut6000hmjdmwqd3dziu	V K Transport Company	Sundry Creditors for Transporter	\N	\N	0.00	Unregistered
e698c585-17c1-4db1-892d-38cb69eb6a3b	cmofl3ut6000hmjdmwqd3dziu	V M INFRA TECH	Sundry Debtors	09AAPFV9231K1ZE	\N	0.00	Regular
0cb7b423-4ddf-492f-be50-3fd940f04459	cmofl3ut6000hmjdmwqd3dziu	V R CONSTRUCTION	Sundry Debtors	09BCAPS3744N1Z2	\N	0.00	Regular
03f1aba6-5a6b-44e4-8b93-babf6a45ab15	cmofl3ut6000hmjdmwqd3dziu	Wadhwan  Ware  House	Sundry Debtors	09ASQPS9989N2ZY	\N	0.00	Regular
2f4e0be2-64d1-4cc0-9858-07c170e0fefb	cmofl3ut6000hmjdmwqd3dziu	Warsi Transport	Sundry Creditors for Transporter	\N	\N	0.00	\N
55b68505-9d97-4cdc-8eb6-2231715de258	cmofl3ut6000hmjdmwqd3dziu	W.C.A.  COMPUTER EDUCATION	Sundry Debtors	09AGCPV5787H2ZN	\N	0.00	Regular
1f78dd97-8ed9-4b23-b1ab-f4224ff47860	cmofl3ut6000hmjdmwqd3dziu	YADAV TRADERS	Sundry Debtors	09ACUPY6851B1ZW	\N	0.00	Regular
c343595c-42e1-4fbd-b029-e95dd3ae20d6	cmofl3ut6000hmjdmwqd3dziu	YADUVANSHI BUILDERS	Sundry Debtors	09AAAFY6481D1ZZ	\N	0.00	Regular
292b4dbe-6756-4f76-9d2e-ae46bba432fe	cmofl3ut6000hmjdmwqd3dziu	YASHASWINI BUILDTECH	Sundry Debtors	\N	\N	0.00	\N
4f1d8398-36b1-404b-87f3-9f1e3cd79186	cmofl3ut6000hmjdmwqd3dziu	YASH DIWIDE	Sundry Debtors	\N	\N	0.00	Unregistered
39645cce-f0b0-4b3d-a971-241105511cc3	cmofl3ut6000hmjdmwqd3dziu	YASHWANT SINGH	Sundry Debtors	\N	\N	0.00	Unregistered
4d3e3a4c-eaae-4aa1-bea4-3185190b5d7e	cmofl3ut6000hmjdmwqd3dziu	YAS KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
0c2a3b24-55ee-48c2-9899-020a1df17fe7	cmofl3ut6000hmjdmwqd3dziu	YAS KUMAR SRIVASTAVA	Sundry Debtors	\N	\N	0.00	Unregistered
f427435e-7c79-4949-9fa1-b5cb75206687	cmofl3ut6000hmjdmwqd3dziu	YATI ENTERPRISES	Sundry Debtors	09BHQPB9038P3ZG	\N	0.00	Regular
ca8259de-ac0d-4557-9564-1a90aa807f00	cmofl3ut6000hmjdmwqd3dziu	YES ENTERPRISES	Sundry Debtors	09JJRPS7118L1Z2	\N	0.00	Regular
c01734ca-c55e-47a1-b05c-f717a85e23bc	cmofl3ut6000hmjdmwqd3dziu	Yes Kumar	Sundry Debtors	09JJRPS7118L1Z2	\N	0.00	Regular
8740a44f-cca7-4f56-8619-c2ca8f6440fc	cmofl3ut6000hmjdmwqd3dziu	YOGENDRA KUMAR	Sundry Debtors	\N	\N	0.00	Unregistered
644366c4-12ef-45f1-b77e-1bd80170e407	cmofl3ut6000hmjdmwqd3dziu	Yogendra Singh	Sundry Debtors	\N	\N	0.00	Unregistered
b117dbfe-32bd-416d-bda6-31379acbd006	cmofl3ut6000hmjdmwqd3dziu	Yogesh Chandra	Sundry Debtors	\N	\N	0.00	Unregistered
86283323-4903-437b-b978-0a6fb4a2a424	cmofl3ut6000hmjdmwqd3dziu	YOG INFO SOLUATIONS	Sundry Debtors	\N	\N	0.00	Regular
b3362544-9e76-461c-90de-2bcd69a2c76e	cmofl3ut6000hmjdmwqd3dziu	YOG INFOSOLUATIONSS	Sundry Creditors	09ANXPA0044N1ZO	\N	0.00	Regular
f408eb5b-7c13-4cdb-80bc-0d164bd0eeab	cmofl3ut6000hmjdmwqd3dziu	Yuraj Singh	Sundry Debtors	\N	\N	0.00	Unregistered
33608c0b-7e5c-4029-bfd1-12ff312d19ec	cmofl3ut6000hmjdmwqd3dziu	YUVARAJ SINGH	Sundry Debtors	\N	\N	0.00	\N
ca6ed18a-2520-4c37-af2f-42fbaa6fba18	cmofl3ut6000hmjdmwqd3dziu	Yuvnasha Pratap	Sundry Debtors	\N	\N	0.00	Unregistered
20d31d84-c82a-4aa8-be2a-7cfe585323f6	cmofl3ut6000hmjdmwqd3dziu	YUVRAJ CONSTRUCTION &amp; DEVELOPERS	Sundry Debtors	09AWBPK2550Q1Z5	\N	0.00	Regular
e8a71541-5294-4fdc-8904-a3436abe3898	cmofmpqxp0000tms4st6fcb8x	Exhaust Fan	FAN	\N	\N	-816.59	\N
989f6e00-77a3-46ea-9329-50f7754c4851	cmofmpqxp0000tms4st6fcb8x	New	Sundry Debtors	\N	\N	0.00	\N
401c6e69-4e8d-450c-91d8-676bb598600b	cmofmpqxp0000tms4st6fcb8x	19&apos;&apos;LED TFT HDMI IVOOMI	Fixed Assets	\N	\N	-2415.25	\N
33c88fe7-1b95-4292-83f6-7d2fee3d0dd8	cmofmpqxp0000tms4st6fcb8x	24&apos;&apos;LED GEONIX	Fixed Assets	\N	\N	-4650.00	\N
229eaa20-2a70-4549-870d-bcc4838ded49	cmofmpqxp0000tms4st6fcb8x	8 Square	PIN DROP	\N	\N	15340.00	\N
5a26a5e4-b59f-4507-bcd3-82d076f05df7	cmofmpqxp0000tms4st6fcb8x	AAROHI ENTERPRISES, CHIBRAMAU	OUT OF KANPUR	\N	\N	573.00	\N
50c60921-f412-4735-8326-d9150f800a24	cmofmpqxp0000tms4st6fcb8x	AAR PRO, KANPUR	KANPUR	\N	\N	0.00	\N
0136063e-ecc2-4b2b-b7a6-00e4e01cdba8	cmofmpqxp0000tms4st6fcb8x	ABBAS	Sundry Debtors	\N	\N	0.00	\N
e5ef64ef-2bca-4c0f-8bc3-c154b09edb1b	cmofmpqxp0000tms4st6fcb8x	ABBAS RAZA	Staff & Worker ( SALARY )	\N	\N	0.00	\N
129a23dc-13c8-450b-ada2-9af85f5d419f	cmofmpqxp0000tms4st6fcb8x	Abhay Bajaj	BAJAJ JI	\N	\N	0.00	\N
0ce1009c-3ed9-4a50-89de-328b7182f4ad	cmofmpqxp0000tms4st6fcb8x	Abhay (BISCUITS)	BISCUITS SALARY	\N	\N	0.00	\N
4cf65295-4a13-449a-8ed0-8b106954b888	cmofmpqxp0000tms4st6fcb8x	ABHAY SAHU	ANANTRAM JI	\N	\N	0.00	\N
6ba6e828-def8-48e6-855f-d1429509b989	cmofmpqxp0000tms4st6fcb8x	Abhay Traders	ANANTRAM JI	\N	\N	0.00	\N
1a5616c5-1bb3-46ff-9ba6-6419c2b151eb	cmofmpqxp0000tms4st6fcb8x	ABHISHEKH BAJAJ	BAJAJ JI	\N	\N	0.00	\N
2e2994be-3f33-4191-b8d3-94dd7ef30271	cmofmpqxp0000tms4st6fcb8x	ABHISHEKH SAHU	ANANTRAM JI	\N	\N	0.00	\N
e64a6816-11b4-4da6-b445-1bd20546c6a1	cmofmpqxp0000tms4st6fcb8x	Abhishek Kumar , SAHAR	DILIP PANDYE	\N	\N	0.00	\N
ae60d042-9e27-48dd-b53b-78ac1d2b92b6	cmofmpqxp0000tms4st6fcb8x	Abhishek Kuram ( 08/1/2026)	Staff & Worker ( SALARY )	\N	\N	0.00	\N
e3c47111-e7e7-4a1c-9319-c40b2b8a0113	cmofmpqxp0000tms4st6fcb8x	AC 1.5T ESTRELLA EX 3*WRAC	Fixed Assets	\N	\N	-18753.76	\N
51e0620f-aac3-4c44-b4ef-6259de0034e5	cmofmpqxp0000tms4st6fcb8x	Ach Prudent	Investments	\N	\N	0.00	\N
f38434ee-2e93-438d-a01e-3959644b2c66	cmofmpqxp0000tms4st6fcb8x	ACTIVA ( UP78DZ2077 ) INDURANCE	INSURANCE	\N	\N	0.00	\N
88270c49-51f1-4772-96ec-d09861596413	cmofmpqxp0000tms4st6fcb8x	ADHUNIK STATIONERS &amp; SUPPLIERS	Sundry Creditors -Exp	\N	\N	0.00	\N
dc9e7246-f92d-4171-ba7d-a0329b3a6190	cmofmpqxp0000tms4st6fcb8x	ADVANCE TAX ( 2024-2025 )	Loans & Advances (Asset)	\N	\N	0.00	\N
63d87c15-9938-4674-b652-3539f17dca68	cmofmpqxp0000tms4st6fcb8x	ADVERTISEMENT EXP	Advertisement	\N	\N	0.00	\N
361ea7e2-130f-4c4d-93ad-66e28e9e8e92	cmofmpqxp0000tms4st6fcb8x	ADVERTISEMENT EXP @5%	Advertisement	\N	\N	0.00	\N
da9cbc85-c2f9-4a08-8ca2-c3d551740a3a	cmofmpqxp0000tms4st6fcb8x	ADVERTISING EXP @18%	Advertisement	\N	\N	0.00	\N
6f7e8cf5-1175-4358-b605-fc076acdff8c	cmofmpqxp0000tms4st6fcb8x	Afak Thekedar ( Gattu Controctor ) 23.10.21	WAGES ( CONTRACTOR )	\N	\N	233729.00	\N
15b78d6c-8ff6-43b1-ab0d-0d3008c6271f	cmofmpqxp0000tms4st6fcb8x	Aggarwal Enterprises	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
2f9b41a7-d336-43f7-a29d-bbbf473ec7cd	cmofmpqxp0000tms4st6fcb8x	A G Marketing	Sundry Creditors -Exp	\N	\N	0.00	\N
51711570-503a-41bf-bb80-0a76bfb8626d	cmofmpqxp0000tms4st6fcb8x	AGRAWAL TRADING CO.	Sundry Creditors	\N	\N	0.00	\N
5e4c85c7-a3f5-4d25-8b23-2880e5468fbd	cmofmpqxp0000tms4st6fcb8x	AIR CONDITIONER	Fixed Assets	\N	\N	-58935.86	\N
8fda963f-a050-4663-8ac2-cfbb2875fc45	cmofmpqxp0000tms4st6fcb8x	AIR COOLED WATER CHILLER	Fixed Assets	\N	\N	0.00	\N
ced3aa84-afb3-4112-9614-e699b67aecbb	cmofmpqxp0000tms4st6fcb8x	AIR VENTILATOR	Fixed Assets	\N	\N	-10500.00	\N
7335e862-dbc7-4f84-8156-259035b2b8e2	cmofmpqxp0000tms4st6fcb8x	AJAY BAJAJ	BAJAJ JI NEW	\N	\N	0.00	\N
e43a4cf5-7658-439c-a41a-a13615e9386c	cmofmpqxp0000tms4st6fcb8x	AJAY BAJPAI	BAJAJ JI	\N	\N	0.00	\N
dc83b122-c248-4ae3-ac23-5556ba952d60	cmofmpqxp0000tms4st6fcb8x	AJAY (BISCUITS WORKER)	BISCUITS SALARY	\N	\N	0.00	\N
df124abf-00ea-4750-a603-5e737ae929fb	cmofmpqxp0000tms4st6fcb8x	AJAY E-Rikshaw	FREIGHT OUTWORD	\N	\N	0.00	\N
177c6578-d857-43c1-82d9-46e71dc59d4d	cmofmpqxp0000tms4st6fcb8x	Ajay Gajwani(Commission)	Sundry Creditors	\N	\N	25500.00	\N
96557274-99fb-4803-9ed7-b5759253d73c	cmofmpqxp0000tms4st6fcb8x	Ajay Gupta, BALAJI	BALAJI TRADER( YASHODA NAGAR )	\N	\N	0.00	\N
992fe7a1-48eb-4ea8-9e1c-47775ac0324e	cmofmpqxp0000tms4st6fcb8x	AJAY JI - CHILLER	CHILLER	\N	\N	0.00	\N
731e0730-6466-49d4-8246-9210d9f7734f	cmofmpqxp0000tms4st6fcb8x	AJAY KUMAR ( BAJAJ )	BAJAJ JI	\N	\N	0.00	\N
6f7659fd-0ba1-481e-a1ff-819b6a985bbd	cmofmpqxp0000tms4st6fcb8x	AJAY  KUMAR BHARTI TOUR	Sundry Creditors(Tour)	\N	\N	0.00	\N
650105d8-f0f6-4cd5-9cc0-69205b9fa66f	cmofmpqxp0000tms4st6fcb8x	AJAY KUMAR SHUKLA ( TOUR )	Sundry Creditors(Tour)	\N	\N	0.00	\N
dee4de22-c74f-4d59-b73c-9298be8c4592	cmofmpqxp0000tms4st6fcb8x	AJAY SAHU	ANANTRAM JI	\N	\N	0.00	\N
93ea20c3-da4c-4053-9073-149b86e665ca	cmofmpqxp0000tms4st6fcb8x	AJAY SINGH , KAHINJARI	DILIP PANDYE	\N	\N	0.00	\N
23310be1-7d1d-49b7-9bc5-d7dc5e3eb609	cmofmpqxp0000tms4st6fcb8x	AJEET SAHU	ANANTRAM JI	\N	\N	0.00	\N
37b2ee57-bdd0-44ad-b253-31bc85335c2f	cmofmpqxp0000tms4st6fcb8x	AKASH BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
ab307a97-c1f8-4da6-86a2-13dd6e203ba1	cmofmpqxp0000tms4st6fcb8x	AKASH - SIPAHI	Sipahi	\N	\N	0.00	\N
e1d35679-3c86-42b3-a2b5-f2b969d70ab0	cmofmpqxp0000tms4st6fcb8x	AKSHAY TRADERS-SATNA	SATNA	\N	\N	0.00	\N
d74efbd5-d7d7-40e1-87c1-f9f1efb30102	cmofmpqxp0000tms4st6fcb8x	Almunium Bhagauna	Fixed Assets	\N	\N	-5012.70	\N
024b3d56-a564-4f0c-b8d0-9fdcb84651d2	cmofmpqxp0000tms4st6fcb8x	Alok Bajaj	BAJAJ JI	\N	\N	0.00	\N
60d219c1-479e-49bd-b3b8-409eb27f0ad7	cmofmpqxp0000tms4st6fcb8x	ALOK BAJPAI	BAJAJ JI	\N	\N	0.00	\N
2f7dcf8c-96a8-446e-9042-a7626a49182e	cmofmpqxp0000tms4st6fcb8x	ALOK NAMKEEN Nayaganj	AMAR SONKAR	\N	\N	0.00	\N
324b158c-00f6-460d-b499-76099d3f6422	cmofmpqxp0000tms4st6fcb8x	Alok Sahu	ANANTRAM JI	\N	\N	0.00	\N
d374d008-c9dd-465e-bf5a-c68075131251	cmofmpqxp0000tms4st6fcb8x	ALOK STORE, NAYA GANJ	AMAR SONKAR	\N	\N	0.00	\N
446123cc-0359-47d6-b7ca-4a362402b919	cmofmpqxp0000tms4st6fcb8x	ALPHABETS	Fixed Assets	\N	\N	0.00	\N
6fbcb5cf-da15-4f82-95b1-a44aa1a9778a	cmofmpqxp0000tms4st6fcb8x	Aman Bajaj	BAJAJ JI	\N	\N	0.00	\N
368a69ac-1cf9-442a-8fe3-b2b2d8f761a1	cmofmpqxp0000tms4st6fcb8x	AMAN BAJPAI	BAJAJ JI	\N	\N	0.00	\N
b0657197-cb1d-4997-8690-e0817630dbae	cmofmpqxp0000tms4st6fcb8x	AMAN BEKERY	Sundry Creditors -Exp	\N	\N	0.00	\N
c78e94ee-ff89-411d-8454-ca0c68c46356	cmofmpqxp0000tms4st6fcb8x	AMAN SAHU	ANANTRAM JI	\N	\N	0.00	\N
9c13b9b6-8f12-4b1a-b135-0e39c25c70fc	cmofmpqxp0000tms4st6fcb8x	AMARA RAJA POWER ZONE BATTERY PZ-NTPZ 15000	Fixed Assets	\N	\N	-10169.49	\N
d070876d-b8c7-488a-9daf-32cf85a8a797	cmofmpqxp0000tms4st6fcb8x	AMAR BAJAJ	BAJAJ JI	\N	\N	0.00	\N
f1c4bddb-8cbd-433a-8f28-437de47c33af	cmofmpqxp0000tms4st6fcb8x	AMAR BAJPAI	BAJAJ JI	\N	\N	0.00	\N
8b6babbf-35d5-4845-989a-16da65698b47	cmofmpqxp0000tms4st6fcb8x	Amar Sahu	ANANTRAM JI	\N	\N	0.00	\N
b4ee1f27-de8f-4e9b-acc3-b60ac9cdb45c	cmofmpqxp0000tms4st6fcb8x	AMAR SONKAR	AMAR SONKAR	\N	\N	2749.00	\N
f2adea83-d2c8-41e5-930a-c5c87bebd173	cmofmpqxp0000tms4st6fcb8x	AMAR SONKER STAFF	Staff & Worker ( SALARY )	\N	\N	18618.00	\N
9ceddb10-7141-4e38-9750-2df9b4482048	cmofmpqxp0000tms4st6fcb8x	AMAR STORE, BASTI	OUT OF KANPUR	\N	\N	0.00	\N
0507ae7f-ea84-4fa9-a3e5-3da4e8de2bd7	cmofmpqxp0000tms4st6fcb8x	AMAR TECH ENGINEERS	Sundry Creditors -Exp	\N	\N	-100000.00	\N
89794896-e659-4ccd-be14-343ec835120c	cmofmpqxp0000tms4st6fcb8x	AMIT BAJAJ	BAJAJ JI	\N	\N	0.00	\N
b7834aa3-344f-40cb-9bc7-b4230e3de330	cmofmpqxp0000tms4st6fcb8x	AMIT BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
494a78af-e49c-4919-ba4d-2e9ff3c0cb03	cmofmpqxp0000tms4st6fcb8x	AMIT ENTERPRISES	Sundry Debtors	\N	\N	0.00	\N
dc2846fd-a2eb-4658-8692-ffdb1af0e71b	cmofmpqxp0000tms4st6fcb8x	AMIT GHAI ( K.P.A.)	Sundry Debtors	\N	\N	-635.00	\N
bcc2a72c-270d-47e5-acc3-244b7289bd77	cmofmpqxp0000tms4st6fcb8x	AMIT KUMAR FAIZABAD	OUT OF KANPUR	\N	\N	-182678.00	\N
f76f1904-ea37-4bd7-987b-d29aa70c660c	cmofmpqxp0000tms4st6fcb8x	Amit Kumar (Power Factor)	Sundry Creditors -Exp	\N	\N	0.00	\N
9e7ae51e-a87c-439d-95b6-20e95f4f6aaa	cmofmpqxp0000tms4st6fcb8x	AMIT SAHU	ANANTRAM JI	\N	\N	0.00	\N
27b071c7-5504-4e7e-b9f2-8d363a5bbafe	cmofmpqxp0000tms4st6fcb8x	AMIT SWEAPER	Staff & Worker ( SALARY )	\N	\N	0.00	\N
79379e82-da50-4df2-b86d-240428fd43f4	cmofmpqxp0000tms4st6fcb8x	Anandeshwer &amp; Company	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
a16e1e6e-0e6a-47c8-96ff-ec5117d596b0	cmofmpqxp0000tms4st6fcb8x	ANAND LOADING STAFF	Sundry Debtors	\N	\N	0.00	\N
732a1c9f-3df4-4573-8994-5b3d50866173	cmofmpqxp0000tms4st6fcb8x	Anand ram and sons	Sundry Debtors	\N	\N	0.00	\N
9cae1e9f-2845-4ca3-859c-8749c306548e	cmofmpqxp0000tms4st6fcb8x	ANAND SAHU	ANANTRAM JI	\N	\N	0.00	\N
42019677-7e2a-447c-8d98-4273a7d099a6	cmofmpqxp0000tms4st6fcb8x	Anant Ram Ji ( Salary )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
28af035a-5a3b-43ae-a76e-6d8c30d890ec	cmofmpqxp0000tms4st6fcb8x	ANANT RAM SHAU	ANANTRAM JI	\N	\N	0.00	\N
fee055aa-b643-4ee3-845a-6955b440f033	cmofmpqxp0000tms4st6fcb8x	ANANT SAHU	ANANTRAM JI	\N	\N	0.00	\N
506ee634-82ce-4eee-9b2a-5e56490539cd	cmofmpqxp0000tms4st6fcb8x	ANIL DIXIT, BILHOR	DILIP PANDYE	\N	\N	0.00	\N
ab2a2c5d-8dbe-45bd-961e-ddfc5b7eec0d	cmofmpqxp0000tms4st6fcb8x	ANIL NAMKEEN BHANDAR	ANANTRAM JI	\N	\N	0.00	\N
76d39575-0e99-4738-9b98-87cf379fb0d5	cmofmpqxp0000tms4st6fcb8x	ANIL SAHU	ANANTRAM JI	\N	\N	0.00	\N
25ec36f1-5821-499e-8d81-c0cb95fc9470	cmofmpqxp0000tms4st6fcb8x	ANIL STORE, RAIL BAJAR	AMAR SONKAR	\N	\N	0.00	\N
2c6c50ce-c623-4985-9d6a-4fff6c477a44	cmofmpqxp0000tms4st6fcb8x	ANITA PANDEY ( 15/10/24 )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
c408dcb3-c234-4717-9b74-d34fb2eb3706	cmofmpqxp0000tms4st6fcb8x	ANJEET BISCUITS	Sundry Debtors	\N	\N	0.00	\N
5b0346a9-6b18-48b7-9e87-6508c54c80f6	cmofmpqxp0000tms4st6fcb8x	Anju- 2 Packing Staff	Staff & Worker ( SALARY )	\N	\N	0.00	\N
e9e8450f-5379-40a4-ba4b-9b446f6b33bb	cmofmpqxp0000tms4st6fcb8x	Anju Packing Staff	Staff & Worker ( SALARY )	\N	\N	0.00	\N
19ead89f-8601-460b-ab48-51b7d3f68c03	cmofmpqxp0000tms4st6fcb8x	ANKIT BAJPAI	BAJAJ JI	\N	\N	0.00	\N
c417235b-4e00-46cd-8231-715c533770e5	cmofmpqxp0000tms4st6fcb8x	ANKIT BISCUITS	BISCUITS SALARY	\N	\N	0.00	\N
a4c4e3ba-92bb-4f94-b713-b868f8e32a49	cmofmpqxp0000tms4st6fcb8x	Ankit Confectionery Store	ANANTRAM JI	\N	\N	0.00	\N
a2657d16-0b38-4113-b871-c17f894024bb	cmofmpqxp0000tms4st6fcb8x	ANKIT STORE  Nayaganj	AMAR SONKAR	\N	\N	0.00	\N
894363e7-e387-4feb-b02e-54db2efe85a4	cmofmpqxp0000tms4st6fcb8x	ANKIT TRADERS	ANANTRAM JI	\N	\N	0.00	\N
a4197e38-ec03-4b52-933d-a2d8b760ecf3	cmofmpqxp0000tms4st6fcb8x	ANKUR BAJAJ	BAJAJ JI	\N	\N	0.00	\N
e403f81a-bed8-4e6e-8353-8b34f772c158	cmofmpqxp0000tms4st6fcb8x	Ankur Bajpai	BAJAJ JI	\N	\N	0.00	\N
9426081f-5fe9-4b59-a547-15030df63079	cmofmpqxp0000tms4st6fcb8x	ANKUR KRISHNA AGENCIES	Sundry Creditors -Exp	\N	\N	0.00	\N
5bb4361c-161b-45bb-949a-19310df5836c	cmofmpqxp0000tms4st6fcb8x	Anmol Bajpai	BAJAJ JI	\N	\N	0.00	\N
5a0c73c1-3b98-4dda-9ce8-fae6cc44bc0e	cmofmpqxp0000tms4st6fcb8x	ANMOL KHANNA , BIJNOR	Ashutosh Ji	\N	\N	0.00	\N
80bdfaf5-9918-481e-8fc2-2069b757b168	cmofmpqxp0000tms4st6fcb8x	ANMOL SAHU	ANANTRAM JI	\N	\N	0.00	\N
96009068-1802-466a-b20c-c0c03fd9abf4	cmofmpqxp0000tms4st6fcb8x	ANURAG PORWAL, DIBIYAPUR	DIBIYAPUR	\N	\N	0.00	\N
73ae34ad-a1e0-46d9-a6ae-5f7c87032a88	cmofmpqxp0000tms4st6fcb8x	ANURAG SAHU	ANANTRAM JI	\N	\N	0.00	\N
19737c47-c9ee-4f4e-bd62-827031a16e01	cmofmpqxp0000tms4st6fcb8x	ANUSHKA TRADING COMPANY(DARSHANPURWA)	BAJAJ JI	\N	\N	0.00	\N
fc88b27c-339e-44af-a8ef-00468d299f83	cmofmpqxp0000tms4st6fcb8x	AONE BAKERY MACHINERY	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
62e84c57-4b77-4017-98d9-1779bbdad5e0	cmofmpqxp0000tms4st6fcb8x	AQSA MOTORS &amp; AUTO ELECTRIC	Sundry Creditors -Exp	\N	\N	0.00	\N
9b90f1a3-7b0e-4c5e-8970-e474e0349436	cmofmpqxp0000tms4st6fcb8x	ARBISH TRADERS	BAJAJ JI	\N	\N	0.00	\N
ef60f9aa-cdd3-4848-9196-173045193b58	cmofmpqxp0000tms4st6fcb8x	Arif Shamshad Khan, Akhbarpur	Sundry Debtors	\N	\N	0.00	\N
5e889f0a-3ecf-47f5-bf5f-d0c01bc517df	cmofmpqxp0000tms4st6fcb8x	ARJUN BAJAJ	BAJAJ JI	\N	\N	0.00	\N
74b5b571-94e9-43a0-a78f-9b0e301a4b1e	cmofmpqxp0000tms4st6fcb8x	ARPIT PACKAGING	CREDITORS ( DIPESH JI )	\N	\N	13753.00	\N
45862bc8-0ffb-4c4b-a279-2cac344c88ac	cmofmpqxp0000tms4st6fcb8x	AR SAHU	ANANTRAM JI	\N	\N	0.00	\N
20ea26e5-97c2-49a6-9fe0-d8c5f5c39b12	cmofmpqxp0000tms4st6fcb8x	ARSHAD STORE, RAIL BAZAR	AMAR SONKAR	\N	\N	0.00	\N
0b5ae870-5be4-4b5d-9dd2-1e709e983006	cmofmpqxp0000tms4st6fcb8x	ARSHLAN - SIPAHI	Sipahi	\N	\N	0.00	\N
6e44e26a-00e9-477d-8fa3-77fa28306593	cmofmpqxp0000tms4st6fcb8x	AR STORE, MEERPUR	AMAR SONKAR	\N	\N	-640.00	\N
537562ba-6354-466b-ab34-9097ff3de640	cmofmpqxp0000tms4st6fcb8x	ARUN KUMAR	Staff & Worker ( SALARY )	\N	\N	0.00	\N
c219acba-2bfa-43cc-a3f6-c41511c6287a	cmofmpqxp0000tms4st6fcb8x	ARUN PACKING 6 FEB 2026	Staff & Worker ( SALARY )	\N	\N	0.00	\N
63021a5d-5c80-4550-8985-4e6d83b97725	cmofmpqxp0000tms4st6fcb8x	Arun Rega Bakery Machineries P Ltd	Sundry Creditors	\N	\N	0.00	\N
258a7e1b-e692-49a9-bfef-b806d0f0de86	cmofmpqxp0000tms4st6fcb8x	ARYAN ENTERPRISES, SAFIPUR	Ashutosh Ji	\N	\N	0.00	\N
e615f68c-79ec-4138-9dc5-f5996f4847db	cmofmpqxp0000tms4st6fcb8x	ASHIRWAD TECHNOLOGY	Sundry Creditors	\N	\N	0.00	\N
25da65e8-45b4-43cc-943c-1913389c1d54	cmofmpqxp0000tms4st6fcb8x	ASHISH GUPTA, BINDKI	OUT OF KANPUR	\N	\N	5033.00	\N
338967c0-b57e-478a-b153-fe98c0a7f44c	cmofmpqxp0000tms4st6fcb8x	ASHOK BAJAJ	BAJAJ JI	\N	\N	0.00	\N
79870514-5bc8-4525-86d6-253c166a4405	cmofmpqxp0000tms4st6fcb8x	ASHOK SAHU	ANANTRAM JI	\N	\N	0.00	\N
cb917d53-3813-4e28-af5d-010dca2b60e1	cmofmpqxp0000tms4st6fcb8x	ASHU BAJAJ	BAJAJ JI	\N	\N	0.00	\N
10e283e2-6bb8-4323-be06-611b41c5d9b4	cmofmpqxp0000tms4st6fcb8x	ASHUTOSH BAJAJ	BAJAJ JI	\N	\N	0.00	\N
bd86d2f1-d6c2-4068-bf32-0501d103662b	cmofmpqxp0000tms4st6fcb8x	ASHUTOSH BHAT(Ta Da Exp)	Sundry Creditors(Tour)	\N	\N	0.00	\N
a0a66c52-34ec-4362-a12e-4aedc1691b1c	cmofmpqxp0000tms4st6fcb8x	ASHUTOSH BHATT ( SALARY )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
4e4b7d45-5dba-4d49-ac86-6288abd01515	cmofmpqxp0000tms4st6fcb8x	Asiyan Bekrs, Fatehpur	Gaurav, LUCKNOW	\N	\N	5184.00	\N
51acb3e4-0973-45ce-a321-f287fc9cb49d	cmofmpqxp0000tms4st6fcb8x	ATHRAV TRADERS	KANPUR	\N	\N	0.00	\N
680aea1b-8dbe-49df-92e0-ab8766c5a748	cmofmpqxp0000tms4st6fcb8x	ATTA BISCUITS MACHINE	Fixed Assets	\N	\N	-6800.00	\N
140e8617-375c-4209-ac90-986f3d742511	cmofmpqxp0000tms4st6fcb8x	Atul Sahu	ANANTRAM JI	\N	\N	0.00	\N
594a2140-6f6f-4a9b-b3ca-88f3becb75f5	cmofmpqxp0000tms4st6fcb8x	ATUL TRADERS	ANANTRAM JI	\N	\N	0.00	\N
045b87b7-a255-41dc-a218-ea6498f5cd6d	cmofmpqxp0000tms4st6fcb8x	ATUL ( Welding Work )	Sundry Creditors -Exp	\N	\N	-3000.00	\N
222e74e4-70a6-495e-92b1-cdd0a03e5832	cmofmpqxp0000tms4st6fcb8x	Audit Fee	Indirect Expenses	\N	\N	0.00	\N
e26e10f7-9370-42d5-bd02-a7f96e9462c2	cmofmpqxp0000tms4st6fcb8x	Audit Fee Payable	Provisions	\N	\N	15000.00	\N
b4994f29-3fda-4d3c-9f8e-2ee728dc1681	cmofmpqxp0000tms4st6fcb8x	Automatic Gas Fired Rotary Rach OVON	Fixed Assets	\N	\N	-250617.19	\N
861c4b99-3d97-4107-ac89-fcfaef54dd6b	cmofmpqxp0000tms4st6fcb8x	AVIRAL SAHU	ANANTRAM JI	\N	\N	0.00	\N
8a19361d-7cd5-488c-92eb-37ff21a266b3	cmofmpqxp0000tms4st6fcb8x	AWADH ELECTRICALS &amp;MACHINES	Sundry Creditors	\N	\N	0.00	\N
a8dd6c7e-8974-484c-86eb-803fd8872aa3	cmofmpqxp0000tms4st6fcb8x	AWADHESH ( GILI CUTTING )	SCRAP ( DEBTORS )	\N	\N	0.00	\N
e5a596a2-f1e2-4c64-be0d-3e6ec47ab405	cmofmpqxp0000tms4st6fcb8x	AWADHESH-KUMAR-JAISWAL (CHIRAI-BASTI)	Shivoham Shukla Parties	\N	\N	0.00	\N
46f1a3b3-846c-4956-ae86-26749eea3d9b	cmofmpqxp0000tms4st6fcb8x	AXIS MUTURE FUND	Investments	\N	\N	0.00	\N
33aed42d-a935-46f0-ae33-91c4081e1b7c	cmofmpqxp0000tms4st6fcb8x	AYUSH BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
a0151091-4441-4bcb-bd5e-2e43c0265eb3	cmofmpqxp0000tms4st6fcb8x	AYUSH ENTERPRISES	Sundry Creditors	\N	\N	0.00	\N
c1d1e67a-b0b3-4cfd-a4c4-d6a97e07a58f	cmofmpqxp0000tms4st6fcb8x	AZAD AHMAD-MAUDAHA	Ashutosh Ji	\N	\N	0.00	\N
f7785fc1-1970-4bf7-95ad-b1c694822a20	cmofmpqxp0000tms4st6fcb8x	AZAD  |( THEKEDAR ) 80 GM	WAGES ( CONTRACTOR )	\N	\N	-283316.00	\N
30540045-a1f5-44b8-b947-25c78fa46adb	cmofmpqxp0000tms4st6fcb8x	BABA PACKAGING	CREDITORS ( DIPESH JI )	\N	\N	51906.00	\N
2a570a3f-b306-4b28-9e74-0f761dd52fc3	cmofmpqxp0000tms4st6fcb8x	BABBAN ( LOADER )	FREIGHT OUTWORD	\N	\N	0.00	\N
a468872c-983f-4d31-9032-7d4e409c03e4	cmofmpqxp0000tms4st6fcb8x	BABLEE PACKING	Staff & Worker ( SALARY )	\N	\N	0.00	\N
427e92ed-07fa-4f3e-a4e2-74151e7403b0	cmofmpqxp0000tms4st6fcb8x	BABLU ( JEERA )	WAGES ( CONTRACTOR )	\N	\N	61980.00	\N
15f8c71a-37c7-4210-9efc-724f44bc6fc1	cmofmpqxp0000tms4st6fcb8x	Bablu Sahu	ANANTRAM JI	\N	\N	0.00	\N
7f879f6d-15a3-4afe-a466-aa3a967d72df	cmofmpqxp0000tms4st6fcb8x	BABLU TEA, RAIL BAJAR	AMAR SONKAR	\N	\N	0.00	\N
07f19329-bae0-4854-a3af-4dd1b5ec20f8	cmofmpqxp0000tms4st6fcb8x	Babuddin-Ghatampur	OUT OF KANPUR	\N	\N	0.00	\N
d66d47ef-f39b-441c-9d70-22d7cc2232a7	cmofmpqxp0000tms4st6fcb8x	BAD DEBTS	Indirect Expenses	\N	\N	0.00	\N
75491c6c-e1fb-4ae0-adac-80bb84063930	cmofmpqxp0000tms4st6fcb8x	BADE BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
e0c9a6b1-447b-4d1c-9a3e-1d90fc86c7dc	cmofmpqxp0000tms4st6fcb8x	BADSHAH - SIPAHI	Sipahi	\N	\N	0.00	\N
5dba595a-5fbb-4da5-b12b-c30208fc40bd	cmofmpqxp0000tms4st6fcb8x	BAI-LABS LLP	Sundry Creditors	\N	\N	0.00	\N
2ed4a477-8dda-452f-88d4-cff1bc90c4d5	cmofmpqxp0000tms4st6fcb8x	BAJAJ AGENCY	BAJAJ JI	\N	\N	0.00	\N
70ed1f61-a29a-4726-97f3-df06d9141c0e	cmofmpqxp0000tms4st6fcb8x	BAJAJ ALLIANZ GIC LTD	Sundry Creditors -Exp	\N	\N	1.00	\N
d65c7208-62d9-4bd1-ab0e-97b779cc2a57	cmofmpqxp0000tms4st6fcb8x	Bajaj Associats	BAJAJ JI	\N	\N	0.00	\N
3f3cd3c0-e3cd-451d-934a-b548d2a73f20	cmofmpqxp0000tms4st6fcb8x	Bajaj &amp; Co	BAJAJ JI	\N	\N	0.00	\N
e3bee680-a991-45df-93b4-1bcf4086722d	cmofmpqxp0000tms4st6fcb8x	Bajaj Enterprises	BAJAJ JI	\N	\N	0.00	\N
3ef360c0-b325-482f-ae4e-e24ecf0554f8	cmofmpqxp0000tms4st6fcb8x	BAJAJ FINSERV FLEXI CAP FUND ( 7144403992 ) 29/7/24	SIP	\N	\N	0.00	\N
fa32f2f9-7e34-4248-8cd7-9f5a1dc3b438	cmofmpqxp0000tms4st6fcb8x	BAJAJ FINSERV HEALTHCARE FUND ( 7997121895 ) 3/1/25	SIP	\N	\N	0.00	\N
eb5ada84-9eee-4c57-ae7d-69891bd0a118	cmofmpqxp0000tms4st6fcb8x	BAJAJ JI ( 90 GM )	BAJAJ JI	\N	\N	0.00	\N
c5420859-0ad9-4c47-a4fa-d4427ef68549	cmofmpqxp0000tms4st6fcb8x	Bajaj Ji ( ADVENCE )	BAJAJ JI	\N	\N	0.00	\N
c5f4390c-457a-4cc7-90da-efa153d49614	cmofmpqxp0000tms4st6fcb8x	Bajaj &amp; Sons	BAJAJ JI	\N	\N	0.00	\N
8a49c7b6-2a6f-46a9-a351-7472eb9c34a4	cmofmpqxp0000tms4st6fcb8x	BAJAJ STORE	BAJAJ JI	\N	\N	0.00	\N
6f714b35-9fa3-45f8-b639-f2fe236d38a8	cmofmpqxp0000tms4st6fcb8x	BAJAJ TRADERS	BAJAJ JI	\N	\N	0.00	\N
87e07641-d0ee-4187-a7bb-3f82bcbe4206	cmofmpqxp0000tms4st6fcb8x	BAKING TRAY 1INCH (BISCUITS)	Fixed Assets	\N	\N	-15031.20	\N
93ddca20-9cb5-4dce-ba4c-962feb526662	cmofmpqxp0000tms4st6fcb8x	Bala Ji Bakers	ANANTRAM JI	\N	\N	0.00	\N
0474be62-c2a7-43e7-af8c-65db39ff270e	cmofmpqxp0000tms4st6fcb8x	Balaji Securwaz	Sundry Creditors -Exp	\N	\N	37278.00	\N
75e64bd2-4972-43cb-abb6-5098dd372d30	cmofmpqxp0000tms4st6fcb8x	Balram Sweaper	Staff & Worker ( SALARY )	\N	\N	0.00	\N
22f79adb-4c2e-4b07-9c7d-a87f83033439	cmofmpqxp0000tms4st6fcb8x	Bank Charges	BANK CHARGES	\N	\N	0.00	\N
d3cbf95b-d777-4a38-a72d-c9cbc54f9b35	cmofmpqxp0000tms4st6fcb8x	Bank Charges ( SBI )	BANK CHARGES	\N	\N	0.00	\N
f12ecd1f-b366-4c4e-a59b-90ab662e5b20	cmofmpqxp0000tms4st6fcb8x	Bank(Interest-SD)	Bank Interest	\N	\N	0.00	\N
8626fab8-bf7e-4a5e-9c4d-3962d73d6c93	cmofmpqxp0000tms4st6fcb8x	BANSALSUPER STORE	KAVITA	\N	\N	0.00	\N
7a7cb6c7-31c7-4276-8e37-937de50ea87c	cmofmpqxp0000tms4st6fcb8x	BANSI JI BILL	Sundry Debtors	\N	\N	0.00	\N
67769219-a28f-4a05-8682-57076039f96e	cmofmpqxp0000tms4st6fcb8x	Bansi Ji (Staff)	Staff & Worker ( SALARY )	\N	\N	0.00	\N
1d34175b-2b7a-435d-93d9-a92ba289bc37	cmofmpqxp0000tms4st6fcb8x	BANSI LAL JI	Staff & Worker ( SALARY )	\N	\N	0.00	\N
86cab83d-96a4-441d-add4-0c45587a6ee9	cmofmpqxp0000tms4st6fcb8x	Bansi Sahu	ANANTRAM JI	\N	\N	0.00	\N
d5134e2f-bd67-44ea-8348-929263f771c5	cmofmpqxp0000tms4st6fcb8x	Batham Sales	VIJAY BATHAM	\N	\N	0.00	\N
687ebf33-1783-4e6c-830a-23427c2a57dc	cmofmpqxp0000tms4st6fcb8x	Battry 12 Volt IM- 1900	Fixed Assets	\N	\N	-6715.17	\N
a9426f64-75d9-4530-b5b8-5fcef581f8ff	cmofmpqxp0000tms4st6fcb8x	BELTING ENGINEERING WORKS	Sundry Creditors	\N	\N	0.00	\N
0d01ce85-204b-4b9c-9337-e64f09077fbe	cmofmpqxp0000tms4st6fcb8x	BHAGCHAND BROTHERS	BAJAJ JI	\N	\N	0.00	\N
7eaae4ed-7a3b-49b7-895d-b8640e12a28f	cmofmpqxp0000tms4st6fcb8x	Bharat Enterprises	Sundry Creditors -Exp	\N	\N	0.00	\N
6d43df24-0e19-4c88-bbc0-08b724e5e474	cmofmpqxp0000tms4st6fcb8x	BHARAT NAMKEEN AND BESAN	Sundry Creditors	\N	\N	0.00	\N
7656f5c2-4f42-40fe-aca6-c421a8a8c2c4	cmofmpqxp0000tms4st6fcb8x	BHARAT NAMKEEN &amp; BESAN	Sundry Creditors	\N	\N	0.00	\N
2acee037-c493-4e4f-a9bc-5c65bade7917	cmofmpqxp0000tms4st6fcb8x	BHARAT STORE,CANAL ROAD	AMAR SONKAR	\N	\N	-3100.00	\N
a2134216-2b02-4a05-bf79-95b47222a20c	cmofmpqxp0000tms4st6fcb8x	Bhola Kirana Bhandar	Sundry Creditors	\N	\N	0.00	\N
7498e8a6-0f2c-4f8f-b18f-91b112b3fc6f	cmofmpqxp0000tms4st6fcb8x	Bhuvanesh &amp; Shyam   C A	Sundry Creditors	\N	\N	72000.00	\N
03ce2fcc-be52-430c-8aa5-c052e3ef57e9	cmofmpqxp0000tms4st6fcb8x	BIHARIRAMCHANDANI	Sundry Creditors(Tour)	\N	\N	0.00	\N
d4876542-7dd9-403b-8957-ac381537fe09	cmofmpqxp0000tms4st6fcb8x	Birendra Bajaj	BAJAJ JI	\N	\N	0.00	\N
77761783-8340-4a7b-9b32-52918c573e1d	cmofmpqxp0000tms4st6fcb8x	BIRENDRA SAHU	ANANTRAM JI	\N	\N	0.00	\N
5a490113-9c28-4fb3-88e5-20135fc06a1b	cmofmpqxp0000tms4st6fcb8x	Birendra Shukla  Staff	Staff & Worker ( SALARY )	\N	\N	0.00	\N
d95bcb8c-bc57-4b70-a734-ab34098140e3	cmofmpqxp0000tms4st6fcb8x	BISCUIT BAKING TROLLY	Fixed Assets	\N	\N	-50000.00	\N
b40c6ef9-6a4d-4a5d-89cf-e04dc305de1c	cmofmpqxp0000tms4st6fcb8x	BISCUITS PACKING MACHINE	Fixed Assets	\N	\N	-150000.00	\N
454c0bfe-fa9e-4c19-b37e-b4c5a3831d5b	cmofmpqxp0000tms4st6fcb8x	BISCUITS PACKING MACHINE (B.R)	Fixed Assets	\N	\N	-400000.00	\N
adf2d832-7a38-4360-83f9-ebf9445d0759	cmofmpqxp0000tms4st6fcb8x	Blink Commerce Private Limited	Sundry Debtors	\N	\N	-3149.80	\N
2bbe1e7c-f9d7-45e3-92a9-ce6070123735	cmofmpqxp0000tms4st6fcb8x	Blink Commerce Private Limited, HARYANA	Sundry Creditors -Exp	\N	\N	29500.00	\N
5363eace-0a5f-48c7-aa98-d56e6e2ec55c	cmofmpqxp0000tms4st6fcb8x	Boby Gas Weldor	Repair and Maintanence	\N	\N	0.00	\N
30a4d7ab-7422-4fe6-a3c2-8ad3c89ed722	cmofmpqxp0000tms4st6fcb8x	Brendra Sahu	ANANTRAM JI	\N	\N	0.00	\N
d0ec85b0-8a86-4a44-834c-e93edecd8fb8	cmofmpqxp0000tms4st6fcb8x	BRENDRA SHUKLA STAFF	Staff & Worker ( SALARY )	\N	\N	0.00	\N
95eb43b9-e36f-429a-96df-dad3bf895153	cmofmpqxp0000tms4st6fcb8x	BRIENDRA BAJPAI	BAJAJ JI	\N	\N	0.00	\N
955aec53-4a3e-4828-9a45-2a90064070e3	cmofmpqxp0000tms4st6fcb8x	Brigesh Sahu	ANANTRAM JI	\N	\N	0.00	\N
cb6f69d6-5ea7-4acc-8614-6e1237b3d257	cmofmpqxp0000tms4st6fcb8x	BRIJENDRA SAHU	ANANTRAM JI	\N	\N	0.00	\N
8c8aab23-fa65-4766-a110-eafbf3d27c7b	cmofmpqxp0000tms4st6fcb8x	BRIJ KISHAN GUPTA NAYA GANJ	AMAR SONKAR	\N	\N	0.00	\N
32e7b798-70f7-4957-9aaa-597d04db5bd7	cmofmpqxp0000tms4st6fcb8x	BRIJMOHAN JI	Sundry Debtors	\N	\N	0.00	\N
861cac89-9dbd-4543-b11d-d27787258b03	cmofmpqxp0000tms4st6fcb8x	B R POUCH PACKING MACHINES PVT LTD.	CREDITORS ( DIPESH JI )	\N	\N	13012.00	\N
236e4b76-0094-4731-b280-60db83dd09a5	cmofmpqxp0000tms4st6fcb8x	B RUSK BAKING TRAY 18%	Fixed Assets	\N	\N	-42688.35	\N
0c9902d8-5338-492d-966e-7c19c0e05158	cmofmpqxp0000tms4st6fcb8x	B S Engineering Works	Sundry Creditors	\N	\N	-26000.00	\N
7a6504f6-2ca9-4685-a63b-95ae08c1cb31	cmofmpqxp0000tms4st6fcb8x	Building	Fixed Assets	\N	\N	-12414078.07	\N
8aaeeecd-43d2-4802-941e-98e16622c674	cmofmpqxp0000tms4st6fcb8x	Building Repairing &amp; Maintenance 12%	Building Repair & Maintenance	\N	\N	0.00	\N
e8888c7c-ab88-4a97-80f5-8c65c5f43699	cmofmpqxp0000tms4st6fcb8x	BUILDING REPAIRING &amp; MAINTENANCE 18%	Building Repair & Maintenance	\N	\N	0.00	\N
4fc09143-35a8-4f27-886c-60bd72b9e670	cmofmpqxp0000tms4st6fcb8x	Building Repairing &amp; Maintenance 28%	Building Repair & Maintenance	\N	\N	0.00	\N
bf512349-d89d-4ca6-988c-f0cd519b7fa3	cmofmpqxp0000tms4st6fcb8x	BUILDING REPAIRING &amp; MAINTENANCE 5%	Building Repair & Maintenance	\N	\N	0.00	\N
c223db5b-7e33-4067-bb42-f1794ca85892	cmofmpqxp0000tms4st6fcb8x	Building Repair &amp; Maintenance U/R	Building Repair & Maintenance	\N	\N	0.00	\N
ca3d8bf4-dfae-4742-a536-3ff8384bf241	cmofmpqxp0000tms4st6fcb8x	BULKIFY	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
bb5a5a84-e3f2-4e71-b7c5-dfed4b89a76a	cmofmpqxp0000tms4st6fcb8x	BURGLARY INSURANCE	INSURANCE	\N	\N	0.00	\N
cd3001dd-3dc7-4bcd-8e86-be0b6fcc464d	cmofmpqxp0000tms4st6fcb8x	Business Promotion	BUSSINESS PROMOTION	\N	\N	0.00	\N
34c18ce2-730f-4f3d-820b-54c0ee03f68c	cmofmpqxp0000tms4st6fcb8x	Bussiness Promotion	BUSSINESS PROMOTION	\N	\N	0.00	\N
35191e08-9094-45cd-a14c-c2ac965ad4ff	cmofmpqxp0000tms4st6fcb8x	Bussiness Promotion 12 %	BUSSINESS PROMOTION	\N	\N	0.00	\N
641d10ce-b834-4f52-8e33-7c7056ff8cd5	cmofmpqxp0000tms4st6fcb8x	BUSSINESS PROMOTION  18%	BUSSINESS PROMOTION	\N	\N	0.00	\N
7d38594a-3539-4902-9226-c1108f227e4a	cmofmpqxp0000tms4st6fcb8x	CAMERA AMC 18%	Indirect Expenses	\N	\N	0.00	\N
9ce1639a-911f-4b92-9765-3b425bd23509	cmofmpqxp0000tms4st6fcb8x	Canopi ( 4X4X7 )	Fixed Assets	\N	\N	-2338.73	\N
fd6dc838-5661-462d-a07f-6af5207ed0b7	cmofmpqxp0000tms4st6fcb8x	CAPITAL GAIN	Indirect Incomes	\N	\N	0.00	\N
e9042738-dfe8-4543-903b-a24fc559cd98	cmofmpqxp0000tms4st6fcb8x	Cash	Cash-in-Hand	\N	\N	-2975982.94	\N
70ece6c9-95fb-476f-8f28-18cf3f755ae6	cmofmpqxp0000tms4st6fcb8x	CASH COUNTING MACHINE	Plant & Machinery 18%	\N	\N	-4696.25	\N
2dd21b5b-2b36-4e28-bc15-81a396147cbd	cmofmpqxp0000tms4st6fcb8x	CCTV Camera	Fixed Assets	\N	\N	-9684.47	\N
d1e4ced9-1887-40cf-a396-6b0c708543f1	cmofmpqxp0000tms4st6fcb8x	CCTV Camera 18%	Fixed Assets	\N	\N	-192960.42	\N
914e254d-e4c2-43b3-8e0c-3534414b3d7b	cmofmpqxp0000tms4st6fcb8x	Central UP Gas Limited	CUGL	\N	\N	4091.00	\N
b5430d71-8071-47c2-9f6d-45280acebceb	cmofmpqxp0000tms4st6fcb8x	Central U P Gas Limited ( D-33 )	CUGL	\N	\N	-212426.00	\N
e13d864f-42d0-44ce-be47-248c1dd7e9cf	cmofmpqxp0000tms4st6fcb8x	Central UP Gas ( SECURITY )	Loans & Advances (Asset)	\N	\N	-366365.00	\N
0317c1c9-26d6-4df3-90c3-bace5716e021	cmofmpqxp0000tms4st6fcb8x	Central UP Gas ( SECURITY ) D-33	Loans & Advances (Asset)	\N	\N	-75000.00	\N
47fd7bb2-3052-4503-a859-895a3490b06d	cmofmpqxp0000tms4st6fcb8x	Cess	Duties & Taxes	\N	\N	-193.00	\N
0cc14f40-8db9-4d3d-b068-078570a4ec20	cmofmpqxp0000tms4st6fcb8x	CGST 6%	Duties & Taxes	\N	\N	0.00	\N
ab2d32ac-df66-46cd-9dec-7652a3fce8ee	cmofmpqxp0000tms4st6fcb8x	CGST 9%	Duties & Taxes	\N	\N	1953.15	\N
2b86895c-67d0-43cc-b164-91620ac54f03	cmofmpqxp0000tms4st6fcb8x	CGST Payable	Duties & Taxes	\N	\N	0.00	\N
00e5a08e-3f3d-4756-8a19-b16465d322ca	cmofmpqxp0000tms4st6fcb8x	CGST Receivable	Duties & Taxes	\N	\N	0.00	\N
aa576cba-75d7-4be4-9a6f-96e6a7cd1a8e	cmofmpqxp0000tms4st6fcb8x	Chama Packing	Staff & Worker ( SALARY )	\N	\N	0.00	\N
c3176b9d-c9f3-44b1-9455-74e2de17ad69	cmofmpqxp0000tms4st6fcb8x	Chariti &amp; Donation	Indirect Expenses	\N	\N	0.00	\N
e3a4cdf2-d994-45ec-997f-413d38fcc0be	cmofmpqxp0000tms4st6fcb8x	Chaurasia Traders, HAIDERGARH	OUT OF KANPUR	\N	\N	0.00	\N
c8643f7d-e824-4f4b-a7cb-c3c72523903f	cmofmpqxp0000tms4st6fcb8x	Chemi Pharma	CREDITORS ( DIPESH JI )	\N	\N	166719.06	\N
c754acc8-7952-4fd0-8061-ef7b2390eb86	cmofmpqxp0000tms4st6fcb8x	Chhama Ji Packing	Staff & Worker ( SALARY )	\N	\N	0.00	\N
33a39663-a52e-4bf5-a1c0-fd866a46e7b8	cmofmpqxp0000tms4st6fcb8x	CHIKKI CUTTER	Plant & Machinery 18%	\N	\N	-3145.00	\N
5c794a93-a649-4bff-80a4-fc715f37f348	cmofmpqxp0000tms4st6fcb8x	CHITRA STAFF	Staff & Worker ( SALARY )	\N	\N	0.00	\N
361b76ea-cb55-4559-adaa-746c6a102c9c	cmofmpqxp0000tms4st6fcb8x	Chotu Bajpai	BAJAJ JI NEW	\N	\N	0.00	\N
d2f6dce2-e64e-48b1-a386-bd5012b7d479	cmofmpqxp0000tms4st6fcb8x	CLAMP METER	Fixed Assets	\N	\N	-910.80	\N
6d53d91c-c9ef-466a-aad1-c4fc70c90191	cmofmpqxp0000tms4st6fcb8x	CLOSSION STOCK	Stock-in-Hand	\N	\N	-8944866.00	\N
62aceca4-9daa-43e7-b3c1-d5faaf9af84c	cmofmpqxp0000tms4st6fcb8x	CODING MACHINE ( Stamping )	Fixed Assets	\N	\N	-3675.40	\N
72a20744-58c7-4bb8-a0af-21f768d1cb52	cmofmpqxp0000tms4st6fcb8x	Comfort Sales and Services	Sundry Creditors -Exp	\N	\N	0.00	\N
d809bdfe-4eea-496b-a2d4-71251f6655e3	cmofmpqxp0000tms4st6fcb8x	Commission	Indirect Expenses	\N	\N	0.00	\N
17e8424e-301d-4d15-ac22-fb7d0e1af296	cmofmpqxp0000tms4st6fcb8x	COMPANY SAMPLE	Sundry Debtors	\N	\N	0.00	\N
2a7d28f4-29cd-402b-a35a-7a48a0e7da3e	cmofmpqxp0000tms4st6fcb8x	Computer	Fixed Assets	\N	\N	5213.05	\N
8e1d0eff-5b6e-4f38-bda9-2192208640c7	cmofmpqxp0000tms4st6fcb8x	COMPUTER @18%	Fixed Assets	\N	\N	-14406.75	\N
7b8cfd09-9a68-4e79-ba80-276881ddb613	cmofmpqxp0000tms4st6fcb8x	COMPUTER REPAIRING &amp; MAINTENANCE @18%	Indirect Expenses	\N	\N	0.00	\N
ea228849-c38a-4257-8709-a4dd92bc733f	cmofmpqxp0000tms4st6fcb8x	Computer UPS	Fixed Assets	\N	\N	-3661.09	\N
05faa909-777a-4d53-bb6b-bd4db5179c10	cmofmpqxp0000tms4st6fcb8x	CONSUMABEL EXP 12 %	Direct Expenses	\N	\N	0.00	\N
a69895a6-36a3-4e29-b728-314a3b04fa63	cmofmpqxp0000tms4st6fcb8x	CONSUMABLE EXP 18%	Consumable Expenses	\N	\N	0.00	\N
b5a2292a-acad-41b5-94b0-42f5e524766a	cmofmpqxp0000tms4st6fcb8x	CONSUMABLE  EXP 5%	Consumable Expenses	\N	\N	0.00	\N
9257d809-7213-4087-a50e-1b8c71e45f69	cmofmpqxp0000tms4st6fcb8x	Consumable Expenses	Consumable Expenses	\N	\N	0.00	\N
8457efd0-ed1d-4459-a8b0-1110a36cb7da	cmofmpqxp0000tms4st6fcb8x	CONTINENTAL ENGINEER&apos;S	Sundry Creditors -Exp	\N	\N	0.00	\N
e8e9c246-a116-4e33-b06f-f89391468111	cmofmpqxp0000tms4st6fcb8x	CONVEYOR (C.S)	Fixed Assets	\N	\N	-75000.00	\N
561b673f-3d5c-4392-aad4-68041a38333b	cmofmpqxp0000tms4st6fcb8x	CONVEYOR MACHINE	Fixed Assets	\N	\N	-125000.00	\N
07ab59c1-5c7e-49a8-8320-86c48758181b	cmofmpqxp0000tms4st6fcb8x	Convyance ( Bansi JI )	Conveyance	\N	\N	0.00	\N
31d06a1f-a176-4c03-a80c-3058676f8c35	cmofmpqxp0000tms4st6fcb8x	Convyance ( Navdeep )	Indirect Expenses	\N	\N	0.00	\N
ca8696cc-ba9c-4b71-8c0c-c1356b1c911e	cmofmpqxp0000tms4st6fcb8x	Coolar	Fixed Assets	\N	\N	-66255.77	\N
52972280-9586-440e-b8ce-54a254e32fcd	cmofmpqxp0000tms4st6fcb8x	CREATIVE WORLD	Sundry Creditors	\N	\N	0.00	\N
efc2b980-f126-49cb-ae9a-da06d8092def	cmofmpqxp0000tms4st6fcb8x	CRETA 1.5 MPI MT E ( UP78HM1877 ) INSURANCE	INSURANCE	\N	\N	0.00	\N
d5cab5c9-74bb-426d-93b4-fac6f66553dd	cmofmpqxp0000tms4st6fcb8x	CRETA 1.5 MPI MT E ( UP78JF2077 ) INSURANCE	INSURANCE	\N	\N	0.00	\N
84b47b6e-2b3d-4692-9e3b-0610d02890d6	cmofmpqxp0000tms4st6fcb8x	CROMPTON ROOM HEATER	Fixed Assets	\N	\N	-744.71	\N
b5ba2fd6-0eb0-44d1-999a-18aa088a9deb	cmofmpqxp0000tms4st6fcb8x	CROWN ENTERPRISES	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
1efdd451-060d-42a5-b2aa-4b74ae48ffd7	cmofmpqxp0000tms4st6fcb8x	CRYSTAL RO WATER SOLUTION	CHILLER	\N	\N	0.00	\N
2497ccf3-a235-4809-be3b-114590da7cf6	cmofmpqxp0000tms4st6fcb8x	Current Tax	Indirect Expenses	\N	\N	0.00	\N
a46dcc9a-249a-494f-8381-893a9f6c88d6	cmofmpqxp0000tms4st6fcb8x	CYLINDER DESIGNING CHARGES @18%	Indirect Expenses	\N	\N	0.00	\N
3b3bd650-df54-45d0-9857-ff60ff7f9e2d	cmofmpqxp0000tms4st6fcb8x	D-35 ( NAGAR NIGAM )	Indirect Expenses	\N	\N	0.00	\N
50b02709-50d7-437a-8add-ef8188483d75	cmofmpqxp0000tms4st6fcb8x	DABLU - SIPAHI	Sipahi	\N	\N	0.00	\N
05dd7fb4-b941-4072-9e94-d1229c2919a2	cmofmpqxp0000tms4st6fcb8x	DARBARI LAL AND OMPANY	Sundry Creditors -Exp	\N	\N	0.00	\N
33fcfce8-0ea6-4f0a-bedc-ea015a673fc8	cmofmpqxp0000tms4st6fcb8x	DASHMESH DAIRY PRODUCTS	BAJAJ JI	\N	\N	0.00	\N
75e02be9-460a-4d1a-b786-cd75a2d3b2c2	cmofmpqxp0000tms4st6fcb8x	Deepak ( Baba )	Sundry Creditors -Exp	\N	\N	-1300.00	\N
937d6977-61e9-42fa-9e46-b89b94ef5b13	cmofmpqxp0000tms4st6fcb8x	DEEPAK BAJAJ	BAJAJ JI	\N	\N	0.00	\N
92873d04-353e-47fc-9d8d-f87db49f512d	cmofmpqxp0000tms4st6fcb8x	DEEPAK BAJPAI	BAJAJ JI	\N	\N	0.00	\N
0f71ce3f-bffb-4dd8-829e-620b18bff1fb	cmofmpqxp0000tms4st6fcb8x	Deepak Sahu	ANANTRAM JI	\N	\N	0.00	\N
96f793ee-e3c7-4009-8ca8-ba9184dbfa37	cmofmpqxp0000tms4st6fcb8x	DEEP FRIDGE-530LTR	Fixed Assets	\N	\N	-24152.54	\N
36f4d2b9-b6ba-46e0-988f-8f49662ac3a3	cmofmpqxp0000tms4st6fcb8x	DEEPIKA ENTERPRISES, SHAHDOL	Sundry Debtors	\N	\N	0.00	\N
8c6bd908-8f34-4222-aa58-0aa2fa089e48	cmofmpqxp0000tms4st6fcb8x	DEEP SAHU	ANANTRAM JI	\N	\N	0.00	\N
7072b3c2-b750-4be2-92b8-cb1f2ea96059	cmofmpqxp0000tms4st6fcb8x	Deep Traders	Sundry Creditors	\N	\N	0.00	\N
d44134c6-917b-447e-8156-6792bcef1d52	cmofmpqxp0000tms4st6fcb8x	DEEPU NANKEEN Nayagank Express Road	AMAR SONKAR	\N	\N	0.00	\N
b00a0198-6f8b-4349-9f3e-a5359cec8a64	cmofmpqxp0000tms4st6fcb8x	Deferred Tax Liabilites	Loans (Liability)	\N	\N	110571.00	\N
b250f7a7-b705-4f62-a5b8-dccf2ab75d13	cmofmpqxp0000tms4st6fcb8x	Delip Bajpai	BAJAJ JI	\N	\N	0.00	\N
0e6966df-8f4c-4af8-b90f-453378ab904d	cmofmpqxp0000tms4st6fcb8x	Depreciation Charges	Indirect Expenses	\N	\N	0.00	\N
e17e9ab6-b2b1-4a0e-b376-d02708d3d99d	cmofmpqxp0000tms4st6fcb8x	Devendra Kumar Motwani, UNNAO	MOTWANI UNNAO	\N	\N	-5500.00	\N
239c9e7e-392d-4c71-a427-8101eed2f947	cmofmpqxp0000tms4st6fcb8x	DEVENDRA KUMAR TIWARI-Lucknow	Lucknow Distributor	\N	\N	-103389.00	\N
3a6850cd-b444-4b19-9bf8-eb8446910447	cmofmpqxp0000tms4st6fcb8x	DHARMENDRA KUMAR , BIDHUNA	OUT OF KANPUR	\N	\N	0.00	\N
0fa8295e-2e0e-48bd-b7e0-be6a313dcd08	cmofmpqxp0000tms4st6fcb8x	DHEERAJ BAJPAI	BAJAJ JI	\N	\N	0.00	\N
62a3efa6-dabf-437e-a415-1d828e008b5c	cmofmpqxp0000tms4st6fcb8x	Dheeraj Sahu	ANANTRAM JI	\N	\N	0.00	\N
45552f42-ba88-4208-9fdb-1a3fbf299bf0	cmofmpqxp0000tms4st6fcb8x	DHERENDRA KUMAR SALE	Sundry Debtors	\N	\N	0.00	\N
9fc3b813-bb73-43c6-8f65-b3e3aa5a2547	cmofmpqxp0000tms4st6fcb8x	Dherendra ( Salary |)	Staff & Worker ( SALARY )	\N	\N	0.00	\N
d438d605-3e0c-48cd-a7d8-79ac362e7bd5	cmofmpqxp0000tms4st6fcb8x	Dherendra (TOUR )	Sundry Creditors(Tour)	\N	\N	0.00	\N
9b3ad046-4935-4317-96be-7ce621d99d19	cmofmpqxp0000tms4st6fcb8x	DIESAL	Consumable Expenses	\N	\N	0.00	\N
dbbac601-4aec-4c6b-a3a4-49d1a2ea2b8b	cmofmpqxp0000tms4st6fcb8x	Digital Scale	Fixed Assets	\N	\N	-934.19	\N
d0bebec2-a862-4222-942f-3661819e3bc2	cmofmpqxp0000tms4st6fcb8x	DIKSHA GUPTA -NAWABGANJ	OUT OF KANPUR	\N	\N	0.00	\N
145b5b64-dff4-4199-ae64-795c136c0ec4	cmofmpqxp0000tms4st6fcb8x	DILIP BAJAJ	BAJAJ JI NEW	\N	\N	0.00	\N
f4c6debc-89d4-4d40-a1df-8d2642883b3c	cmofmpqxp0000tms4st6fcb8x	DILIP BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
a5b1f550-69b4-4b52-b536-43762e57297d	cmofmpqxp0000tms4st6fcb8x	Dilip E-Rikshaw	FREIGHT OUTWORD	\N	\N	0.00	\N
bbeca923-5e37-41f5-af41-396e428e0aaf	cmofmpqxp0000tms4st6fcb8x	DILIP KUMAR ( Bajaj )	BAJAJ JI	\N	\N	0.00	\N
ba1502df-921b-41a5-8842-61c6738aab12	cmofmpqxp0000tms4st6fcb8x	DILIP PANDEY  ( Salary )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
6e0a165d-2c66-4329-a997-b7a2996d4a1c	cmofmpqxp0000tms4st6fcb8x	DILIP PANDEY  ( Tour )	Sundry Creditors(Tour)	\N	\N	0.00	\N
d0206770-a1e4-49e4-9c51-c7bab14a1cda	cmofmpqxp0000tms4st6fcb8x	Dinesh Bajaj	BAJAJ JI	\N	\N	0.00	\N
0ab0c906-07eb-489c-b35e-d849ba9551bc	cmofmpqxp0000tms4st6fcb8x	Dinesh  Bajpai	BAJAJ JI	\N	\N	0.00	\N
bbfa5da4-ce87-43fd-9946-7e4745e8689c	cmofmpqxp0000tms4st6fcb8x	Dinesh Traders, GOLA	Gaurav, LUCKNOW	\N	\N	0.00	\N
b9b3b5e8-1177-4e8d-831f-9d2d642bf8fb	cmofmpqxp0000tms4st6fcb8x	DINKUM TRADING COMPANY	Sundry Creditors	\N	\N	0.00	\N
aeeddeaa-3f19-496c-ba4e-f0a944744380	cmofmpqxp0000tms4st6fcb8x	DIPESH D-35 LOAN	Loans (Liability)	\N	\N	0.00	\N
ca4016aa-e5af-40fd-818b-4819b11402c9	cmofmpqxp0000tms4st6fcb8x	Dipesh Gajwani Cash A/c	Sundry Debtors	\N	\N	-140957.00	\N
5687dec5-e27e-4be1-8190-8e474f70a6ea	cmofmpqxp0000tms4st6fcb8x	DIPESH GAJWANI ( DIRECTOR )	Sundry Creditors	\N	\N	0.00	Unregistered
cea64484-2e04-4a8b-b283-5843a6dd96bb	cmofmpqxp0000tms4st6fcb8x	DIPESH GAJWANI ( REMUNERATION )	Sundry Creditors	\N	\N	0.00	\N
3d98acbb-b1b8-448a-a3b4-a58f4ea5c24a	cmofmpqxp0000tms4st6fcb8x	Dipesh Gajwani(Unsecured Loans)	Unsecured Loans	\N	\N	9675199.00	\N
cc24c00d-376a-40f1-9750-55a62e7e36f2	cmofmpqxp0000tms4st6fcb8x	Directors Remunearation	Indirect Expenses	\N	\N	0.00	\N
6a487339-7fa6-4a23-b9a5-17e0e0b10aba	cmofmpqxp0000tms4st6fcb8x	DISCOUNT F.O.C. 5%	Sales Accounts	\N	\N	0.00	\N
e2ae0155-0809-4f2c-89c5-1278f9642b72	cmofmpqxp0000tms4st6fcb8x	DISCOUNT PAID	Indirect Expenses	\N	\N	0.00	\N
5c094ee4-b491-49e6-a916-8e320c7cbc28	cmofmpqxp0000tms4st6fcb8x	DISCOUNT REC	Indirect Incomes	\N	\N	0.00	\N
255f1213-ea64-4432-82aa-bd163bd59911	cmofmpqxp0000tms4st6fcb8x	DIVIDER MACHINE (C.S)	Fixed Assets	\N	\N	-300000.00	\N
1dfd8e7d-d2a9-4c7e-9e06-a8315df146d1	cmofmpqxp0000tms4st6fcb8x	DIWALI EXP	DIWALI EXP	\N	\N	0.00	\N
8e273d50-cae0-4495-b99e-3267dd45a66e	cmofmpqxp0000tms4st6fcb8x	DIWALI EXP 5%	DIWALI EXP	\N	\N	0.00	\N
87e4669e-c047-403a-a8bf-19cb49e955d3	cmofmpqxp0000tms4st6fcb8x	DIWALI EXP 6 %	DIWALI EXP	\N	\N	0.00	\N
d717442a-c6bc-486d-a4ac-733c8a02a776	cmofmpqxp0000tms4st6fcb8x	DIWALI EXP@18%	DIWALI EXP	\N	\N	0.00	\N
c8f8941b-6702-4e40-927f-75572f5efe30	cmofmpqxp0000tms4st6fcb8x	DRILL MACHINE600W	Fixed Assets	\N	\N	-1870.00	\N
94441ff1-8b3d-48d0-801e-865b9eabf604	cmofmpqxp0000tms4st6fcb8x	Dry Fruits Cutter Machine	Fixed Assets	\N	\N	-1615.51	\N
d0b06b93-fdb3-4551-8ba2-0975abd71ae3	cmofmpqxp0000tms4st6fcb8x	DURGESH BISCUITS	BISCUITS SALARY	\N	\N	0.00	\N
97fd0fbc-c5ad-43fb-afd9-665c896895b5	cmofmpqxp0000tms4st6fcb8x	Durgesh B Rusk	Sundry Debtors	\N	\N	0.00	\N
cdd10004-7d7d-4f64-b82f-fc96bfb5b14d	cmofmpqxp0000tms4st6fcb8x	DURGESH GUPTA - SHUKLAGANJ	SHUKLAGANJ	\N	\N	0.00	\N
c5e74a69-b8e6-400d-a012-4f0819afe476	cmofmpqxp0000tms4st6fcb8x	Dyna Writing Instruments	Sundry Creditors -Exp	\N	\N	0.00	\N
a816461d-90e5-4164-93a7-f20f810e81b6	cmofmpqxp0000tms4st6fcb8x	Eastern Printing &amp; Packaging Solutions	Sundry Creditors	\N	\N	0.00	\N
b6430499-a397-424e-b230-648732853a92	cmofmpqxp0000tms4st6fcb8x	Ek Dant Agencies, Mauranipur	SATISH	\N	\N	-96712.00	\N
0ee1cf4a-3ca6-49ab-abef-2acf459b98aa	cmofmpqxp0000tms4st6fcb8x	Electrical Fittings @12%	Fixed Assets	\N	\N	-8398.24	\N
6f665172-1a79-401a-9e56-d781b8c61d92	cmofmpqxp0000tms4st6fcb8x	Electrical Fittings @18%	Fixed Assets	\N	\N	-398295.42	\N
bb486e83-0f2d-45d2-82d5-dea4695a9be5	cmofmpqxp0000tms4st6fcb8x	Electrical Installations	Fixed Assets	\N	\N	635.69	\N
67e34850-669d-4c40-a9b1-fd53e10821ed	cmofmpqxp0000tms4st6fcb8x	Electric Exp	Electricity Exp	\N	\N	0.00	\N
4915eb46-7fbf-4d71-8afa-a4440d43ac33	cmofmpqxp0000tms4st6fcb8x	Electricity Expences ( D-33 )	D-33 EXP	\N	\N	0.00	\N
05e1f5d6-b4cd-4511-9ecf-bac757d6838a	cmofmpqxp0000tms4st6fcb8x	Electricity Expenses@12%	Electricity Exp	\N	\N	0.00	\N
b7f204a7-b4ed-4fdb-a5a1-238e27c7e9ae	cmofmpqxp0000tms4st6fcb8x	Electricity Expenses@18%	Electricity Exp	\N	\N	0.00	\N
886a4a16-426d-41b0-98fc-3ae18f79b494	cmofmpqxp0000tms4st6fcb8x	ELECTRIC REPAIRING &amp; MAINTENANCE @18%	Electricity Exp	\N	\N	0.00	\N
cae0db9c-06c8-4934-a94c-3e6925aa6c99	cmofmpqxp0000tms4st6fcb8x	ELECTRIC WEIGHT SCALE 500*500	Fixed Assets	\N	\N	-5500.00	\N
011cf594-cdd5-4780-b183-fde929ca120d	cmofmpqxp0000tms4st6fcb8x	ELECTRONIC WEIGHT SCLAE 10KG (KATTA)	Fixed Assets	\N	\N	-9372.86	\N
e3a13ff0-cca9-47a6-87f1-2ecb6532376d	cmofmpqxp0000tms4st6fcb8x	ESHANT TOUR	Sundry Creditors(Tour)	\N	\N	0.00	\N
c4b21890-543c-44d3-b847-377739852795	cmofmpqxp0000tms4st6fcb8x	EXCITEL BROADBAND PVT LTD	Sundry Creditors -Exp	\N	\N	0.00	\N
cf2c2893-76b4-494c-aa79-f4a2f48df323	cmofmpqxp0000tms4st6fcb8x	EXHAUST FAN 24*900 RPM	Fixed Assets	\N	\N	-5142.39	\N
dae227a2-7e7f-4343-a9be-049f40e08b9b	cmofmpqxp0000tms4st6fcb8x	EXHAUST FAN ORIENT 18*1400	Fixed Assets	\N	\N	-3262.72	\N
3d4aa7b8-141d-4eba-9b0f-d94478fdd6c3	cmofmpqxp0000tms4st6fcb8x	Factory Cleaning Expenses	Office Exp	\N	\N	0.00	\N
b42a7eb3-3253-4583-8474-b124b39ede87	cmofmpqxp0000tms4st6fcb8x	FARHAN LUCKNOW  ( Tour )	Sundry Creditors(Tour)	\N	\N	0.00	\N
06f86933-e45e-49b9-b5d5-ee62a0d4f156	cmofmpqxp0000tms4st6fcb8x	FARUKHABAD NAMKEEN, NAYA GANJ	AMAR SONKAR	\N	\N	0.00	\N
243f946e-4782-494f-b29b-49bc921cfd38	cmofmpqxp0000tms4st6fcb8x	FESTIVAL EXP	Festival Expenses	\N	\N	0.00	\N
f2b27a98-558a-49bf-a1c6-d131a042c480	cmofmpqxp0000tms4st6fcb8x	F F Store, Ram Narain Bajar	AMAR SONKAR	\N	\N	0.00	\N
890923c1-755c-47f4-acdd-182375e58bfb	cmofmpqxp0000tms4st6fcb8x	FINE TOOLS AND HARDWARE	Sundry Creditors	\N	\N	0.00	\N
e36a3e39-d0ce-4241-a97a-9a72ba065a8f	cmofmpqxp0000tms4st6fcb8x	FIRE BUCKET	Fixed Assets	\N	\N	-552.50	\N
a13fe803-81a6-4ef5-a370-94d04fb70e9e	cmofmpqxp0000tms4st6fcb8x	FIREEQUIPMENT 18%	Fixed Assets	\N	\N	-157652.11	\N
48097c76-6432-4097-8f5c-210a4aa654b6	cmofmpqxp0000tms4st6fcb8x	FIRE EXHAUST18%	Fixed Assets	\N	\N	-13800.00	\N
db372868-7fce-4755-acd5-eb9e487d7cfb	cmofmpqxp0000tms4st6fcb8x	FIROJ ENTERPRISES	SUNDRY DEBTORS (SCRAP)	\N	\N	0.00	\N
cc71f038-f05a-49ca-9412-77d3bb9294ae	cmofmpqxp0000tms4st6fcb8x	Fisher Automation	Sundry Creditors -Exp	\N	\N	0.00	\N
6d59ffb9-3ff5-4a3b-966c-8f34086ba8de	cmofmpqxp0000tms4st6fcb8x	FLOW FAN	FAN	\N	\N	-11259.01	\N
97b2455d-0801-4210-97e6-7319e672f45f	cmofmpqxp0000tms4st6fcb8x	FRANKLIN INDIA OPPORT FUND( 34795151 ) 19/12/24	SIP	\N	\N	0.00	\N
d1df3d2a-9634-4237-aa75-c0474c0deaf2	cmofmpqxp0000tms4st6fcb8x	FREIGHT	Indirect Expenses	\N	\N	0.00	\N
60896902-8864-4655-8851-4f09ba27fc62	cmofmpqxp0000tms4st6fcb8x	FREIGHT &amp; CARTAGE RCM	Direct Expenses	\N	\N	0.00	\N
56b37e08-5533-47c5-9266-9dbfb7b0482d	cmofmpqxp0000tms4st6fcb8x	FREIGHT INWARD	Direct Expenses	\N	\N	0.00	\N
44ce88b4-68da-47a1-af04-c3ffd9d651fc	cmofmpqxp0000tms4st6fcb8x	Freight Inward 18%	Direct Expenses	\N	\N	0.00	\N
3559b37c-6b22-4ac8-a402-2d833c57814b	cmofmpqxp0000tms4st6fcb8x	FREIGHT INWARD 5%	Direct Expenses	\N	\N	0.00	\N
8e79d52c-a47a-4e51-9e4d-176ed387ba3a	cmofmpqxp0000tms4st6fcb8x	Freight Outward ( Kanpur Local )	Freight & Cartage O/W	\N	\N	0.00	\N
1e00bfbc-d41c-4c04-b429-5fad16bf2b24	cmofmpqxp0000tms4st6fcb8x	Freight Outward ( Out Of Kanpur )	Freight & Cartage O/W	\N	\N	0.00	\N
669cf706-b920-451a-83df-e161d7f21401	cmofmpqxp0000tms4st6fcb8x	Furniture &amp; Fixures	Fixed Assets	\N	\N	-64139.30	\N
f7be5e12-e1ee-4cf3-86d7-e1cd531fb80e	cmofmpqxp0000tms4st6fcb8x	GABBAR - SIPAHI	Sipahi	\N	\N	0.00	\N
30a67ee3-bd05-4d26-8fae-0119a38f4296	cmofmpqxp0000tms4st6fcb8x	GAGAN (BISCUITS CONTRACTOR)	Sundry Debtors	\N	\N	0.00	\N
acd97d67-a2bb-4087-bd4c-7819fb3e3bef	cmofmpqxp0000tms4st6fcb8x	GAGAN PRAJAPATI ( BISCUIT THEKEDAR )	WAGES ( CONTRACTOR )	\N	\N	0.00	\N
df023291-b91d-4065-9c7c-01ac86fa8230	cmofmpqxp0000tms4st6fcb8x	GATTU PACKING MACHINE	Fixed Assets	\N	\N	-450000.00	\N
6430c7e5-ca86-4ba5-973b-f6fd21f37d3d	cmofmpqxp0000tms4st6fcb8x	Gaurang Enterprises	Sundry Creditors	\N	\N	0.00	\N
899b52b5-d7ac-494d-8d62-c89b361e8b17	cmofmpqxp0000tms4st6fcb8x	GAURAV AGENCIES, JHANSI	OUT OF KANPUR	\N	\N	-34708.00	\N
82da84e5-f469-437e-9c8a-bb9e0b94b05d	cmofmpqxp0000tms4st6fcb8x	GAURAV MISHRA ( LUCKNOW ) SALARY	Staff & Worker ( SALARY )	\N	\N	-27801.71	\N
cddb9bdf-1355-4e2b-98b0-6f76061681a9	cmofmpqxp0000tms4st6fcb8x	GAURAV MISHRA ( TOUR )	Sundry Creditors(Tour)	\N	\N	0.00	\N
a8c1f0aa-cb45-499b-9d99-3f402b4d4916	cmofmpqxp0000tms4st6fcb8x	GAYATRI TRADERS, MALLAWAN	OUT OF KANPUR	\N	\N	0.00	\N
a76e7851-03e5-4770-ba04-500aa7e87339	cmofmpqxp0000tms4st6fcb8x	GDK SOLUTIONS	CREDITORS ( DIPESH JI )	\N	\N	118818.00	\N
acdcc908-9f95-4f8f-bc0c-132f5d01ca36	cmofmpqxp0000tms4st6fcb8x	Geeta Kitchenware Llp	Sundry Creditors -Exp	\N	\N	0.00	\N
3c64da02-7e3f-420d-9796-4c7080957958	cmofmpqxp0000tms4st6fcb8x	GENERATOR	Fixed Assets	\N	\N	-7403.03	\N
c473e1ef-15a2-46e3-8744-6ef077f2dea2	cmofmpqxp0000tms4st6fcb8x	GENERATOR 125KVA (12-7-16)	Fixed Assets	\N	\N	-500000.00	\N
7b8a388d-1fc8-4942-a5ab-e7dfe658abaa	cmofmpqxp0000tms4st6fcb8x	Generator 65KVA	Fixed Assets	\N	\N	0.00	\N
5b5aef37-d8b2-4306-83e0-c656b048a4c1	cmofmpqxp0000tms4st6fcb8x	GENERATOR  REPAIRING &amp; MAINTENANCE @18%	Indirect Expenses	\N	\N	0.00	\N
a4f6caaf-bcbe-4e30-9b38-6f7f5b0a7f84	cmofmpqxp0000tms4st6fcb8x	GHANSHYAM SAHU	ANANTRAM JI	\N	\N	0.00	\N
1b66ec0a-ec33-4eb9-81c7-fb1ba622f4d2	cmofmpqxp0000tms4st6fcb8x	G.I.Sheet	Fixed Assets	\N	\N	-140421.66	\N
1ebecde2-5ff2-4111-a3aa-93f6b05553fc	cmofmpqxp0000tms4st6fcb8x	GOLDEN FOODS	Sundry Debtors	\N	\N	-209602.00	\N
2a0e8fbb-c98f-46d0-8ee9-65f5777bddc5	cmofmpqxp0000tms4st6fcb8x	Goodwill	Fixed Assets	\N	\N	-51818.25	\N
6a1358f6-5332-460f-bc18-5b1c12a131e8	cmofmpqxp0000tms4st6fcb8x	Gopi Chand D-35 (Purchase)	Sundry Creditors	\N	\N	-347455.00	\N
e1d79436-c9d6-4263-8cb9-794461fe7bcb	cmofmpqxp0000tms4st6fcb8x	Gopi Chand D-35(Rent)	Sundry Creditors	\N	\N	0.00	\N
31658188-24b5-4ace-bf9d-7b1982588333	cmofmpqxp0000tms4st6fcb8x	Gopi Chand D-35(Security)	Loans & Advances (Asset)	\N	\N	-140000.00	\N
b3e97114-6a7e-43a5-b5e5-3173589e930a	cmofmpqxp0000tms4st6fcb8x	GRINDER 18%	Fixed Assets	\N	\N	-2100.00	\N
c0c3a32c-f2a8-4103-a050-06c4944090af	cmofmpqxp0000tms4st6fcb8x	G S CONFESNARY, RIAL BAJAR	AMAR SONKAR	\N	\N	-1280.00	\N
befaf293-a424-452b-8d71-d2bf16fec012	cmofmpqxp0000tms4st6fcb8x	GST DEMAND 2018-2023	Indirect Expenses	\N	\N	0.00	\N
1748d907-684f-41b4-8f9c-d05b82f9d433	cmofmpqxp0000tms4st6fcb8x	GST PAYABLE	Duties & Taxes	\N	\N	-0.99	\N
9d5b9954-a56e-47b4-8333-d57880580a98	cmofmpqxp0000tms4st6fcb8x	GUDDU BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
a05bbb8f-8962-4165-94a7-a81adb494626	cmofmpqxp0000tms4st6fcb8x	GUDDU FARUKHABAD, Nayaganj	AMAR SONKAR	\N	\N	0.00	\N
2675f7f9-6f00-4a20-a81c-af5d08ca6f76	cmofmpqxp0000tms4st6fcb8x	GUDDU -SIPAHI	Sipahi	\N	\N	0.00	\N
9ea58b7b-af7c-40ab-96bd-7374abf7efa5	cmofmpqxp0000tms4st6fcb8x	Gupta Ji ( LOADER )	FREIGHT OUTWORD	\N	\N	0.00	\N
e71e2555-c807-4921-bb8a-43f475a8086f	cmofmpqxp0000tms4st6fcb8x	GUPTA SALES, CHAUBEPUR	Ashutosh Ji	\N	\N	0.00	\N
9a4b2579-b5fb-4511-8302-642ca6878697	cmofmpqxp0000tms4st6fcb8x	GUPTA STORE, RAIL BAZAR	AMAR SONKAR	\N	\N	-2116.00	\N
3b31a108-9ff3-4ec5-baa1-b37c93dbb90a	cmofmpqxp0000tms4st6fcb8x	GURU KRIPA AGENCIES, MOTH	Sundry Debtors	\N	\N	0.00	\N
1632b32f-bbd1-43d9-a073-a879dee26b57	cmofmpqxp0000tms4st6fcb8x	GYANENDRA SAHU	ANANTRAM JI	\N	\N	0.00	\N
a10a55f8-9e4e-4b2f-8dc9-a7f489b6a795	cmofmpqxp0000tms4st6fcb8x	HAND COADING MACHINE	Fixed Assets	\N	\N	-12150.80	\N
9005ac29-0bf6-4bb5-a077-38c98a95540b	cmofmpqxp0000tms4st6fcb8x	HAREESH SAHU	ANANTRAM JI	\N	\N	0.00	\N
46608c90-9eed-40c1-ac7e-007a3740bd74	cmofmpqxp0000tms4st6fcb8x	HARI OM TRADERS	Sundry Creditors -Exp	\N	\N	0.00	\N
f28d7a90-0548-4658-adcb-6df23bafd566	cmofmpqxp0000tms4st6fcb8x	Hari Om Traders, DEORIA	OUT OF KANPUR	\N	\N	0.00	\N
659016d6-addd-44b1-9b83-6ab9365edb0c	cmofmpqxp0000tms4st6fcb8x	Harish Chandra Motwani, Unnao	MOTWANI UNNAO	\N	\N	0.00	\N
5d112648-caa1-497a-8495-618a2b73aa33	cmofmpqxp0000tms4st6fcb8x	Harish Geeli Cutting	SCRAP ( DEBTORS )	\N	\N	-12225.00	\N
fca68f98-1ec5-43d1-bb02-d3b9cb07d7f3	cmofmpqxp0000tms4st6fcb8x	HARI TRADERS	ANANTRAM JI	\N	\N	0.00	\N
7ac3d0b2-81ad-4d55-bfcf-4def67652d23	cmofmpqxp0000tms4st6fcb8x	Harjeet Laminators	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
0aa3046d-02b1-4639-bd93-9c6f198f99cb	cmofmpqxp0000tms4st6fcb8x	HARSH LAMINATORS	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
9c1eaf3e-6d03-4858-ad5b-58f8a096c7ac	cmofmpqxp0000tms4st6fcb8x	HARSH TRADERS-GORAKHPUR	Sundry Debtors	\N	\N	0.00	\N
598c98e9-b10c-4b67-b614-d2b576c0aa01	cmofmpqxp0000tms4st6fcb8x	HASEEB ENTERPRISES, KATRA	Gaurav, LUCKNOW	\N	\N	0.00	\N
db15479c-286c-420e-805d-cd4037208f96	cmofmpqxp0000tms4st6fcb8x	HAVELLS C/FAN	Fixed Assets	\N	\N	0.00	\N
ac4f57f3-e64a-441a-b948-6a48ef7f90fe	cmofmpqxp0000tms4st6fcb8x	havells exhaust fan 18*1400rpm	Fixed Assets	\N	\N	-3177.98	\N
29d80be8-0c92-4bba-a046-96beee580ea2	cmofmpqxp0000tms4st6fcb8x	H B TRADING COMPANY. SHAHJAHANPUR	Ashutosh Ji	\N	\N	0.00	\N
159a9e0b-3226-4d87-b544-b4cae61311db	cmofmpqxp0000tms4st6fcb8x	HDFC FOCUSED 30 FUND ( 33481960/45 ) 3/1/25	SIP	\N	\N	0.00	\N
0f810ee7-5143-491c-a2fa-164a77b698be	cmofmpqxp0000tms4st6fcb8x	INSURANCE (BUILDING)	INSURANCE	\N	\N	0.00	\N
3e3ade03-3b57-471a-83a3-a96e4a06ffc6	cmofmpqxp0000tms4st6fcb8x	HDFC LARGE AND MID CAP FUND( 33281701/04 ) 19/12/24	SIP	\N	\N	0.00	\N
17ac5fa9-3840-4b31-b869-f119b30f4768	cmofmpqxp0000tms4st6fcb8x	HEERA SAHU	ANANTRAM JI	\N	\N	0.00	\N
ea1b7801-29bc-4da1-8875-557f64317ec7	cmofmpqxp0000tms4st6fcb8x	HEER GAJWANI	Staff & Worker ( SALARY )	\N	\N	0.00	\N
5549ed34-d5b7-4235-b920-200ed93ef2f2	cmofmpqxp0000tms4st6fcb8x	HELLO MEDIA	Sundry Creditors	\N	\N	0.00	\N
c1ed95df-4719-4dd3-91ae-e0c7b92b83fb	cmofmpqxp0000tms4st6fcb8x	HIMANSHU TRADING COMPANY	Sundry Debtors	\N	\N	0.00	\N
91e5d1c5-94cb-4532-a21c-a6923619bff7	cmofmpqxp0000tms4st6fcb8x	HIND PATANJALI KENDRA	KAVITA	\N	\N	0.00	\N
d85cba11-b531-497b-a894-3a46b767124d	cmofmpqxp0000tms4st6fcb8x	HIND TRADERS	Sundry Creditors	\N	\N	0.00	\N
39f2b3e5-f402-46c0-a940-a4d2fc7e45f7	cmofmpqxp0000tms4st6fcb8x	HIRAN THEKEDAR	WAGES ( CONTRACTOR )	\N	\N	0.00	\N
e531073a-3ebb-4f0e-9917-0b7b33e987d1	cmofmpqxp0000tms4st6fcb8x	HOLI EXP	Festival Expenses	\N	\N	0.00	\N
54fce4a6-453c-40d2-9e38-ce3790d984b9	cmofmpqxp0000tms4st6fcb8x	HP LASER JET PRO MFP M126A PRINTER	Fixed Assets	\N	\N	-10592.59	\N
eeba01a6-bd72-4543-b172-75e1bf0dfe35	cmofmpqxp0000tms4st6fcb8x	HR BAJAJ	BAJAJ JI	\N	\N	0.00	\N
a30b7c02-d67e-4738-be5f-f3899a0c4292	cmofmpqxp0000tms4st6fcb8x	HR SAHU	ANANTRAM JI	\N	\N	0.00	\N
55346872-85c6-4ce1-b30d-6412c32e1336	cmofmpqxp0000tms4st6fcb8x	HSBC BUSINESS CYCLES FUND ( 20890187/72 ) 19/12/24	SIP	\N	\N	0.00	\N
faa6d578-0ebf-405d-b429-93f952d68767	cmofmpqxp0000tms4st6fcb8x	HUNNY ( ICE )	Consumable Expenses	\N	\N	0.00	\N
7d0071c1-f1ce-4c43-96ae-9bd9e246e0c0	cmofmpqxp0000tms4st6fcb8x	HYDRAULIC WALL MOUNT LIFT	Fixed Assets	\N	\N	-240457.45	\N
27b5d11c-31b8-4a55-b470-dea9880a516f	cmofmpqxp0000tms4st6fcb8x	Hyundai Creta 1.5 Mpi Mt E ( UP78JD2077 )	Fixed Assets	\N	\N	-1042626.00	\N
9c2cbbdc-4d2c-436e-a350-f08c3a3c4887	cmofmpqxp0000tms4st6fcb8x	I.A. ENTERPRISES	Sundry Creditors	\N	\N	0.00	\N
802ec760-99b7-4e2b-a8c1-7fed2a273e1e	cmofmpqxp0000tms4st6fcb8x	IARDO	Sundry Creditors	\N	\N	0.00	\N
a8187f84-4e0b-4b72-98e6-0665e42c12e1	cmofmpqxp0000tms4st6fcb8x	IBRAHIM - SIPAHI	Sipahi	\N	\N	-20000.00	\N
a6e01154-dd96-4a8b-96b3-3cae960a86ee	cmofmpqxp0000tms4st6fcb8x	ICICI Bank A/c No.099805001580	Bank OD A/c	\N	\N	0.00	\N
82b9fa54-51b6-4e9b-b1f9-f3b1a25a64ff	cmofmpqxp0000tms4st6fcb8x	ICICI Bank A/c No.099805002695	Bank Accounts	09AAACI1195H1ZK	\N	8700671.49	\N
e317c937-63b3-493c-8234-bbb6238ad34d	cmofmpqxp0000tms4st6fcb8x	ICICI Bank ( LAKAN00051136200 ) CRETA 22-5-25 - 5L	Secured Loans	\N	\N	215982.55	\N
6c4dab85-b4b4-4990-a6a1-12ec74ee58d2	cmofmpqxp0000tms4st6fcb8x	I.C.I.C.I BANK (LOAN A/C NO.-603090029628 )	Secured Loans	\N	\N	0.00	\N
76a174f9-ef5d-4f63-bb01-64b03bbd324b	cmofmpqxp0000tms4st6fcb8x	I.C.I.C.I BANK (LOAN A/C NO.-603090049482 ) REEMA	Secured Loans	\N	\N	0.00	\N
7a52879b-a227-4d3f-8e02-65480c28f279	cmofmpqxp0000tms4st6fcb8x	I.C.I.C.I BANK (LOAN A/C NO.-L3KAN00005348608	Secured Loans	\N	\N	0.00	\N
7651a024-a621-447c-bd00-20a21269b4fd	cmofmpqxp0000tms4st6fcb8x	I.C.I.C.I BANK ( LOAN A/C NO-TBKAN00007460059 ) D35	Secured Loans	\N	\N	21018795.00	\N
d5fe7e97-c13f-470f-85a1-6fa00b56b73f	cmofmpqxp0000tms4st6fcb8x	I.C.I.C.I BANK ( LOAN A/C NO-UPKAN00051882724 ) 25L	Secured Loans	\N	\N	2387636.00	\N
921f40a2-a94f-46ed-a977-ad8143e34b34	cmofmpqxp0000tms4st6fcb8x	ICICI Lombard General Insurance	Sundry Creditors -Exp	\N	\N	0.00	\N
e768f197-0613-4514-87fe-766659abdb81	cmofmpqxp0000tms4st6fcb8x	ICICI PRUDENTIAL MIDCAP FUND( 34180777/55 ) 29/7/24	SIP	\N	\N	0.00	\N
b1fc4520-547e-4b07-a6c7-6606e7c15a86	cmofmpqxp0000tms4st6fcb8x	ICICI Pru Flexicap Fund	Investments	\N	\N	0.00	\N
c899fd75-67c3-4b79-ab21-9b36deba012b	cmofmpqxp0000tms4st6fcb8x	ICICI Suspense A/c	Suspense A/c	\N	\N	0.00	\N
4791cc26-9b0d-4c99-bc8d-2c2e02e25457	cmofmpqxp0000tms4st6fcb8x	I.G.BAJAJ JI	BAJAJ JI	\N	\N	0.00	\N
382b01d5-3365-42d4-b0b5-98be9fa175db	cmofmpqxp0000tms4st6fcb8x	IGST @18%	Duties & Taxes	\N	\N	-0.01	\N
afc3251d-0cd1-4599-8aa9-67f8a768bd78	cmofmpqxp0000tms4st6fcb8x	I GST @5%	Duties & Taxes	\N	\N	23690.56	\N
f73c8104-4488-4bc2-a7b4-825e4d3142bb	cmofmpqxp0000tms4st6fcb8x	IGST Receivable	Duties & Taxes	\N	\N	0.00	\N
82e0e600-8910-4a62-9ec1-50786960f756	cmofmpqxp0000tms4st6fcb8x	IGST Sale@5%	Sales Accounts	\N	\N	0.00	\N
efe88a63-a714-4fbe-977d-1cca6ed1bf40	cmofmpqxp0000tms4st6fcb8x	Incentives	Indirect Expenses	\N	\N	0.00	\N
e4a62997-b798-43cc-a9ce-8bc242bc3adc	cmofmpqxp0000tms4st6fcb8x	Income Tax Expense	Indirect Expenses	\N	\N	0.00	\N
321fdf21-61c2-49e5-b314-9b80da36ba39	cmofmpqxp0000tms4st6fcb8x	INDER BAJAJ	BAJAJ JI	\N	\N	0.00	\N
7a1a893b-1572-425c-a125-e98785ae62bf	cmofmpqxp0000tms4st6fcb8x	INDER SWEAPER	Staff & Worker ( SALARY )	\N	\N	0.00	\N
d27a5b74-8fc6-4cc1-bfd2-d35b6d73371e	cmofmpqxp0000tms4st6fcb8x	INDIA ELECTRIC	Sundry Creditors	\N	\N	0.00	\N
dcfc3d6d-1f3d-485c-9c72-06328ff69134	cmofmpqxp0000tms4st6fcb8x	INDIAMART INTERMESH LTD	Sundry Creditors	\N	\N	0.00	\N
25455d56-9771-43e5-898e-0756eb623990	cmofmpqxp0000tms4st6fcb8x	INDIAN INDUSTRIES ASSOCIAT ( IIA )	Sundry Creditors	\N	\N	0.00	\N
3fce8a9d-fed2-49b4-87ff-ec65683a4553	cmofmpqxp0000tms4st6fcb8x	INDO ASIA PLASTICS, DELHI	Sundry Creditors -Exp	\N	\N	0.00	\N
54626763-33d0-4ef6-b658-d18c0b81c807	cmofmpqxp0000tms4st6fcb8x	Industrial Experts	Sundry Creditors -Exp	\N	\N	0.00	\N
508e6bb5-e2e7-4219-af9f-d94b5b555699	cmofmpqxp0000tms4st6fcb8x	INDUSTRIAL PNG	Consumable Expenses	\N	\N	0.00	\N
1ab865b1-9064-4de7-86e3-45bd3de142a8	cmofmpqxp0000tms4st6fcb8x	INPUT CGST 14%	Duties & Taxes	\N	\N	0.00	\N
40566890-d524-4837-b118-bb90ceef7584	cmofmpqxp0000tms4st6fcb8x	INPUT CGST 2.5%	Duties & Taxes	\N	\N	-108993.06	\N
1e89c8ec-cdf8-42d1-814a-f4487e693fbb	cmofmpqxp0000tms4st6fcb8x	INPUT CGST 6%	Duties & Taxes	\N	\N	-693.47	\N
4e236717-c359-40b6-a0cd-868c7df2b500	cmofmpqxp0000tms4st6fcb8x	INPUT CGST 9%	Duties & Taxes	\N	\N	-78283.34	\N
b457e94d-b152-4317-9877-ca609cf47160	cmofmpqxp0000tms4st6fcb8x	INPUT IGST 18%	Duties & Taxes	\N	\N	-6411.23	\N
54ca3599-bd7d-4d16-9168-78f6b40ae292	cmofmpqxp0000tms4st6fcb8x	Input IGST@12%	Duties & Taxes	\N	\N	0.00	\N
4303b916-ead7-4e4e-a73b-27e7ba881444	cmofmpqxp0000tms4st6fcb8x	Input IGST@5%	Duties & Taxes	\N	\N	0.00	\N
38e46d4e-8990-4515-a507-cb663516ac4a	cmofmpqxp0000tms4st6fcb8x	INPUT SGST 14%	Duties & Taxes	\N	\N	0.00	\N
e66ffa09-b192-4cba-8503-0820266ac32e	cmofmpqxp0000tms4st6fcb8x	INPUT SGST 2.5%	Duties & Taxes	\N	\N	-105098.10	\N
f2c14f06-9f13-473f-b780-3aac55bb50b7	cmofmpqxp0000tms4st6fcb8x	INPUT SGST 6%	Duties & Taxes	\N	\N	-693.47	\N
cd8a38b6-df31-4152-aa7c-e79ec2a51e07	cmofmpqxp0000tms4st6fcb8x	INPUT SGST9%	Duties & Taxes	\N	\N	-86412.50	\N
73104789-eeb9-4d20-8711-0d42a267318b	cmofmpqxp0000tms4st6fcb8x	INSECT  KILLER MACHINE  2*18 WATT	Fixed Assets	\N	\N	-1751.23	\N
dbabc13d-7805-43ca-a281-6bdb4477be42	cmofmpqxp0000tms4st6fcb8x	INSURANCE (VEHICLES)	INSURANCE	\N	\N	0.00	\N
926f8927-9e9f-4c92-99c9-237df0e3bb00	cmofmpqxp0000tms4st6fcb8x	Interest Income	Indirect Incomes	\N	\N	0.00	\N
4e24d4d2-f7b9-41f8-bdd0-8bd084387b3d	cmofmpqxp0000tms4st6fcb8x	Interest on CC Limit	Bank Interest	\N	\N	0.00	\N
f212ecdb-1d7e-447f-88a5-4c2887a57010	cmofmpqxp0000tms4st6fcb8x	Interest on TDS	Indirect Expenses	\N	\N	0.00	\N
7eb38f3a-ca44-4075-9385-0b54ad321171	cmofmpqxp0000tms4st6fcb8x	Internet Exp.	Indirect Expenses	\N	\N	0.00	\N
f2ea3bf0-b02f-47fe-ab5e-52bac3371d28	cmofmpqxp0000tms4st6fcb8x	INVENST	Investments	\N	\N	-85000.00	\N
17258df5-b02b-48fc-a52a-a993083cba71	cmofmpqxp0000tms4st6fcb8x	Inverter	Fixed Assets	\N	\N	-2916.54	\N
0ac08390-ae7b-4c5b-8119-51927ee09a93	cmofmpqxp0000tms4st6fcb8x	Investment	Investments	\N	\N	0.00	\N
0a536ab7-7dbc-4b66-854b-7ee2693d3a90	cmofmpqxp0000tms4st6fcb8x	Invokil Pest Control Private Limited	Sundry Creditors -Exp	\N	\N	0.00	\N
d08f625a-9fe8-4876-94c2-f9f4d339b134	cmofmpqxp0000tms4st6fcb8x	IRON TRAY	Fixed Assets	\N	\N	-248984.07	\N
a2bcba9e-da86-4042-9474-e1aae947410b	cmofmpqxp0000tms4st6fcb8x	Issued Capital	Authorised Capital	\N	\N	1500000.00	\N
c69026f5-7a61-4a02-b135-24428409c626	cmofmpqxp0000tms4st6fcb8x	ITC Inelegible	Indirect Expenses	\N	\N	0.00	\N
03611df8-de55-4115-ac7f-eb30cf08ece0	cmofmpqxp0000tms4st6fcb8x	ITC Writeoff	Indirect Expenses	\N	\N	0.00	\N
40b8bbfd-d7d3-43bf-89ac-822f2f707c25	cmofmpqxp0000tms4st6fcb8x	Jagdeesh Sahu	ANANTRAM JI	\N	\N	0.00	\N
9a5dd4e2-300b-4dbe-9cdb-98b443c890d4	cmofmpqxp0000tms4st6fcb8x	Jai Durga Agencies, PRATAPGARH	Ashutosh Ji	\N	\N	0.00	\N
07216be2-1143-4e90-8bd4-8c8833e48ced	cmofmpqxp0000tms4st6fcb8x	JAI DURGE MEDICAL STORE HAMIRPUR	Sundry Debtors	\N	\N	0.00	\N
edabc60d-d60d-4cb1-8f99-6cee08b0087b	cmofmpqxp0000tms4st6fcb8x	JAI GANESH ENTERPRISES	CONVEYAR	\N	\N	0.00	\N
62664ee2-b615-4e3e-9116-0a64c8d5dc7b	cmofmpqxp0000tms4st6fcb8x	JAI MAA DURGA AGENCY-GONDA	Shivoham Shukla Parties	\N	\N	-38685.00	\N
c3bfb411-ed03-486a-9b9c-c37330e629ed	cmofmpqxp0000tms4st6fcb8x	JAIPUR BAKE EQUIPMENT	Sundry Creditors	\N	\N	0.00	\N
100c6f7a-508a-4c7b-8c21-24dcd39c276d	cmofmpqxp0000tms4st6fcb8x	JAI SHRI BALAJI SWEETS	KAVITA	\N	\N	0.00	\N
aff0be06-e67c-4cfa-add2-863f125ceb58	cmofmpqxp0000tms4st6fcb8x	Janak Traders, Banda	Ashutosh Ji	\N	\N	0.00	\N
f8983efb-167c-4ea7-837e-9048c077efdf	cmofmpqxp0000tms4st6fcb8x	JATIN PURSWANI, GWALIOR	OUT OF KANPUR	\N	\N	0.00	\N
dd3043aa-39a8-43d5-8c3b-2dc6bdbac4ac	cmofmpqxp0000tms4st6fcb8x	JAWAHAR GAJWANI ( DIRECTOR )	Sundry Creditors	\N	\N	0.00	Unregistered
f6e1a1df-0933-463b-a28f-936e883ae4e4	cmofmpqxp0000tms4st6fcb8x	JAWAHAR GAJWANI ( REMUNERATION )	Sundry Creditors	\N	\N	0.00	\N
9d7d9c9f-97da-4056-97fc-37759639e5c4	cmofmpqxp0000tms4st6fcb8x	Jawahar Gajwani(Unsecured Loans)	Unsecured Loans	\N	\N	4970757.00	\N
1eddd324-9576-4c2b-9c4f-4f6e5e2b7c61	cmofmpqxp0000tms4st6fcb8x	JEERA BAKING TROLLY	Fixed Assets	\N	\N	-42000.00	\N
c59790cf-740e-47f5-9b0b-8fbdb193557e	cmofmpqxp0000tms4st6fcb8x	Jignesh Bajaj	BAJAJ JI	\N	\N	0.00	\N
a9bf6bbe-a468-498a-8a53-549841c96af9	cmofmpqxp0000tms4st6fcb8x	JITENDRA BAJAJ	BAJAJ JI	\N	\N	0.00	\N
6edd97c3-77a7-4616-8bf3-2f1b9898b743	cmofmpqxp0000tms4st6fcb8x	Jumbotail Wholesale Private Limited	Sundry Debtors	\N	\N	0.00	\N
726becf7-9b29-4b49-9b88-ea2cfac096e3	cmofmpqxp0000tms4st6fcb8x	JYOTI JAISWAL-SULTANPUR	Ashutosh Ji	\N	\N	0.00	\N
10d98d63-e229-4bbc-a00c-12249f6ffb7f	cmofmpqxp0000tms4st6fcb8x	Jyoti Sweaper	Staff & Worker ( SALARY )	\N	\N	0.00	\N
377b124b-90a0-4347-b36f-77e59c5c6fe0	cmofmpqxp0000tms4st6fcb8x	KAILASH BAKARY, RAIL BAZAR	AMAR SONKAR	\N	\N	0.00	\N
82139cd5-5ca0-4ec3-9ed0-b4d5348a4063	cmofmpqxp0000tms4st6fcb8x	Kailash Mishthan Bhandar	Sundry Creditors -Exp	\N	\N	0.00	\N
8b535957-a30a-4c2e-912a-15c118c40cda	cmofmpqxp0000tms4st6fcb8x	Kailash Store, Lucknow	KAVITA	\N	\N	0.00	\N
333782b1-402e-436d-ad59-1277d7dcd9dd	cmofmpqxp0000tms4st6fcb8x	Kalloo Packing	Staff & Worker ( SALARY )	\N	\N	0.00	\N
1a128623-2ad4-48ab-a5b9-8bbbad6b1bd3	cmofmpqxp0000tms4st6fcb8x	KALYANI GENERAL STORE, FATEHPUR-84	Shivoham Shukla Parties	\N	\N	0.00	\N
a5fb99f6-2a99-4627-9a97-de5511b68831	cmofmpqxp0000tms4st6fcb8x	KAMAL BAJAJ	BAJAJ JI	\N	\N	0.00	\N
07209303-0f41-428c-a980-d61e8a1b4f97	cmofmpqxp0000tms4st6fcb8x	Kamal Bajpai	BAJAJ JI NEW	\N	\N	0.00	\N
8e55f5e0-d6b0-4f8e-818b-d213c44d64cc	cmofmpqxp0000tms4st6fcb8x	KAMAL LOADING (STAFF)	Staff & Worker ( SALARY )	\N	\N	0.00	\N
090c7ed1-d35e-434e-b819-32cdce4d672b	cmofmpqxp0000tms4st6fcb8x	Kamdhenu Textiles	Sundry Creditors -Exp	\N	\N	0.00	\N
ab88267a-d62d-4aab-93dc-359fd9e3307a	cmofmpqxp0000tms4st6fcb8x	Kamlesh	Staff & Worker ( SALARY )	\N	\N	0.00	\N
5f6d413b-98a1-4997-8bd5-9472bc101f5b	cmofmpqxp0000tms4st6fcb8x	Kamlesh Bajaj	BAJAJ JI	\N	\N	0.00	\N
f184123c-f5f6-4635-8e9e-b0825d525a55	cmofmpqxp0000tms4st6fcb8x	Kamlesh Sweaper	Staff & Worker ( SALARY )	\N	\N	0.00	\N
11987da8-43d2-4093-8446-1368902a9fb2	cmofmpqxp0000tms4st6fcb8x	Kanchan Jain D-33 ( ELECTRICITY )	RENT ( D-33 )	\N	\N	0.00	\N
70260c89-4ba8-45a1-96f2-85f8fc78957b	cmofmpqxp0000tms4st6fcb8x	Kanchan Jain D-33 (Rent) CASH	RENT ( D-33 )	\N	\N	-75000.00	\N
af734faf-2a10-4b22-a195-53a212f64346	cmofmpqxp0000tms4st6fcb8x	Kanha Enterprises, Farrukhabad	Sundry Debtors	\N	\N	0.00	\N
aa9b5cc4-ef64-4c7e-966c-261e6f12dc8b	cmofmpqxp0000tms4st6fcb8x	KANHAIYA AGENCIES, KANPUR	Sundry Debtors	\N	\N	0.00	\N
35e71fdc-6372-4272-9205-0573a71222ec	cmofmpqxp0000tms4st6fcb8x	KANHAIYA TRIPATHI, LUCKNOW	Lucknow Distributor	\N	\N	0.00	\N
65f66073-0454-4836-8f81-6fda07794d4d	cmofmpqxp0000tms4st6fcb8x	KANPUR NAGAR NIGAM ( SAFAI )	Sundry Creditors -Exp	\N	\N	0.00	\N
690912dc-9074-410d-851e-85013c2547a2	cmofmpqxp0000tms4st6fcb8x	KANTA MADAM	Sundry Debtors	\N	\N	0.00	\N
bdf33f67-6284-4eea-9c92-08a5af0414b0	cmofmpqxp0000tms4st6fcb8x	KAPIL SWEAPER	Staff & Worker ( SALARY )	\N	\N	0.00	\N
30597913-7843-4906-871b-da33ac943b46	cmofmpqxp0000tms4st6fcb8x	KARAN BAJAJ	BAJAJ JI	\N	\N	0.00	\N
4a3d9244-bd35-40a1-ac8f-e553aef3b152	cmofmpqxp0000tms4st6fcb8x	KARAN BAJPAI	BAJAJ JI	\N	\N	0.00	\N
11e34f68-0102-4e5a-b193-bab93af2ca14	cmofmpqxp0000tms4st6fcb8x	Kavita Agencies, Lucknow	KAVITA	\N	\N	0.00	\N
89af161e-baee-48e7-8c9a-6896cb9ea83e	cmofmpqxp0000tms4st6fcb8x	Kavita Agencies ( Salesmen- Salary ) VARSHA	KAVITA	\N	\N	0.00	\N
c91cf74f-49a5-43aa-a918-16463ea0b805	cmofmpqxp0000tms4st6fcb8x	KAVITA SUPPLIER	Sundry Debtors	\N	\N	0.00	\N
e05cdba4-d653-4bfa-a994-c621a225908a	cmofmpqxp0000tms4st6fcb8x	KEDIA CORPORATION	CONVEYAR	\N	\N	0.00	\N
7d911d1b-9e70-4cb0-93cd-9953202af0b4	cmofmpqxp0000tms4st6fcb8x	KENT RO Water Purifier	Fixed Assets	\N	\N	-2840.15	\N
3e6acbeb-527f-4e65-a329-70898b3ef604	cmofmpqxp0000tms4st6fcb8x	KESCO , Kanpur( D-35 )	Direct Expenses	\N	\N	0.00	\N
31f5e321-4968-474f-b6ae-19af5f0ad289	cmofmpqxp0000tms4st6fcb8x	Keshav Bajpai	BAJAJ JI	\N	\N	0.00	\N
8a82da2f-0b00-4cde-8692-8beed818767a	cmofmpqxp0000tms4st6fcb8x	Keshav Lal	BAJAJ JI	\N	\N	0.00	\N
a28be8cf-c2db-40a4-9c7b-2baa335174e1	cmofmpqxp0000tms4st6fcb8x	KESHAV LOADING	Sundry Debtors	\N	\N	0.00	\N
851fdd9c-1ca6-45db-b3e4-a176779cc654	cmofmpqxp0000tms4st6fcb8x	KESHAV TRIVEDI	Staff & Worker ( SALARY )	\N	\N	0.00	\N
f36b6a1e-3adf-460a-9eae-2a09cce9a36a	cmofmpqxp0000tms4st6fcb8x	KGN ENTERPRISES	Sundry Creditors	\N	\N	0.00	\N
f56cc67c-dd1e-4adb-ab4e-506aea28a7ae	cmofmpqxp0000tms4st6fcb8x	KGR POLYMERS PRIVATE LIMITED	Sundry Creditors	\N	\N	0.00	\N
541d0ef8-e27b-4b30-baa6-2a381e83cd5b	cmofmpqxp0000tms4st6fcb8x	Khairul	Sipahi	\N	\N	-270681.00	\N
08137f08-195c-4822-b85f-0c48bdcb9dc8	cmofmpqxp0000tms4st6fcb8x	KHANNA AUTO SALES PVT LTD	Sundry Creditors -Exp	\N	\N	-150679.00	\N
fc51521e-bf3f-4b00-8b2a-b46292d6bff8	cmofmpqxp0000tms4st6fcb8x	KHAN SABH	Sundry Debtors	\N	\N	0.00	\N
322f58af-4e3b-4ae0-aed5-6ee8a675ade8	cmofmpqxp0000tms4st6fcb8x	Khan Shahab	Sundry Creditors -Exp	\N	\N	0.00	\N
a678873e-b394-4c87-a65e-e9d09b922f20	cmofmpqxp0000tms4st6fcb8x	KHATRI &amp; MEHROTRA	Sundry Creditors -Exp	\N	\N	3100.00	\N
0709f6a6-5894-4227-b543-cb778a1ccff4	cmofmpqxp0000tms4st6fcb8x	KHUMESH BABU, DIBIYAPUR	DIBIYAPUR	\N	\N	0.00	\N
d26876a1-907e-49d8-b97b-b3f0c15b7e28	cmofmpqxp0000tms4st6fcb8x	KIRTI UDYOG ( Creditor )	CREDITORS ( DIPESH JI )	\N	\N	35500.00	\N
b9df33dd-1b9b-4452-9183-c6ccc075b16f	cmofmpqxp0000tms4st6fcb8x	KISAN TANKS PRIVATE	Sundry Creditors -Exp	\N	\N	0.00	\N
580c89d1-41ea-4289-b1b2-affa65eea6cf	cmofmpqxp0000tms4st6fcb8x	KISHAN ( LOADER )	FREIGHT OUTWORD	\N	\N	0.00	\N
9962ea99-69ec-4cd0-80bf-10cafb94f95e	cmofmpqxp0000tms4st6fcb8x	KISHAN SAHU	ANANTRAM JI	\N	\N	0.00	\N
e3192f57-e61b-42f7-8e00-57094aff8135	cmofmpqxp0000tms4st6fcb8x	Kishan Sales	Sundry Creditors -Exp	\N	\N	0.00	\N
aee410e7-e10b-4856-b44b-18d954575b00	cmofmpqxp0000tms4st6fcb8x	KISHORE RAMCHANDANI	Sundry Debtors	\N	\N	0.00	\N
e328decc-4ea3-4311-8fe3-3172620d3a35	cmofmpqxp0000tms4st6fcb8x	KISMAT- SIPAHI	Sipahi	\N	\N	0.00	\N
6edf796b-8b15-42a0-b83a-98715a5a7121	cmofmpqxp0000tms4st6fcb8x	KOHLI AGENCIES	Sundry Debtors	\N	\N	0.00	\N
b5e7e819-f85c-4ca0-9e79-31bd792b6765	cmofmpqxp0000tms4st6fcb8x	Kotak Emerging Equity Scheme	Investments	\N	\N	-5000.00	\N
9074b561-097a-47a9-b924-60a3b7460a46	cmofmpqxp0000tms4st6fcb8x	Kotak Mutual Fund	Investments	\N	\N	0.00	\N
4f63779d-78d1-4ac3-9b1f-038643e0e33c	cmofmpqxp0000tms4st6fcb8x	KRISHNA GUPTA , SHUKLAGANJ	SHUKLAGANJ	\N	\N	0.00	\N
d55c3832-8abd-4c54-a20a-7f94f442d7c6	cmofmpqxp0000tms4st6fcb8x	KRISHNA HARDWARE AND BARTAN BHANDAR	Sundry Creditors	\N	\N	0.00	\N
2970ca86-a9af-41ad-92a0-782e856a918b	cmofmpqxp0000tms4st6fcb8x	KULDEEP BAJAJ	BAJAJ JI	\N	\N	0.00	\N
f94a38cf-4751-48fa-8977-cf76628990b5	cmofmpqxp0000tms4st6fcb8x	Kumar Advertisers	Sundry Creditors -Exp	\N	\N	0.00	\N
d3969d8e-8e6d-4641-be73-fc2ea0b01056	cmofmpqxp0000tms4st6fcb8x	KUMAR G CONFECTIONERY-BANARAS	Sundry Debtors	\N	\N	0.00	\N
0b7f7e91-c182-4956-b705-77fdf2914d85	cmofmpqxp0000tms4st6fcb8x	KUMAR G CONFECTIONERY, VARANASI(Ok)	Shivoham Shukla Parties	\N	\N	-8434.00	\N
632ea740-3b7e-4d31-bdcc-3647341315ba	cmofmpqxp0000tms4st6fcb8x	KUMAR SAHU	ANANTRAM JI	\N	\N	0.00	\N
58267f0e-0eb3-4ecd-a222-136591c7fb5c	cmofmpqxp0000tms4st6fcb8x	KUMKUM ARSHIT ENTERPRISES	Sundry Creditors	\N	\N	0.00	\N
0189f10f-2ebd-4ecb-98bf-2bc84c3daf5f	cmofmpqxp0000tms4st6fcb8x	KUSHAGRA JAISWAL	Unsecured Loans	\N	\N	0.00	\N
96cec2fe-6600-437f-b5ad-1fb942f0cb40	cmofmpqxp0000tms4st6fcb8x	KWALITEX HEALTHCARE PRIVATE LIMITED	Sundry Creditors	\N	\N	0.00	\N
d59403e0-57ec-4f84-be63-ed1fd525f9ce	cmofmpqxp0000tms4st6fcb8x	KWALITY ENGINEERING WORKS	Sundry Creditors	\N	\N	0.00	\N
a4da5ac0-e07b-4357-a3ba-2eaa05d864e5	cmofmpqxp0000tms4st6fcb8x	Lakhan Bajaj	BAJAJ JI	\N	\N	0.00	\N
5a3f4f96-6961-4416-80b9-1ea0ce05bc6e	cmofmpqxp0000tms4st6fcb8x	LAL BABU CARPENTOR 25/12	Office Exp	\N	\N	0.00	\N
17dc5d2d-fe64-422b-a7f1-8f9bc7835a27	cmofmpqxp0000tms4st6fcb8x	LALLAN - SIPAHI	Sipahi	\N	\N	0.00	\N
31526535-a02b-48b2-a408-e5feb0f1b748	cmofmpqxp0000tms4st6fcb8x	Land	Fixed Assets	\N	\N	-20832900.00	\N
ff8a6c95-457e-4464-9afe-ea6a713c9057	cmofmpqxp0000tms4st6fcb8x	Lata Sales, MAGRASA	Ashutosh Ji	\N	\N	0.00	\N
e675a152-fb1b-447f-b3c6-aad8735f1b30	cmofmpqxp0000tms4st6fcb8x	LATE FEES	Indirect Expenses	\N	\N	0.00	\N
4419e535-87e3-4e02-b039-370716d54992	cmofmpqxp0000tms4st6fcb8x	LEAVE A/C	Indirect Expenses	\N	\N	0.00	\N
7ddc2e05-69cb-4ad3-91d7-8fe4b80f2b6c	cmofmpqxp0000tms4st6fcb8x	LEGAL EXP 18%	Legal Expenses	\N	\N	0.00	\N
838d5b58-08da-45fb-b7d2-1d683928addf	cmofmpqxp0000tms4st6fcb8x	LEGAL EXPENCES	Legal Expenses	\N	\N	0.00	\N
0b288062-4494-478f-9eb6-88a390afe682	cmofmpqxp0000tms4st6fcb8x	LETTER HOLDER	Fixed Assets	\N	\N	0.00	\N
2af2d003-c6c5-4bd2-8a92-35159d5afbd7	cmofmpqxp0000tms4st6fcb8x	LG MICROWAV-MC2146BV	Fixed Assets	\N	\N	-9322.03	\N
7c003353-8bb9-4bdf-80df-6c5e5f85c3ef	cmofmpqxp0000tms4st6fcb8x	LG WASHING MACHINE -T70SKSF1Z	Fixed Assets	\N	\N	-14406.77	\N
d41876fd-0d92-4098-a2b9-47847095bbcf	cmofmpqxp0000tms4st6fcb8x	Livekeeping Technologies Private Limited	Sundry Creditors -Exp	\N	\N	0.00	\N
45f2e923-7499-46c3-8c91-9ebb6e2969d0	cmofmpqxp0000tms4st6fcb8x	LODING / UNLODING	Direct Expenses	\N	\N	0.00	\N
4b2c6f98-fb27-4938-8a91-e370527f0375	cmofmpqxp0000tms4st6fcb8x	LORD ADVERTISING COMPANY	Sundry Creditors	\N	\N	0.00	\N
6bc0b979-c650-4774-afd4-83e54931344a	cmofmpqxp0000tms4st6fcb8x	Loss on Sale	Indirect Expenses	\N	\N	0.00	\N
54ef5eea-67df-4775-9d92-9a69c8e37fdd	cmofmpqxp0000tms4st6fcb8x	Lpg Cylinder Ndne 47.5 Kg	Consumable Expenses	\N	\N	0.00	\N
42ba0549-c493-45a1-af99-6d30b8357ff8	cmofmpqxp0000tms4st6fcb8x	Lpg Gas - AFAK	Consumable Expenses	\N	\N	0.00	\N
ef4a7d9b-77b3-4efe-befc-590264f911b6	cmofmpqxp0000tms4st6fcb8x	Lpg Gas - BABLU	Consumable Expenses	\N	\N	0.00	\N
ae6fd8c1-4564-43b5-82db-0519a962f7ac	cmofmpqxp0000tms4st6fcb8x	Lpg Gas - CHITRA	Consumable Expenses	\N	\N	0.00	\N
a90e1a38-2f70-4cf5-ab44-065a85fafc11	cmofmpqxp0000tms4st6fcb8x	Lpg Gas - NEW KARIGAR	Consumable Expenses	\N	\N	0.00	\N
5988326d-c785-47c9-88d5-56cd0bc2c786	cmofmpqxp0000tms4st6fcb8x	LPG-GAS RAJESH BISCUITS	Consumable Expenses	\N	\N	0.00	\N
e26b61d6-5d52-48f6-8661-863f031fddb3	cmofmpqxp0000tms4st6fcb8x	Lpg Gas - SIPAHILAL	Consumable Expenses	\N	\N	0.00	\N
da366d1f-9e9b-4dc3-9e1f-bd343d4d1b4f	cmofmpqxp0000tms4st6fcb8x	LUCKY	FREIGHT OUTWORD	\N	\N	0.00	\N
e7ec50b0-c333-44e6-a50e-c67929a41b78	cmofmpqxp0000tms4st6fcb8x	Lucky Sahu	ANANTRAM JI	\N	\N	0.00	\N
8caa9b73-ff74-42e1-afd9-3c81ee3cd6c5	cmofmpqxp0000tms4st6fcb8x	MAA BHAGWATI LAIYA CHANA BHANDAR	Sundry Creditors	\N	\N	0.00	\N
fa4b2123-2ca7-4ed9-b48b-2987bc9612a3	cmofmpqxp0000tms4st6fcb8x	Maa Laxmi Traders	Gaurav, LUCKNOW	\N	\N	0.00	\N
5458769a-94c3-45fe-81a1-515c3da65bb3	cmofmpqxp0000tms4st6fcb8x	Maa Laxmi Traders (NIGHASAN)	DILIP PANDYE	\N	\N	-45636.00	\N
a4b1b7b4-e6cb-4d18-b377-0933e29590d2	cmofmpqxp0000tms4st6fcb8x	MAA PITAMBARA TRAVELS-LALITPUR	Lalitpur	\N	\N	0.00	\N
9774458d-0174-48c6-8b56-e218436f901b	cmofmpqxp0000tms4st6fcb8x	MAA VAISHNO PUBLICITY	Sundry Creditors	\N	\N	0.00	\N
4be6a7c3-9669-44b0-a05e-6a38858a9823	cmofmpqxp0000tms4st6fcb8x	Maa Vaishno Traders, MAHOLI ( Sitapur )	Gaurav, LUCKNOW	\N	\N	0.00	\N
3316071f-21b2-4f89-9c08-2c3003ba85e0	cmofmpqxp0000tms4st6fcb8x	MACHINE SPARE SPARTS (ASHIRWAD TEC)	Fixed Assets	\N	\N	-8000.00	\N
3f2da103-3495-40d2-8900-7b08f7c814c9	cmofmpqxp0000tms4st6fcb8x	Madhuban Barcoading Solutions	Sundry Creditors	\N	\N	0.00	\N
ad397333-3dca-461f-bd54-da0d9bd68552	cmofmpqxp0000tms4st6fcb8x	MADHURAM SWEETS	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
27102b7b-c97e-4c98-afda-aac72bb6c02b	cmofmpqxp0000tms4st6fcb8x	Mahadev Agency-Sultanpur	OUT OF KANPUR	\N	\N	-386.00	\N
3ffe316f-c819-4ba8-af9a-bbed545cfbdc	cmofmpqxp0000tms4st6fcb8x	Mahadev Enterprises	CREDITORS ( DIPESH JI )	\N	\N	891975.80	\N
d33c93e1-ebca-45ba-8a40-659dde1644f2	cmofmpqxp0000tms4st6fcb8x	MAHAVEER TRADERS , BISWAN	Gaurav, LUCKNOW	\N	\N	0.00	\N
042b32ee-3230-4d39-9288-80d778e501e4	cmofmpqxp0000tms4st6fcb8x	Mahesh Bajpai	BAJAJ JI	\N	\N	0.00	\N
5c9a33b4-ab52-4070-8c8a-ec41a785032a	cmofmpqxp0000tms4st6fcb8x	MAHESH CHANDRA , AIT	Ashutosh Ji	\N	\N	0.00	\N
81572d17-5fc0-439d-a471-913ece6d8710	cmofmpqxp0000tms4st6fcb8x	MAHESH JI	BAJAJ JI	\N	\N	0.00	\N
9b578f17-a5ba-4623-b870-ef9637513811	cmofmpqxp0000tms4st6fcb8x	MALIK PETROLIUM	Sundry Creditors	\N	\N	0.00	\N
bc244c8c-5332-4943-aff9-e14d82476a36	cmofmpqxp0000tms4st6fcb8x	MAMTA GAS AGENCY	Sundry Creditors	\N	\N	0.00	\N
3d25f1d2-d63f-4fdf-a70a-46244fb7edf5	cmofmpqxp0000tms4st6fcb8x	MAMTA STAFF	Staff & Worker ( SALARY )	\N	\N	0.00	\N
1ab32673-fd02-4180-ae7d-0406a1b834a4	cmofmpqxp0000tms4st6fcb8x	MANEESH SAHU	ANANTRAM JI	\N	\N	0.00	\N
78449e91-dec9-42e0-b9ec-6faf6f6ed5bc	cmofmpqxp0000tms4st6fcb8x	MANGO ( SALARY )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
b467c516-a7e6-41d7-a9fd-a2765f2881f5	cmofmpqxp0000tms4st6fcb8x	MANISH ENTERPRISES,, LALGANJ	Ashutosh Ji	\N	\N	0.00	\N
fa8c92e8-912a-484a-9275-a18807d3bd72	cmofmpqxp0000tms4st6fcb8x	Manish Tripathi Screaning	Sundry Creditors	\N	\N	0.00	\N
bf0e8b87-c1af-4184-9521-eb8350b2de1f	cmofmpqxp0000tms4st6fcb8x	MANOHAR BAJAJ	BAJAJ JI	\N	\N	0.00	\N
d52510fd-c1e3-4240-85c6-228e793eaa1e	cmofmpqxp0000tms4st6fcb8x	MANOHAR LOADING BILL	Sundry Debtors	\N	\N	0.00	\N
c096da35-d6ed-4f21-8a5a-60088179a49f	cmofmpqxp0000tms4st6fcb8x	Manohar Loading Staff	Staff & Worker ( SALARY )	\N	\N	0.00	\N
78cce5b9-371b-4514-a6c0-10d289938b71	cmofmpqxp0000tms4st6fcb8x	MANOHAR SAHU	ANANTRAM JI	\N	\N	0.00	\N
8244f7da-2caa-41dc-a221-4114f93b76e8	cmofmpqxp0000tms4st6fcb8x	MANOJ BAJPAI	BAJAJ JI	\N	\N	0.00	\N
fd4144dd-28c9-432a-b962-9396de720fd5	cmofmpqxp0000tms4st6fcb8x	MANOJ COOL HOME	Sundry Creditors	\N	\N	0.00	\N
0350004b-20aa-4107-89ba-02d4e97b3c53	cmofmpqxp0000tms4st6fcb8x	MANOJ ELEC	Sundry Debtors	\N	\N	0.00	\N
841b6ab9-f1a0-4d7f-a6b5-a17a83d5c688	cmofmpqxp0000tms4st6fcb8x	MANOJ KUMAR ( ELECTRICIAN )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
ddcf729b-5a3a-4739-94cb-4ec6b0ad6f97	cmofmpqxp0000tms4st6fcb8x	MANOJ TRADERS	ANANTRAM JI	\N	\N	0.00	\N
467bf91c-ed6f-4faf-b70e-7d71f509a882	cmofmpqxp0000tms4st6fcb8x	Manoj Traders, KATNI	Ashutosh Ji	\N	\N	0.00	\N
5c9c2700-99ec-4513-822c-32f2292618b7	cmofmpqxp0000tms4st6fcb8x	MA SANTOSHI ENTERPRISES	KANPUR	\N	\N	0.00	\N
367c06f6-c3d0-4ea8-ac6e-069185aa626c	cmofmpqxp0000tms4st6fcb8x	Matli (Jeera)	Staff & Worker ( SALARY )	\N	\N	0.00	\N
c92fddb0-8b63-4e30-ad4f-61d5dc4b8acd	cmofmpqxp0000tms4st6fcb8x	MD.HUSSAIN RAZA UNNAO	Raza Bhai Unnao	\N	\N	0.00	\N
16a93e55-903e-412a-be58-dc9b8b145857	cmofmpqxp0000tms4st6fcb8x	MEBLU - SIPAHI	Sipahi	\N	\N	0.00	\N
f3ed7835-9763-4500-a7b7-6de6ac1c930c	cmofmpqxp0000tms4st6fcb8x	MEENA ENTERPRISES	Sundry Creditors -Exp	\N	\N	0.00	\N
4b45c8f1-5df1-46c3-819f-e4f40cea2b2d	cmofmpqxp0000tms4st6fcb8x	Meena Ji Packing	Staff & Worker ( SALARY )	\N	\N	0.00	\N
92a53130-ebb6-4031-b129-3587aab1d760	cmofmpqxp0000tms4st6fcb8x	Metro Essence Mart	CREDITORS ( DIPESH JI )	\N	\N	2.00	\N
a4871b44-6369-4ce1-a6b2-2eb88197ea02	cmofmpqxp0000tms4st6fcb8x	MINERAL OIL CORPORATION PRIVATE LIMITED	Sundry Debtors	\N	\N	0.00	\N
ba6453be-5692-422a-9190-8c01c7b3f17d	cmofmpqxp0000tms4st6fcb8x	Misc. Expenses	Indirect Expenses	\N	\N	0.00	\N
0e9aecd7-feaa-439a-b1c7-53b3ab07e108	cmofmpqxp0000tms4st6fcb8x	Misc. Expenses  D.G.	Indirect Expenses	\N	\N	0.00	\N
8d4cd8f6-1443-4295-9022-2c9ec9b1b879	cmofmpqxp0000tms4st6fcb8x	Misc. Income	Indirect Incomes	\N	\N	0.00	\N
127a60d0-4f9e-49bf-8adc-4b52ebab1368	cmofmpqxp0000tms4st6fcb8x	MISC P	Sundry Debtors	\N	\N	0.00	\N
8806e5b1-8bbb-45e2-a7a9-9cb075a69051	cmofmpqxp0000tms4st6fcb8x	Mixer B10B	Fixed Assets	\N	\N	-21521.83	\N
dbd13b49-2f67-4186-9aac-1312846c4d3e	cmofmpqxp0000tms4st6fcb8x	MIXTURE GATTU@18%	Fixed Assets	\N	\N	-125000.00	\N
efaddbca-98a4-4527-a4f5-eb23a5399590	cmofmpqxp0000tms4st6fcb8x	M K Food	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
45bf6c4c-545f-451a-92da-a2a57bb21d35	cmofmpqxp0000tms4st6fcb8x	M.K. Traders, SANDILA	DILIP PANDYE	\N	\N	0.00	\N
b36d9c90-5d1c-4405-8ab1-689b55243a1b	cmofmpqxp0000tms4st6fcb8x	Mm Bajaj	BAJAJ JI	\N	\N	0.00	\N
e7ec23be-4262-4591-bf29-a2e0b8eac0a0	cmofmpqxp0000tms4st6fcb8x	M. M. FOODS-VARANASI	Ashutosh Ji	\N	\N	0.00	\N
499d3574-9ffc-4fed-81db-83735f76c837	cmofmpqxp0000tms4st6fcb8x	Mobile &amp; Internet Charges	Indirect Expenses	\N	\N	0.00	\N
c7c55545-5b9e-46f0-8663-76e034268c8c	cmofmpqxp0000tms4st6fcb8x	Mobile Phone	Fixed Assets	\N	\N	-101355.95	\N
d2735d11-4167-4c74-9479-c7b6251ff437	cmofmpqxp0000tms4st6fcb8x	MOHAMMAD ILYAS-Mahmudabad	Gaurav, LUCKNOW	\N	\N	-4986.00	\N
f396d760-0e2c-4de1-bc44-eee6a53b94c1	cmofmpqxp0000tms4st6fcb8x	MOHAMMAD SALIM-BANGERMAU	Ashutosh Ji	\N	\N	0.00	\N
91a355f0-8e69-4c28-af30-f186112d0938	cmofmpqxp0000tms4st6fcb8x	MOHAMMAS ARSHAD-JAHANABAD	Sundry Debtors	\N	\N	0.00	\N
a3ed79ba-1993-4adf-bea3-0db1559eb571	cmofmpqxp0000tms4st6fcb8x	Mohan Bajaj	BAJAJ JI	\N	\N	0.00	\N
1826a9f5-2691-4293-a52e-966fd2c78008	cmofmpqxp0000tms4st6fcb8x	MOHAN BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
b12b3d18-a0a6-4c1b-a6d8-f750c1f4fe88	cmofmpqxp0000tms4st6fcb8x	MOHAN SAHU	ANANTRAM JI	\N	\N	0.00	\N
dffde234-3caf-4604-ac2d-71bebbfacc4c	cmofmpqxp0000tms4st6fcb8x	Mohan Traders	ANANTRAM JI	\N	\N	0.00	\N
e85886e7-7c12-49f5-956d-db7ce843c9fb	cmofmpqxp0000tms4st6fcb8x	Mohd. GUFRAN	Staff & Worker ( SALARY )	\N	\N	0.00	\N
bdba01f1-19a1-444e-b07f-0ca771c06108	cmofmpqxp0000tms4st6fcb8x	Mohd. Misbah Uddin, Allahabad	ALLAHABAD	\N	\N	0.00	\N
adef447d-f4fb-4630-9894-58e4b1c6c7e3	cmofmpqxp0000tms4st6fcb8x	MOHD. RAFI, LAHARPUR	Gaurav, LUCKNOW	\N	\N	0.00	\N
9dcd6d75-d78d-430a-bf38-58b2252ea687	cmofmpqxp0000tms4st6fcb8x	MOHD SAMI, BINDKI	DILIP PANDYE	\N	\N	0.00	\N
1722f285-de9b-4dcb-8fe2-638c789347f4	cmofmpqxp0000tms4st6fcb8x	Mohd. Shameem, Lucknow	Lucknow Distributor	\N	\N	0.00	\N
7b471f21-499f-4048-b9b4-57e4d6000f78	cmofmpqxp0000tms4st6fcb8x	MOHINI NAMKEEN EXPRESS ROAD	AMAR SONKAR	\N	\N	-3100.00	\N
2357d795-f087-4275-85c6-8a85e5c216c1	cmofmpqxp0000tms4st6fcb8x	MOHINI STORE, NAYA GANJ	AMAR SONKAR	\N	\N	0.00	\N
d0f96ae3-943d-4742-96e6-b1aa6904f9a8	cmofmpqxp0000tms4st6fcb8x	Mohit Bajaj	BAJAJ JI	\N	\N	0.00	\N
0cad6926-0339-46e4-9abe-ed4558d91d60	cmofmpqxp0000tms4st6fcb8x	Mohit Mishra ( 13/3/23 )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
4a3f9aa4-8c57-4619-ae5e-c02ab342d910	cmofmpqxp0000tms4st6fcb8x	MOHIT MISHRA ( TOUR )	Sundry Creditors(Tour)	\N	\N	0.00	\N
63d28d02-ffe3-45c5-a37f-ebd89cc3bc7b	cmofmpqxp0000tms4st6fcb8x	MOHIT SAHU	ANANTRAM JI	\N	\N	0.00	\N
d3a2effd-bbab-4917-901a-308cd41d05cb	cmofmpqxp0000tms4st6fcb8x	MOHIT TRADING CO.	Sundry Creditors -Exp	\N	\N	0.00	\N
ef746a1b-b57c-470a-9c07-740f1e3f87ba	cmofmpqxp0000tms4st6fcb8x	MOHSIN ENTERPRISES, ETAWAH	DILIP PANDYE	\N	\N	0.00	\N
0d0905c4-fadb-4846-9228-ca4f347d54ef	cmofmpqxp0000tms4st6fcb8x	Moni Packing	Staff & Worker ( SALARY )	\N	\N	0.00	\N
4068ff74-2de5-4d96-b26e-007669242cd5	cmofmpqxp0000tms4st6fcb8x	MONU BAJAJ	BAJAJ JI NEW	\N	\N	0.00	\N
68a39393-e289-485c-98ce-286cae845831	cmofmpqxp0000tms4st6fcb8x	MONU MOHIT &amp; BROTHERS	Sundry Debtors	\N	\N	0.00	\N
8f9880ce-5c0a-4322-9ee5-4636aef5f30d	cmofmpqxp0000tms4st6fcb8x	MONU SAHU	ANANTRAM JI	\N	\N	0.00	\N
9a990d9f-4edc-4a2a-bd7e-ca75a0274ef0	cmofmpqxp0000tms4st6fcb8x	MONU STORE,Chanal Road	AMAR SONKAR	\N	\N	-640.00	\N
5eddef89-7104-45f7-8fa2-185d472989ec	cmofmpqxp0000tms4st6fcb8x	MOOLCHAND PUNJABI SONS-LAKHIMPUR	OUT OF KANPUR	\N	\N	-110453.00	\N
6536e2ba-1ea6-480d-9d87-479359d62521	cmofmpqxp0000tms4st6fcb8x	Moped	Fixed Assets	\N	\N	-6041.31	\N
4b762ba3-27ca-4db3-ac82-f16e890e46df	cmofmpqxp0000tms4st6fcb8x	MOTI JHEEL	Sundry Debtors	\N	\N	0.00	\N
9b3c6591-953f-4321-a598-e97b4a86a7e0	cmofmpqxp0000tms4st6fcb8x	MOTILAL MUTURE FUND	Investments	\N	\N	0.00	\N
4345509a-373a-440b-8d20-96820c24bc67	cmofmpqxp0000tms4st6fcb8x	MOTOR (GATTU OVEN)	Fixed Assets	\N	\N	-13409.22	\N
c3ec8ee7-3e90-4540-a8dc-0efe34325083	cmofmpqxp0000tms4st6fcb8x	MOULDER (C.S)	Fixed Assets	\N	\N	-225000.00	\N
0107bd87-3af7-4c7d-a558-8bfd5d668e60	cmofmpqxp0000tms4st6fcb8x	MRADUL BAJAJ	BAJAJ JI	\N	\N	0.00	\N
e57b258e-75f7-4924-a617-f51bf9b9a8ae	cmofmpqxp0000tms4st6fcb8x	MRIDUL SAHU	ANANTRAM JI	\N	\N	0.00	\N
329d9ac7-4c79-439d-9a37-6ed09a4f187c	cmofmpqxp0000tms4st6fcb8x	MRIGAKSHI ENTERPRISES, LUCKNOW	Lucknow Distributor	\N	\N	-28.00	\N
a2465034-2c8e-4f2b-b481-5ba47662d85e	cmofmpqxp0000tms4st6fcb8x	M/S AARNI TRADING COMPANY	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
578feddf-2ff8-47c0-b04f-7b2c164fdf5c	cmofmpqxp0000tms4st6fcb8x	M/S AASHITA TRADERS-FARRUKHABAD	OUT OF KANPUR	\N	\N	0.00	\N
3b295d38-62c4-4277-b9d5-4c900fbb202b	cmofmpqxp0000tms4st6fcb8x	M/s Aazmi General Store, BISWAN	Gaurav, LUCKNOW	\N	\N	0.00	\N
9b39f115-2478-49f5-9eb5-f85eac42bfce	cmofmpqxp0000tms4st6fcb8x	M/s Abhay Trading Company, RURA	Sundry Debtors	\N	\N	0.00	\N
15808a0e-5d26-4274-824b-66b101edd8c9	cmofmpqxp0000tms4st6fcb8x	M/s Adarsh Bakery Shop	Sundry Debtors	\N	\N	0.00	\N
d7e6233b-16e4-4067-ad17-79cfaa8144e5	cmofmpqxp0000tms4st6fcb8x	M/S ADKON WEIGHING SOLUTION	Sundry Creditors	\N	\N	0.00	\N
793626b5-5844-40b6-a6d4-116941757497	cmofmpqxp0000tms4st6fcb8x	M/S AGARWAL STEEL TRADERS	Sundry Creditors	\N	\N	0.00	\N
ce9594f1-1d97-4de0-b918-895daef2ac8c	cmofmpqxp0000tms4st6fcb8x	M/S A. G. MARKETING	Sundry Creditors	\N	\N	0.00	\N
44709348-028e-4b52-934c-36be4cef118a	cmofmpqxp0000tms4st6fcb8x	M/S AKHILESH KIRANA STORES, GURSARAI	SATISH	\N	\N	0.00	\N
ec987567-1cf4-464b-ad7d-c8b6b07efd84	cmofmpqxp0000tms4st6fcb8x	M/S AMCO SALES	Sundry Creditors	\N	\N	0.00	\N
6c58d0cb-12c4-40cc-8308-d6f8aba42868	cmofmpqxp0000tms4st6fcb8x	M/s Amit Pipes &amp; Hardwares	Sundry Creditors -Exp	\N	\N	0.00	\N
962a7467-8aa5-40cb-aef4-0cc67357d348	cmofmpqxp0000tms4st6fcb8x	M/S ANG SANG SECURITIES	Sundry Creditors	\N	\N	0.00	\N
d15a4ce5-87a8-473c-99d9-98eb8e034cbd	cmofmpqxp0000tms4st6fcb8x	M/S ANIL COOLER WORKS	Sundry Creditors	\N	\N	0.00	\N
239adc78-3b48-4cde-b985-24f7615cf1ba	cmofmpqxp0000tms4st6fcb8x	M/s Anuradha Automation	Sundry Creditors -Exp	\N	\N	0.00	\N
ea153870-6853-42e2-b632-6b3416e9cf81	cmofmpqxp0000tms4st6fcb8x	M/S ARBISH TRADERS	BAJAJ JI	\N	\N	0.00	\N
d24f8514-3070-4c47-9a49-13e7609db083	cmofmpqxp0000tms4st6fcb8x	M/S BABA ANANDESHWAR TRADERS	KANPUR	\N	\N	0.00	\N
38931628-b99e-487f-9c90-d392b1f47d73	cmofmpqxp0000tms4st6fcb8x	M/S BABA BATTERY SERVICE	Sundry Creditors	\N	\N	0.00	\N
f01f54a0-54b7-431d-8857-2b420a469547	cmofmpqxp0000tms4st6fcb8x	M/S BALAJI MACHINERY AND TOOLS	Sundry Creditors	\N	\N	0.00	\N
45d36fee-1af4-430d-b560-c705c0ea4325	cmofmpqxp0000tms4st6fcb8x	M/S BALAJI TRADERS-ORAI	OUT OF KANPUR	\N	\N	0.00	\N
7b01427f-0019-4bd1-9ac2-c9f6279b14ed	cmofmpqxp0000tms4st6fcb8x	M/S BYRAMJEE FRAMJEE AND COMPANY	Sundry Creditors	\N	\N	0.00	\N
ae876fe4-5e0f-46a0-8763-7eb234b29ffd	cmofmpqxp0000tms4st6fcb8x	M/S CHARAN FLOUR MILL P.LTD.	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
cd2eaf06-4007-45e4-934c-b2cdbe76815e	cmofmpqxp0000tms4st6fcb8x	M/S DADDY&apos;S CHOICE ENTERPRISES	Sundry Creditors	\N	\N	0.00	\N
5182555c-86aa-4a24-9e3d-73ce1ddc8169	cmofmpqxp0000tms4st6fcb8x	M/S DIL KHUSH TRADERS	Sundry Creditors -Exp	\N	\N	0.00	\N
5a54c428-1bac-47f4-a794-64da80c71ed8	cmofmpqxp0000tms4st6fcb8x	M/S DIXIT BROTHERS-LALGANJ	OUT OF KANPUR	\N	\N	-241.00	\N
5ec6ef38-060f-4f8e-b7ab-f589931b2d6c	cmofmpqxp0000tms4st6fcb8x	M/S DIXIT SALES	Sundry Creditors	\N	\N	0.00	\N
d2047cdf-13aa-4a2b-b49f-e220e0c405bd	cmofmpqxp0000tms4st6fcb8x	M/s D. K. Traders, KHALILABAD	OUT OF KANPUR	\N	\N	0.00	\N
06320684-d0c6-4809-b8e7-c09fcf03681b	cmofmpqxp0000tms4st6fcb8x	M/S FINE AIRCONDITIONING COMPANY	Sundry Creditors -Exp	\N	\N	0.00	\N
65994f72-e73d-4d43-bc8e-5fc2fe48fb2a	cmofmpqxp0000tms4st6fcb8x	M/S FRIENDS ELECTRICALS	Sundry Creditors	\N	\N	2921.90	\N
0f92489f-f331-41cd-b70e-a9db22e5a151	cmofmpqxp0000tms4st6fcb8x	M/S GANPATI GRAPHICS	CREDITORS ( DIPESH JI )	\N	\N	171372.00	\N
b7b40eac-1745-4a0d-8616-33a024b65655	cmofmpqxp0000tms4st6fcb8x	M/s  Golden Traders, Biswan ( Reosa )	Gaurav, LUCKNOW	\N	\N	0.00	\N
695044a5-1e6a-49d0-b3d3-c6645a9a4571	cmofmpqxp0000tms4st6fcb8x	M/S GOOD LIFE TECHNOLOGIES PVT.LTD.	Sundry Creditors	\N	\N	0.00	\N
a95c8477-abd7-4643-b547-7d17d74bda57	cmofmpqxp0000tms4st6fcb8x	M/S GOODWILL ENTERPRISES	Sundry Creditors	\N	\N	0.00	\N
e8e03bd9-e83b-469f-9767-9dc38cc38676	cmofmpqxp0000tms4st6fcb8x	M/S GOPI SPRAY MFRS. &amp; ENGRS.	Sundry Creditors	\N	\N	0.00	\N
50a53c29-e8c4-4a05-9ac8-cb5d3f7a6b07	cmofmpqxp0000tms4st6fcb8x	M/s Goyal Sons	Sundry Creditors -Exp	\N	\N	0.00	\N
0de1b7fd-ad18-4a28-a035-1a6ce56cf6ec	cmofmpqxp0000tms4st6fcb8x	M/S GURU KRIPA TRADERS LUCKNOW	KAVITA	\N	\N	0.00	\N
be329ac8-605c-404f-b06f-25b2107999a2	cmofmpqxp0000tms4st6fcb8x	M/S HARDWARE CENTRE	Sundry Creditors -Exp	\N	\N	0.00	\N
46498ed3-1116-4f7c-9578-bc3e7e03297e	cmofmpqxp0000tms4st6fcb8x	M/S HERITAGE GRANITES AND MARBLES	Sundry Creditors	\N	\N	0.00	\N
c8becb47-68f3-4b3b-aa5a-e23b650e9bfe	cmofmpqxp0000tms4st6fcb8x	M/S HINDUSTANI ENTERPRISES-JHANSI	SATISH	\N	\N	0.00	\N
762f528c-031b-4522-b7ef-1ae0d9d91ddb	cmofmpqxp0000tms4st6fcb8x	M/s Indian Industrial Lubricaints	Sundry Creditors	\N	\N	0.00	\N
88819cf4-f094-4876-a4c3-aaee3d23e69c	cmofmpqxp0000tms4st6fcb8x	M/S INDRESH ENTERPRISES	Sundry Creditors	\N	\N	0.00	\N
d6b3277a-2b3e-442e-9e75-99dc1080e4e5	cmofmpqxp0000tms4st6fcb8x	M/S JAI BHAGWAN TRADERS	Sundry Creditors	\N	\N	0.00	\N
89801c1b-d177-4b28-a114-2991ac867e84	cmofmpqxp0000tms4st6fcb8x	M/S JAIN MILL STORE	Sundry Creditors	\N	\N	0.00	\N
d39cbf58-c0ee-4f40-9d90-a5367a7f5e08	cmofmpqxp0000tms4st6fcb8x	M/S JAYA BEKARI SHOP-KHAGA	Shivoham Shukla Parties	\N	\N	0.00	\N
51163c67-460a-4ae7-8a78-e51a174cdf59	cmofmpqxp0000tms4st6fcb8x	M/S KANAK MARBLES	Sundry Creditors	\N	\N	0.00	\N
a54e2394-d310-48d0-b373-6abef6758fc9	cmofmpqxp0000tms4st6fcb8x	M/S KANSAL AGENCIES-KARWI	Ashutosh Ji	\N	\N	-70455.00	\N
2d9ec9ec-6c08-4c22-b7c3-588ec74b662e	cmofmpqxp0000tms4st6fcb8x	M/S KAPOOR STATIONERS	Sundry Creditors	\N	\N	0.00	\N
d084c49d-b549-4d1c-bd24-4a1beaea1a40	cmofmpqxp0000tms4st6fcb8x	M/s Khandelwal and Sons, MATHURA	OUT OF KANPUR	\N	\N	-32977.00	\N
e25ef837-82b8-4574-bbf0-266a40e80a6d	cmofmpqxp0000tms4st6fcb8x	M/s Khandelwals Jyoti, LUCKNOW	Lucknow Distributor	\N	\N	0.00	\N
dfc82f5a-3c36-4ef4-845e-aa762d0867be	cmofmpqxp0000tms4st6fcb8x	M/s Khanna Auto Sales Pvt.Ltd.	Sundry Creditors -Exp	\N	\N	5568.00	\N
294979fc-49c6-4689-bcd9-514b8cadfef1	cmofmpqxp0000tms4st6fcb8x	MS KISHAN LAL	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
e766ca6a-1031-4250-9036-e99fe7b858cd	cmofmpqxp0000tms4st6fcb8x	M/S K.J.AGENCIES	Sundry Creditors	\N	\N	0.00	\N
9af28888-6dac-4da7-a7a2-5407cd3da553	cmofmpqxp0000tms4st6fcb8x	M/S KRISHNA ELECTRIC INSTRUMENTS	Sundry Creditors	\N	\N	0.00	\N
1b1b259c-d1bf-41db-863f-b5fb29ef8f81	cmofmpqxp0000tms4st6fcb8x	M/S KRITIKA ENTERPRISES-Etawah	Shivoham Shukla Parties	\N	\N	0.00	\N
4ad07154-758e-4ae6-9a7c-70930c7f7276	cmofmpqxp0000tms4st6fcb8x	M/s K.V. Plastic Pvt. Ltd. RENT ( D-33 )	RENT ( D-33 )	\N	\N	0.00	\N
c99b7d6f-8ed7-404d-a3ff-834ff5e54864	cmofmpqxp0000tms4st6fcb8x	M/S LAKSHYA INTERNATIONAL	Sundry Creditors	\N	\N	0.00	\N
6349dd45-9191-4986-9ec3-601a1aad194a	cmofmpqxp0000tms4st6fcb8x	M/s Lucky Sanitary &amp; Tiles	Sundry Creditors -Exp	\N	\N	0.00	\N
80d9bde4-dbca-4b2b-833a-c1aaac3533e1	cmofmpqxp0000tms4st6fcb8x	M/S MADHUR PACKAGERS	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
71f8d92d-fbe7-44bf-95a6-7aacfb2fd30f	cmofmpqxp0000tms4st6fcb8x	M/s Mangalam Traders, BASTI	OUT OF KANPUR	\N	\N	0.00	\N
582eaa2c-80ce-47f5-8385-4a2892502451	cmofmpqxp0000tms4st6fcb8x	M/S MANOJ ELECTRICALS	Sundry Creditors	\N	\N	0.00	\N
1ac3169c-5025-4237-80c5-895489cadd05	cmofmpqxp0000tms4st6fcb8x	M/s  Manorama Trading Co	CREDITORS ( DIPESH JI )	\N	\N	2641523.88	\N
bbdaee14-f2ab-47ba-9a58-e226e1f26d42	cmofmpqxp0000tms4st6fcb8x	M/S MAYUR INDUSTRIES	Sundry Creditors	\N	\N	0.00	\N
7c1930af-1809-47d6-bba2-6440569c6950	cmofmpqxp0000tms4st6fcb8x	M/S MOHIT TRADERS	Sundry Creditors	\N	\N	0.00	\N
920b2923-60e8-4f29-993a-0fd452e50b9b	cmofmpqxp0000tms4st6fcb8x	M/S MONIKA PLYWOOD &amp; HARDWARE STORE	Sundry Creditors -Exp	\N	\N	0.00	\N
c3691710-ebe0-41a3-ac51-876e1cb93d80	cmofmpqxp0000tms4st6fcb8x	M/s Naman Traders, ALLAHABAD	OUT OF KANPUR	\N	\N	3359.81	\N
6801705b-d76b-420d-ae33-03ff41f86470	cmofmpqxp0000tms4st6fcb8x	M/S NAMRATA ELECTRONICS	Sundry Creditors	\N	\N	0.00	\N
7729c274-cefd-4c46-8cb6-9dbb583410af	cmofmpqxp0000tms4st6fcb8x	M/s Nanak Electric Stores	Sundry Creditors -Exp	\N	\N	0.00	\N
b90cf507-83ca-40a5-bf32-e0eb0bc601f8	cmofmpqxp0000tms4st6fcb8x	M/S NEW PRATAP AUTO CENTRE	Sundry Creditors	\N	\N	0.00	\N
6b06d020-d2aa-49b6-9bfd-515ee035f902	cmofmpqxp0000tms4st6fcb8x	M/S N.K. TRADERS- BHARTHANA	Ashutosh Ji	\N	\N	0.00	\N
d6c59fee-ad62-4bc2-8905-3783d7f60afa	cmofmpqxp0000tms4st6fcb8x	M/s Om Trading Company	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
51da9440-7d01-448f-be27-8407580d91c6	cmofmpqxp0000tms4st6fcb8x	M/S PARI ENTERPRISES ORAI	Ashutosh Ji	\N	\N	0.00	\N
5b62ede0-43a8-4b65-aec7-bf5df39a5005	cmofmpqxp0000tms4st6fcb8x	M/S PRADHAN AGENCY-JHINJHAK	DILIP PANDYE	\N	\N	0.00	\N
8ae4c409-a30e-4e30-bd0c-df8e2f961266	cmofmpqxp0000tms4st6fcb8x	M/S RAJ ALUMINIUM AND HARDWARE	Sundry Creditors	\N	\N	0.00	\N
f5411dde-6df4-49d0-8af7-f17223a43af4	cmofmpqxp0000tms4st6fcb8x	M/S RAJ DISTRIBUTORS	Sundry Creditors	\N	\N	0.00	\N
22b9690a-1b30-4afe-8d8e-4260ccf06ff6	cmofmpqxp0000tms4st6fcb8x	M/S RAJ TRADERS-KHUTAR	OUT OF KANPUR	\N	\N	-42012.00	\N
bae07e38-d3eb-4da5-a6a3-35d632d266fc	cmofmpqxp0000tms4st6fcb8x	M/S RAMA ENGINEERING.WORKS	Sundry Creditors	\N	\N	0.00	\N
47199178-55df-4c0c-95d4-4fcfb136fd3f	cmofmpqxp0000tms4st6fcb8x	M/S RAMAN ELECTRICALS	Sundry Creditors -Exp	\N	\N	0.00	\N
5a7e7af9-7f6a-4679-9835-9c35a3c451a0	cmofmpqxp0000tms4st6fcb8x	M/s Ram Kumar Rajesh Kumar, RATH	OUT OF KANPUR	\N	\N	0.00	\N
b061cb18-ad8e-48f7-913b-14fda37c4056	cmofmpqxp0000tms4st6fcb8x	M/s Rang Mahal Paints Agencies	Sundry Creditors -Exp	\N	\N	0.00	\N
a1bc4d5a-2d10-469f-b428-70e08b699837	cmofmpqxp0000tms4st6fcb8x	M/S REEMA BAKERS	Sundry Creditors	\N	\N	170982.00	\N
f0f7a48e-ecb9-4f55-ae7c-22d05e0c8f75	cmofmpqxp0000tms4st6fcb8x	M/s R. F. Food Products, MALLAWAN	OUT OF KANPUR	\N	\N	1870.00	\N
57b91ac4-a248-4d54-9d47-772b7ff916a5	cmofmpqxp0000tms4st6fcb8x	M/s Riya Agencies, LUCKNOW	Gaurav, LUCKNOW	\N	\N	-88788.00	\N
78a711ef-90d8-41c0-a8e0-a11170681f35	cmofmpqxp0000tms4st6fcb8x	M/s Rohit Traders. DALMAU	OUT OF KANPUR	\N	\N	0.00	\N
42a2518d-a540-4540-ae14-134c31703b73	cmofmpqxp0000tms4st6fcb8x	M/S SABRI TRADERS-HAMIRPUR	OUT OF KANPUR	\N	\N	-1176.00	\N
b300a532-c08a-4742-bd4c-6f177fef507e	cmofmpqxp0000tms4st6fcb8x	M/S SACHDEVA &amp; SONS	Sundry Creditors	\N	\N	0.00	\N
fb90b353-dbc6-4f41-944b-78e1cbcb57d6	cmofmpqxp0000tms4st6fcb8x	M/s Saneja Industrial Enterprises	Sundry Creditors -Exp	\N	\N	0.00	\N
0b3fe6ec-a356-4cce-b725-77adaac6759d	cmofmpqxp0000tms4st6fcb8x	M/S SARAF COOLING COMPANY PRIVATE LIMITED	Sundry Creditors	\N	\N	0.00	\N
e5e12ff5-349b-4b7a-a6e9-d4379df96a57	cmofmpqxp0000tms4st6fcb8x	M/S SHANKAR TRADING COMPANY	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
d94d7dfc-d213-40ca-b94d-144af47dceb3	cmofmpqxp0000tms4st6fcb8x	M/S SHANKER TRADINGS COM.-MAHOBA	Shivoham Shukla Parties	\N	\N	-23214.00	\N
95affbf9-f795-4d03-a6e9-6cd4426a6c39	cmofmpqxp0000tms4st6fcb8x	M/s Shawa Technocrafts Private Limited	Sundry Creditors -Exp	\N	\N	0.00	\N
433394d2-9fc6-4fde-a22a-03d23afcfc3c	cmofmpqxp0000tms4st6fcb8x	M/s Shivam Enterprises, SHIKHOHABAD	SHIKHOHABAD	\N	\N	0.00	\N
8aa4160c-8f2c-47a6-8cdd-58ebba6d4b68	cmofmpqxp0000tms4st6fcb8x	M/S SHIV ENTERPRISES PANKI	Ashutosh Ji	\N	\N	0.00	\N
ed7da688-fe37-4796-841f-49db4f90ede4	cmofmpqxp0000tms4st6fcb8x	M/S SHIV HYDRAULIC ENGINEERING WORK	Sundry Creditors	\N	\N	0.00	\N
bb701f2f-c04b-466b-878f-acffb0695d93	cmofmpqxp0000tms4st6fcb8x	M/S SHREE LALLU HARDWARE	Sundry Creditors	\N	\N	0.00	\N
73d786d7-6993-4c94-85d9-98883739b38e	cmofmpqxp0000tms4st6fcb8x	M/S SHRI NEW YOGI SWEETS NAMKEEN AND CONFECTIONERS	Sundry Creditors	\N	\N	0.00	\N
d0014bb0-eaa9-40dc-974d-1d4a9ad5bab8	cmofmpqxp0000tms4st6fcb8x	M/S SHRI RAM ENTERPRISES-KALYANPUR	Sundry Debtors	\N	\N	3815.00	\N
32edccb4-91d7-48fa-ba71-6b6f75a1796f	cmofmpqxp0000tms4st6fcb8x	M/S SHRI RAM PACKAGING	Sundry Creditors	\N	\N	0.00	\N
e7974dd4-3b0e-4729-93b5-bcd19cfb0ec9	cmofmpqxp0000tms4st6fcb8x	M/S SHUBHI AGENCIES-BARABANKI	Ashutosh Ji	\N	\N	0.00	\N
a716bf58-b86a-42af-a567-053921fd77c2	cmofmpqxp0000tms4st6fcb8x	M/S SHUBH SALES	Sundry Creditors	\N	\N	0.00	\N
de910e4a-d457-43c1-813f-60a6b2dcdbe4	cmofmpqxp0000tms4st6fcb8x	M/s Shukla Mill &amp; Machinery Corporation	Sundry Creditors	\N	\N	0.00	\N
bec363ee-90d5-4d0d-889e-546617db677a	cmofmpqxp0000tms4st6fcb8x	M/S SIGMA SLOTTING CORPORATION	Sundry Creditors	\N	\N	0.00	\N
9ad14a0b-9955-44c0-a432-4d223c77c127	cmofmpqxp0000tms4st6fcb8x	M/S SINGHAL AGENCY -AGRA	OUT OF KANPUR	\N	\N	0.00	\N
d2d31dfc-3811-4f7b-82dd-5e92cb4edc13	cmofmpqxp0000tms4st6fcb8x	M/S SOHUMS SWEETS	BAJAJ JI	\N	\N	0.00	\N
981dd9ff-e370-4858-9a2e-dd34fc00cb75	cmofmpqxp0000tms4st6fcb8x	M/S SONAL TRADING CO.	Sundry Creditors	\N	\N	0.00	\N
67be2cf2-7b51-4b12-8e84-c19c0636a8a5	cmofmpqxp0000tms4st6fcb8x	M/S STYLO PACK	Sundry Creditors	\N	\N	0.00	\N
23576834-a89e-4a2e-a0f8-ae2a16bc821f	cmofmpqxp0000tms4st6fcb8x	M/S SUPERKING TYERS AGENCY	Sundry Creditors	\N	\N	0.00	\N
2971ba0b-b20f-475e-a832-6c094e98262a	cmofmpqxp0000tms4st6fcb8x	M/S TEX CHEM AND COATINGS	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
88b62bef-db4e-4eec-aa9b-98fce2c0b2ff	cmofmpqxp0000tms4st6fcb8x	M/S U. P. PUMPS PVT. LTD.	Sundry Creditors	\N	\N	0.00	\N
29aee38c-e396-443a-ad35-d98a096aa9a5	cmofmpqxp0000tms4st6fcb8x	M/S VASANT LAXMI CASHEW	CREDITORS ( DIPESH JI )	\N	\N	178400.00	\N
59ab0290-13ec-4d3a-a583-630c040cc50d	cmofmpqxp0000tms4st6fcb8x	M/S VINEE AGENCIES	Ashutosh Ji	\N	\N	0.00	\N
b237e0a9-7b38-4f59-b938-65198c9782fb	cmofmpqxp0000tms4st6fcb8x	M/S VINOD TRADERS	Sundry Creditors	\N	\N	0.00	\N
91546b59-5e2b-444f-be69-6ba336647fea	cmofmpqxp0000tms4st6fcb8x	M/s Vishal Machinery &amp; Tools	Sundry Creditors -Exp	\N	\N	0.00	\N
74b28485-b2c0-4b0d-9740-b3be1e2ae795	cmofmpqxp0000tms4st6fcb8x	M/S V.K.ISPAT	Sundry Creditors	\N	\N	0.00	\N
08cc532c-d4f6-4a6f-aae1-b40f78645d7b	cmofmpqxp0000tms4st6fcb8x	M/S V.K.TRADERS	Sundry Creditors	\N	\N	0.00	\N
65a41e7e-4d7e-4ffb-ae3f-21407cbd5195	cmofmpqxp0000tms4st6fcb8x	Mubarak Ali ( DUCT )	Sundry Creditors -Exp	\N	\N	0.00	\N
8755eef9-2578-44b4-8892-2a3939430e91	cmofmpqxp0000tms4st6fcb8x	Mukes Bajaj	BAJAJ JI	\N	\N	0.00	\N
04e5af03-12ee-40d3-99ed-6115942379f3	cmofmpqxp0000tms4st6fcb8x	Mukesh Bajaj	BAJAJ JI	\N	\N	0.00	\N
b5804ecf-00a7-4b13-a08a-c1c73cc7e61a	cmofmpqxp0000tms4st6fcb8x	Mukesh Plumber	Sundry Creditors	\N	\N	0.00	\N
fde2730e-0800-4c1e-a27f-a5c09c37456d	cmofmpqxp0000tms4st6fcb8x	Mukhtar Thekedar	WAGES ( CONTRACTOR )	\N	\N	0.00	\N
fc12494f-ef93-4b28-adf9-42da6b3d2f10	cmofmpqxp0000tms4st6fcb8x	Mukul Bajaj	BAJAJ JI	\N	\N	0.00	\N
727d925f-cb3e-4246-893c-ffb9b29b5800	cmofmpqxp0000tms4st6fcb8x	MUKUL STORE, SANTI NAGAR	AMAR SONKAR	\N	\N	0.00	\N
06c6d5b4-86c7-4da0-9b8a-8b1f44616eea	cmofmpqxp0000tms4st6fcb8x	NAGESHWAR STORE, EXPRESS ROAD	AMAR SONKAR	\N	\N	0.00	\N
6f0ca470-c702-4dfa-9959-6498e51a5d35	cmofmpqxp0000tms4st6fcb8x	NAMAN BAJAJ	BAJAJ JI	\N	\N	0.00	\N
ae23cbf7-c365-49d0-bf1d-6a5138d11d1c	cmofmpqxp0000tms4st6fcb8x	NAMAN BAJPAI	BAJAJ JI	\N	\N	0.00	\N
d2adb1af-2a3f-4961-a311-6ec324ade328	cmofmpqxp0000tms4st6fcb8x	NANAK ENTERPRISES	Sundry Creditors	\N	\N	0.00	\N
507b3f99-2651-4037-8fb6-6889c88039ec	cmofmpqxp0000tms4st6fcb8x	Naredra (Biscuits Contractor)	Sundry Debtors	\N	\N	0.00	\N
81128c91-b160-489b-aee0-c6111603cba9	cmofmpqxp0000tms4st6fcb8x	NARENDRA BISCUITS ( 18.9.24 )	WAGES ( CONTRACTOR )	\N	\N	0.00	\N
51ea54d6-2654-41c9-83e1-c2fbdeec3083	cmofmpqxp0000tms4st6fcb8x	NASEEM DUCT	Sundry Creditors -Exp	\N	\N	0.00	\N
98d5a0e5-37b0-4a63-9196-95347f13ece0	cmofmpqxp0000tms4st6fcb8x	NATIONAL AGENCIES, RUDAULI	OUT OF KANPUR	\N	\N	360.00	\N
a0012282-ba30-48ad-8e44-0bd46517ae80	cmofmpqxp0000tms4st6fcb8x	NATIONAL TRADERS, BAHRAICH	Ashutosh Ji	\N	\N	0.00	\N
a5477910-d138-4e69-85ea-0b3e0cd1f980	cmofmpqxp0000tms4st6fcb8x	NAVDEEP ( Salary )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
c65e09f6-d983-4ac7-91ef-cebc06ea65ef	cmofmpqxp0000tms4st6fcb8x	NAVEEN CHAND SHARMA STAFF	Staff & Worker ( SALARY )	\N	\N	0.00	\N
b96cb975-127d-4dfb-8e48-3a33f7c4f9f9	cmofmpqxp0000tms4st6fcb8x	Naveen Enterprises ( Creditor )	CREDITORS ( DIPESH JI )	\N	\N	182344.74	\N
1da8ccb8-2603-408f-9a22-c3816113b9e5	cmofmpqxp0000tms4st6fcb8x	NE-1100 INK ROLL CODER	Fixed Assets	\N	\N	-40000.00	\N
dec51d93-e7dd-4ac2-99e9-b16daa57693e	cmofmpqxp0000tms4st6fcb8x	Neeraj Bajaj	BAJAJ JI	\N	\N	0.00	\N
31721ae8-f518-4e94-98e3-9085d4690a0c	cmofmpqxp0000tms4st6fcb8x	Neeraj Bajpai	BAJAJ JI	\N	\N	0.00	\N
c8d4e069-7106-46f8-b191-c5dd32f01f19	cmofmpqxp0000tms4st6fcb8x	Neeraj Singh ( 24/12/2024 )	Staff & Worker ( SALARY )	\N	\N	-2000.00	\N
d417c833-2f8b-46b6-bd73-06ee621b782d	cmofmpqxp0000tms4st6fcb8x	NEHA STAFF	Staff & Worker ( SALARY )	\N	\N	0.00	\N
01e80937-1626-415a-abf9-bc208aac3577	cmofmpqxp0000tms4st6fcb8x	New 1	Sundry Debtors	\N	\N	0.00	\N
19e3455a-f8c0-456b-8080-333bbca8df28	cmofmpqxp0000tms4st6fcb8x	NEW ( JEERA ) KARIGER 16/4/24	WAGES ( CONTRACTOR )	\N	\N	0.00	\N
4ea246c3-9f97-44eb-beb6-6b3e67dc732e	cmofmpqxp0000tms4st6fcb8x	NEW MIXTURE 90KG (TRISUL)	Fixed Assets	\N	\N	-39312.50	\N
e1745bdd-e6a1-4a65-bca1-ad65a759c979	cmofmpqxp0000tms4st6fcb8x	New Oven Purchase @ 18 %	Fixed Assets	\N	\N	-454557.07	\N
4be65c5d-00e6-45c7-8964-4e12e061f8e9	cmofmpqxp0000tms4st6fcb8x	NEW SUPREEM OIL TRADERS	Sundry Creditors	\N	\N	0.00	\N
01ac7366-938a-480c-8ce6-5afdc094a0da	cmofmpqxp0000tms4st6fcb8x	NIGHT PETROLLING	Indirect Expenses	\N	\N	0.00	\N
5771a7e9-d183-4989-9aec-3186284c9c62	cmofmpqxp0000tms4st6fcb8x	NIHARIKA BAKARY, MALL ROAD	AMAR SONKAR	\N	\N	0.00	\N
0b7dcc34-014a-456e-be68-31bfdd3f9e76	cmofmpqxp0000tms4st6fcb8x	NIKHIL SAHU	ANANTRAM JI	\N	\N	0.00	\N
c22855e9-e381-4aeb-8095-2aaec89d4c31	cmofmpqxp0000tms4st6fcb8x	NIPPON INDIA MULTICAP FUND( 499383832286 ) 19/12/24	SIP	\N	\N	0.00	\N
bef095ee-d976-4804-967a-b6b0bfc69b03	cmofmpqxp0000tms4st6fcb8x	NISHA GAJWANI	Sundry Debtors	\N	\N	0.00	\N
ac8cf99f-721a-431f-a23c-12c27efcc861	cmofmpqxp0000tms4st6fcb8x	Nitin Bajaj	BAJAJ JI	\N	\N	0.00	\N
945ebc5f-8f92-4be5-8f6f-ef24a4b02ea8	cmofmpqxp0000tms4st6fcb8x	NITIN (BISCUITS)	BISCUITS SALARY	\N	\N	0.00	\N
b1fd0cf0-166e-4c74-8359-03e823692339	cmofmpqxp0000tms4st6fcb8x	NITIN B RUSK	Sundry Debtors	\N	\N	0.00	\N
4b8b45b2-e3bc-45d9-8471-e9366decf440	cmofmpqxp0000tms4st6fcb8x	NITIN SAHU	ANANTRAM JI	\N	\N	0.00	\N
d3726add-68aa-44d0-bf83-2c2c81bad594	cmofmpqxp0000tms4st6fcb8x	NKPK UDYOG PVT LTD	CREDITORS ( DIPESH JI )	\N	\N	479827.00	\N
67d607c6-e6e4-4e64-8193-f30da2f4447c	cmofmpqxp0000tms4st6fcb8x	Office Exp	Office Exp	\N	\N	0.00	\N
391d68fa-4855-4e2c-9285-8d694f717cc0	cmofmpqxp0000tms4st6fcb8x	Office Exp 18%	Office Exp	\N	\N	0.00	\N
4e7cdcc9-03d6-4799-bb98-aa0e6120d6ac	cmofmpqxp0000tms4st6fcb8x	OLD RAJPAL MACHINERY STORE	Sundry Creditors	\N	\N	0.00	\N
d50698a1-9c68-4bf1-961d-f7b7fb449284	cmofmpqxp0000tms4st6fcb8x	Omar Export, Hardoi	OUT OF KANPUR	\N	\N	0.00	\N
eb79e161-3dfb-4fd0-ac0a-c65ae390f66e	cmofmpqxp0000tms4st6fcb8x	OM BOILER &amp; BURNERS	Sundry Creditors	\N	\N	0.00	\N
d0c42a25-df6d-4858-bdff-beaa69c80827	cmofmpqxp0000tms4st6fcb8x	OM MARKETING, JABALPUR	Ashutosh Ji	\N	\N	-60070.00	\N
8f6c9e65-dae5-44ee-a3bc-5e0fec0d6879	cmofmpqxp0000tms4st6fcb8x	Om Prakash Gupta, PUKHRAYA	DILIP PANDYE	\N	\N	0.00	\N
c732ee2d-96fd-4f81-92e1-f68418b8317f	cmofmpqxp0000tms4st6fcb8x	ORIENTAL SALES MARKETING, Lucknow	Lucknow Distributor	\N	\N	-86999.00	\N
134d7caa-5766-4d3a-b2f7-1d4f5aee3e08	cmofmpqxp0000tms4st6fcb8x	OUTPUT CGST@12%	Duties & Taxes	\N	\N	0.00	\N
6683666c-b14a-4f4f-8ba6-1ca415e73536	cmofmpqxp0000tms4st6fcb8x	Output CGST @ 2.5%	Duties & Taxes	\N	\N	264720.81	\N
7c877b7d-4b24-4664-a982-4cc665f5b023	cmofmpqxp0000tms4st6fcb8x	OUTPUT CGST @9%	Duties & Taxes	\N	\N	0.00	\N
f1fd6a4e-f8ce-4b4b-b340-fded36660e23	cmofmpqxp0000tms4st6fcb8x	OUTPUT SGST @12%	Duties & Taxes	\N	\N	0.00	\N
07277bdb-324e-4350-b12c-38479a45ed3c	cmofmpqxp0000tms4st6fcb8x	Output SGST @ 2.5%	Duties & Taxes	\N	\N	264720.81	\N
5709406b-d195-49f7-8c61-86b5216842f2	cmofmpqxp0000tms4st6fcb8x	OUTPUT SGST@9%	Duties & Taxes	\N	\N	0.00	\N
1f5dacd2-423c-46f9-ac1a-703f1c1026b7	cmofmpqxp0000tms4st6fcb8x	OVEN ARUN REGA ( WITH TROLLY)	Fixed Assets	\N	\N	-650000.00	\N
5956dd9d-106e-4789-b34f-cc314635731c	cmofmpqxp0000tms4st6fcb8x	OVEN GAS &amp; DIESAL	Fixed Assets	\N	\N	-392934.51	\N
0f70676f-31a5-4e27-b017-8e48241988e1	cmofmpqxp0000tms4st6fcb8x	OVEN PUR 4 TROLLT	Fixed Assets	\N	\N	-455756.40	\N
5e12412f-ff2c-4071-b27c-0e9f09cd5c33	cmofmpqxp0000tms4st6fcb8x	PACKING CHARGES	Indirect Expenses	\N	\N	0.00	\N
6c7e2dfa-7c48-4031-b65e-b95134d68b5f	cmofmpqxp0000tms4st6fcb8x	PACKING EXP 18%	Direct Expenses	\N	\N	0.00	\N
6af4a95a-769b-4e92-ba77-1e51921d335b	cmofmpqxp0000tms4st6fcb8x	Packing Expenses	Direct Expenses	\N	\N	0.00	\N
dcb512d8-dcf6-45b4-a82f-113cae14ccd3	cmofmpqxp0000tms4st6fcb8x	PACKING MACHINE AASHIRWAD	Fixed Assets	\N	\N	-300000.00	\N
05f1b19e-731f-46e4-89ed-e74b5e30cada	cmofmpqxp0000tms4st6fcb8x	PADMA (JEERA)	Staff & Worker ( SALARY )	\N	\N	0.00	\N
4351f997-2949-49db-9a4e-d5286eca1801	cmofmpqxp0000tms4st6fcb8x	PAHUJA TRAVELLS	Sundry Creditors -Exp	\N	\N	0.00	\N
87e244d0-f240-43b3-95af-f5a8cda75f6e	cmofmpqxp0000tms4st6fcb8x	PANKAJ BAJAJ	BAJAJ JI	\N	\N	0.00	\N
e370f88e-80b0-4e16-af3a-a9a298fe3402	cmofmpqxp0000tms4st6fcb8x	PANKAJ BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
1200d996-3074-429f-98e6-04e82df84305	cmofmpqxp0000tms4st6fcb8x	Pankaj B Rusk	BISCUITS SALARY	\N	\N	0.00	\N
a0a0ad2f-a85d-43ad-a44b-41766a100c9f	cmofmpqxp0000tms4st6fcb8x	PANKAJ SWEETS	VIJAY BATHAM	\N	\N	0.00	\N
27fc95ab-283e-41ee-8520-c4876bebce17	cmofmpqxp0000tms4st6fcb8x	PANKAJ ( V-GUARD )	Sundry Debtors	\N	\N	-1405.00	\N
912700ba-581c-4cd8-bb36-7f9faa0be25c	cmofmpqxp0000tms4st6fcb8x	Pappu Jugal (THEKEDAAR)	Sundry Creditors	\N	\N	0.00	\N
f4272e78-0f91-455a-90a3-66d48215194b	cmofmpqxp0000tms4st6fcb8x	PARAS TRADEMART PVT LTD	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
2321d1a9-8ac6-44e9-a2af-ac68b8930358	cmofmpqxp0000tms4st6fcb8x	PARMANAND AND COMPANY	Sundry Creditors	\N	\N	0.00	\N
b96d100e-de46-444b-9a9e-0907f5297912	cmofmpqxp0000tms4st6fcb8x	Parmanand Sahu	ANANTRAM JI	\N	\N	0.00	\N
a26b960e-d8c4-47ed-882f-adec2477ec2b	cmofmpqxp0000tms4st6fcb8x	Parshwanath Agencies, KANPUR	Sundry Debtors	\N	\N	0.00	\N
1ec4a949-238a-4419-b1d6-9c37597c040e	cmofmpqxp0000tms4st6fcb8x	PATHAK ENTERRISES-BHARWA	Ashutosh Ji	\N	\N	1565.00	\N
8758e1c1-14d6-4a43-b074-38c2ac662115	cmofmpqxp0000tms4st6fcb8x	PC JAIN AND SONS LLP	Sundry Creditors	\N	\N	0.00	\N
3fec958b-e95d-4dc5-9576-988805ed5d1b	cmofmpqxp0000tms4st6fcb8x	PDC INTERNATIONAL	PIN DROP	\N	\N	-30237.00	\N
ac2af26c-e8c2-4964-86aa-50ff7312eea4	cmofmpqxp0000tms4st6fcb8x	PDC INTERNATIONAL, UP	PIN DROP	\N	\N	-24190.00	\N
824556de-d2a8-4ee6-9afe-122165a10691	cmofmpqxp0000tms4st6fcb8x	PEDESTAL FAN THUNDER 450MM (2800) RPM	FAN	\N	\N	-7614.00	\N
acdb71b9-51e2-45bc-964e-a3b0ef2fea1f	cmofmpqxp0000tms4st6fcb8x	PEEKAY FARM EQUIPMENTS INDIA PVT LTD.	CHILLER	\N	\N	0.00	\N
f21aac17-e2f1-4960-a193-f8f27596dee3	cmofmpqxp0000tms4st6fcb8x	PIN DROP CREATORS	PIN DROP	\N	\N	-19352.00	\N
8a29d815-f392-434a-803b-066bacf3ed2c	cmofmpqxp0000tms4st6fcb8x	Pinky Plastic	Sundry Creditors -Exp	\N	\N	5741.00	\N
cbcaf934-d6d8-40c3-b833-aa1468a7839c	cmofmpqxp0000tms4st6fcb8x	PINTU SAHU	ANANTRAM JI	\N	\N	0.00	\N
a55cdcb4-e048-491b-9e66-8b2dac0bf309	cmofmpqxp0000tms4st6fcb8x	Pioneer Flexible Pakagers	CREDITORS ( DIPESH JI )	\N	\N	633330.00	\N
79b716d1-20a5-4a2b-a378-0e7741bd72c5	cmofmpqxp0000tms4st6fcb8x	P K ENTERPRISES (SCREENING)	Sundry Creditors	\N	\N	0.00	\N
34631346-73d5-489e-b373-ac4399012e01	cmofmpqxp0000tms4st6fcb8x	Plant &amp; Machinery Fixed Assets ( U/R )	Fixed Assets	\N	\N	-851474.88	\N
f7220314-058e-4b29-ac8a-37fd8e4ac2c6	cmofmpqxp0000tms4st6fcb8x	PONY STORE, MASAL GALI	AMAR SONKAR	\N	\N	0.00	\N
6893af35-3438-4102-bb3f-625601b6420e	cmofmpqxp0000tms4st6fcb8x	POOJA &amp; FESTIVAL EXP	Festival Expenses	\N	\N	0.00	\N
6f26ad29-d2c8-4818-ac6c-2f352e95b4de	cmofmpqxp0000tms4st6fcb8x	Poonam Sahu Packing	Staff & Worker ( SALARY )	\N	\N	0.00	\N
7ffc6c95-3cc2-4759-9ff1-1ffbd3ffb789	cmofmpqxp0000tms4st6fcb8x	Poonam Singh (	Staff & Worker ( SALARY )	\N	\N	0.00	\N
93f7c162-96ac-4218-8892-825ef4a8f65f	cmofmpqxp0000tms4st6fcb8x	Poonam Singh Packing	Staff & Worker ( SALARY )	\N	\N	2667.00	\N
8612fc0b-8e62-4905-a3a5-04c01c1583d9	cmofmpqxp0000tms4st6fcb8x	Porwal Graphics &amp;  Printers ( Creditor )	CREDITORS ( DIPESH JI )	\N	\N	489850.00	\N
b3ce0b4e-35d9-40d6-baf6-409f3b5e1ff0	cmofmpqxp0000tms4st6fcb8x	Postage &amp; Courier Charges	Indirect Expenses	\N	\N	0.00	\N
5718d5ff-1069-458d-b9cf-48a134a7e995	cmofmpqxp0000tms4st6fcb8x	POWER PLANET	Sundry Creditors -Exp	\N	\N	0.00	\N
2327fdb8-b6cf-467f-80de-16d456b6c6f7	cmofmpqxp0000tms4st6fcb8x	Pradeep Bajaj	BAJAJ JI	\N	\N	0.00	\N
1696c036-f8f9-492d-85d2-870f0db56bfa	cmofmpqxp0000tms4st6fcb8x	Pradeep BISCUITS	BISCUITS SALARY	\N	\N	0.00	\N
395e6d62-7720-476a-bfd0-801b6351672b	cmofmpqxp0000tms4st6fcb8x	PRADEEP B RUSK	Sundry Debtors	\N	\N	0.00	\N
9624afff-0d32-4934-b199-23458424573b	cmofmpqxp0000tms4st6fcb8x	PRADEEP SAHU	ANANTRAM JI	\N	\N	0.00	\N
dde7ec3a-0b7f-4955-b25a-5f6c6b540b2c	cmofmpqxp0000tms4st6fcb8x	PRADEEP SWEAPER	Staff & Worker ( SALARY )	\N	\N	0.00	\N
fce29be9-bc9f-46a0-9c85-329d838fa47f	cmofmpqxp0000tms4st6fcb8x	Prakash Enterprises, KUSHINAGAR	OUT OF KANPUR	\N	\N	0.00	\N
de29eba3-c002-4810-8d5f-e2d7fab93752	cmofmpqxp0000tms4st6fcb8x	PRAKHAR BAJAJ	BAJAJ JI NEW	\N	\N	0.00	\N
243a6f5f-6ae3-410d-8666-491a6430d4c0	cmofmpqxp0000tms4st6fcb8x	PRAMOD BAJPAI	BAJAJ JI	\N	\N	0.00	\N
b4cfbd44-52a8-47cf-929f-f025b892e213	cmofmpqxp0000tms4st6fcb8x	PRAMOD B RUSK	Sundry Debtors	\N	\N	0.00	\N
5ae97151-76e2-42ae-a5d0-d224c774979c	cmofmpqxp0000tms4st6fcb8x	PRAMOD KUMAR ( BISCUITS )	BISCUITS SALARY	\N	\N	74918.00	\N
4eb57494-b18e-40a4-b7cb-793d716b733f	cmofmpqxp0000tms4st6fcb8x	PRAMOD SAHU	ANANTRAM JI	\N	\N	0.00	\N
69c76d66-d67a-490b-a468-a94935123df7	cmofmpqxp0000tms4st6fcb8x	PRANJUL SAHU	ANANTRAM JI	\N	\N	0.00	\N
922eaf09-a90d-4902-b2c3-74577d8c11b2	cmofmpqxp0000tms4st6fcb8x	PRATEEK S	Sundry Debtors	\N	\N	0.00	\N
e64f9823-a7ba-469c-b022-68fe32440b65	cmofmpqxp0000tms4st6fcb8x	PRATEEK STAFF	Staff & Worker ( SALARY )	\N	\N	0.00	\N
a5e418c3-b849-441e-9ff7-0d3c1b98a9c5	cmofmpqxp0000tms4st6fcb8x	PRATEEK TRIVEDI ( SALARY )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
8e139ef0-9321-4629-8c06-9b58b261f739	cmofmpqxp0000tms4st6fcb8x	Pratik Vishnoi / KISHAN GUPTA	Sundry Debtors	\N	\N	17031.00	\N
e86c5ce2-545f-4912-913b-ce98c8ef3c03	cmofmpqxp0000tms4st6fcb8x	Prepaid Insurance	Loans & Advances (Asset)	\N	\N	-7274.00	\N
80607705-c7b3-44f3-b37e-cfbb293b4220	cmofmpqxp0000tms4st6fcb8x	Prince Machine	Sundry Creditors -Exp	\N	\N	31160.00	\N
7cee0730-370b-4a29-81fc-6037af60866a	cmofmpqxp0000tms4st6fcb8x	PRINCE PACKEGING	Sundry Creditors	\N	\N	0.00	\N
b31e2667-868e-485c-ad32-17f4a6273b09	cmofmpqxp0000tms4st6fcb8x	Printer	Fixed Assets	\N	\N	1194.14	\N
3b800be5-f1ad-4ad7-b7a0-9d9f4ce0d21d	cmofmpqxp0000tms4st6fcb8x	PRINTING &amp; STATIONERY	Printing and Stationery	\N	\N	0.00	\N
94c82d1f-0de5-4a3d-b5cb-242c0fee0289	cmofmpqxp0000tms4st6fcb8x	PRINTING &amp; STATIONERY@12%	Printing and Stationery	\N	\N	0.00	\N
3e99d059-743d-48a5-9f0e-38fae3357590	cmofmpqxp0000tms4st6fcb8x	PRINTING &amp; STATIONERY@18%	Printing and Stationery	\N	\N	0.00	\N
a08e0831-555c-49ef-b028-1cc0ea6f2b15	cmofmpqxp0000tms4st6fcb8x	PRIYA COMMUNICATION	Sundry Creditors	\N	\N	0.00	\N
ac203b14-5c73-4fed-91f5-8056c71bac04	cmofmpqxp0000tms4st6fcb8x	Processig Fee	BANK CHARGES	\N	\N	0.00	\N
0db67d2f-8685-47fd-8be7-5313d6e35d84	cmofmpqxp0000tms4st6fcb8x	Production Labour Charges ( BISCUITS )	Direct Expenses	\N	\N	0.00	\N
4e79443a-c26b-4c6a-b4c4-65e2e93e1875	cmofmpqxp0000tms4st6fcb8x	Production Labour Charges ( JEERA )	Direct Expenses	\N	\N	0.00	\N
3b95a17c-f1aa-4eaa-808a-48a527ab9ea9	cmofmpqxp0000tms4st6fcb8x	Professional Fee	Indirect Expenses	\N	\N	0.00	\N
30b2400f-4297-475c-abb4-8e27a2351b77	cmofmpqxp0000tms4st6fcb8x	PROFILE SHEET	Fixed Assets	\N	\N	-13366.27	\N
73f0acf9-6aab-4c77-a109-f11bceaba1d1	cmofmpqxp0000tms4st6fcb8x	Profit &amp; Loss A/c	&#4; Primary	\N	\N	1479631.10	\N
dc5dd1e5-f75b-4d03-81c9-21cb3380791b	cmofmpqxp0000tms4st6fcb8x	Protean Egov Technologies Limited	Sundry Creditors -Exp	\N	\N	0.00	\N
00fe9ee9-2b68-4f07-a9f2-416dfca2c9d9	cmofmpqxp0000tms4st6fcb8x	Provision for Deferred Tax	Indirect Expenses	\N	\N	0.00	\N
f702acfc-e418-4a4f-9156-19317776ac2f	cmofmpqxp0000tms4st6fcb8x	Provision for Income Tax	Current Liabilities	\N	\N	0.00	\N
ea6bcec5-f9ea-4dbc-b9e7-b80219923e9a	cmofmpqxp0000tms4st6fcb8x	PUBLISITES GRAFIX	Sundry Creditors -Exp	\N	\N	0.00	\N
1003976d-b416-4560-b3e6-84ae40a340f8	cmofmpqxp0000tms4st6fcb8x	Pump Set @ 12%	Fixed Assets	\N	\N	-4756.22	\N
04ca033d-abd7-4076-969c-02b7d34b317b	cmofmpqxp0000tms4st6fcb8x	PUNEET GANGA TRADERS	CREDITORS ( DIPESH JI )	\N	\N	297686.00	\N
e94164cd-8f95-42d7-a25b-2c846f9338ed	cmofmpqxp0000tms4st6fcb8x	PUNJAB DEPARTMENTAL STORE	Ashutosh Ji	\N	\N	0.00	\N
e7402f7d-8ad6-4d06-bca4-03c6c2687ff4	cmofmpqxp0000tms4st6fcb8x	PURCHASE 12%	Purchase Accounts	\N	\N	0.00	\N
c751a6f2-0d29-4395-8911-7b7e46f5e662	cmofmpqxp0000tms4st6fcb8x	PURCHASE 18%	Purchase Accounts	\N	\N	0.00	\N
da52e0e3-68d5-4f99-a249-e73e4115edb6	cmofmpqxp0000tms4st6fcb8x	Purchase 5%	Purchase Accounts	\N	\N	0.00	\N
5d7b4bd1-04a8-4068-97fe-37211fc8ec37	cmofmpqxp0000tms4st6fcb8x	Purchase Exempt	Purchase Accounts	\N	\N	0.00	\N
d23bef6b-5f3e-4c95-ac1a-3c94bcfea569	cmofmpqxp0000tms4st6fcb8x	Purchase IGST@12%	Purchase Accounts	\N	\N	0.00	\N
76b35afe-e3bb-447b-9dbe-6fd2320caed7	cmofmpqxp0000tms4st6fcb8x	Purchase IGST@18%	Purchase Accounts	\N	\N	0.00	\N
4e23f11e-41e1-46d2-8319-bf8ebffd15a0	cmofmpqxp0000tms4st6fcb8x	Purchase IGST@5%	Purchase Accounts	\N	\N	0.00	\N
0ab222b2-baec-4696-b9d7-b0f4fd0cf89d	cmofmpqxp0000tms4st6fcb8x	Purchase Unregister	Purchase Accounts	\N	\N	0.00	\N
6126331e-ff12-443f-af4d-3fe949940e8a	cmofmpqxp0000tms4st6fcb8x	Purshottam Bajaj	BAJAJ JI	\N	\N	0.00	\N
d61c46ba-9901-4b97-8da5-ec7b7f7d2906	cmofmpqxp0000tms4st6fcb8x	PUSHPA TRADERS-Lucknow	Lucknow Distributor	\N	\N	0.00	\N
fcfc5f39-d1a2-49da-9db3-4903997f4feb	cmofmpqxp0000tms4st6fcb8x	QASMI TRADERS, BAHRAICH	Ashutosh Ji	\N	\N	1684.00	\N
64df5daf-f1c5-461f-8d8a-f14fda269734	cmofmpqxp0000tms4st6fcb8x	R A B PACKAGING LLP	Sundry Creditors	\N	\N	6429.00	\N
13cf95f8-b8de-4c2d-8c05-df163ca74f55	cmofmpqxp0000tms4st6fcb8x	RABY INGREDIENTS (Lknw)	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
4d3e1400-19be-41f9-8c81-5e88e9a31e2f	cmofmpqxp0000tms4st6fcb8x	RADHA SWAMI TRADERS	CREDITORS ( DIPESH JI )	\N	\N	166565.00	\N
78e21615-4dc4-4c72-8c08-b8e30b1bc969	cmofmpqxp0000tms4st6fcb8x	Radhey Lal	BAJAJ JI	\N	\N	0.00	\N
0a824153-4643-4cbe-9864-fddc3e9c9f9d	cmofmpqxp0000tms4st6fcb8x	RADHEY LAL RAJESH KUMAR	Sundry Creditors	\N	\N	0.00	\N
8df0c5e6-d49d-46bf-b0d4-dba777dafec4	cmofmpqxp0000tms4st6fcb8x	Radhey Lal Sahu	ANANTRAM JI	\N	\N	0.00	\N
a648ce2b-3719-42f5-90d4-ac26141b3ec2	cmofmpqxp0000tms4st6fcb8x	RADHEY STORE, TRIVENI NAGAR	AMAR SONKAR	\N	\N	-1280.00	\N
beb58e1c-5b35-42c7-a379-23ef34fd0d36	cmofmpqxp0000tms4st6fcb8x	RAGHAV (SUNIL SUDHEER)	Sundry Debtors	\N	\N	-5870.00	\N
c570ab70-6957-458d-80e8-8826c3f4a39c	cmofmpqxp0000tms4st6fcb8x	Raghu Bajpai	BAJAJ JI NEW	\N	\N	0.00	\N
a3af8be0-3602-430c-adfe-d45eebd622b1	cmofmpqxp0000tms4st6fcb8x	RAGHUVEER SINGH (GUARD)	Sundry Debtors	\N	\N	0.00	\N
f1372e2b-ce5f-4b27-bf99-17e79494646c	cmofmpqxp0000tms4st6fcb8x	RAHUL AGENCY RAIBARELI	OUT OF KANPUR	\N	\N	-222861.00	\N
d1ad28ee-ff05-47a6-bf39-d5d683ce1cf9	cmofmpqxp0000tms4st6fcb8x	RAHUL BAJAJ	BAJAJ JI	\N	\N	0.00	\N
3595d033-f685-4e06-a813-a05ca05bfc60	cmofmpqxp0000tms4st6fcb8x	Rahul Bajpai	BAJAJ JI NEW	\N	\N	0.00	\N
01bc833a-2938-4fdf-bbaf-424c85197cd5	cmofmpqxp0000tms4st6fcb8x	Rahul Engineering Work	Sundry Creditors	\N	\N	-193029.00	\N
475145bb-84ad-4862-9528-61733a460eb7	cmofmpqxp0000tms4st6fcb8x	RAHUL SAHU	ANANTRAM JI	\N	\N	0.00	\N
d7653b5a-dc1f-4c42-a29e-55b84ed6bae3	cmofmpqxp0000tms4st6fcb8x	RAHUL STORE, MASALA GALI	AMAR SONKAR	\N	\N	-3100.00	\N
d1c38651-bfdf-4641-9749-cfddbf1fd3f3	cmofmpqxp0000tms4st6fcb8x	Rahul Trading Co.	Sundry Creditors -Exp	\N	\N	0.00	\N
dbc0bdee-e94d-4a76-8c4f-e6d7f7808226	cmofmpqxp0000tms4st6fcb8x	RAINA GOYAL CS	Sundry Creditors -Exp	\N	\N	0.00	\N
a0cd8147-d05f-4d3a-8220-abc02c3e0af3	cmofmpqxp0000tms4st6fcb8x	RAIS STORE, MEERPUR	AMAR SONKAR	\N	\N	0.00	\N
70cb433e-3123-4bd0-8600-423152c1eb14	cmofmpqxp0000tms4st6fcb8x	RAJAT AWASTHI ( 01-MAR-2024 )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
70e3968e-a375-4e6b-8f72-198aa2e3bd7e	cmofmpqxp0000tms4st6fcb8x	Rajat Awasthi ( Tour )	Sundry Creditors(Tour)	\N	\N	0.00	\N
663d3aa8-9f71-4181-af24-e4d8abda5375	cmofmpqxp0000tms4st6fcb8x	RAJAT BAJAJ	BAJAJ JI	\N	\N	0.00	\N
cdc6ec5b-604a-4677-ad47-bab12135bc85	cmofmpqxp0000tms4st6fcb8x	Rajat Bajpai	BAJAJ JI NEW	\N	\N	0.00	\N
9991b893-6877-44a0-adca-cf4dbbe0da17	cmofmpqxp0000tms4st6fcb8x	RAJAT DIXIT ( 29-SEP-2025 )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
5f48d35f-4394-45be-b8dc-a174cb5a33b9	cmofmpqxp0000tms4st6fcb8x	RAJAT SAHU	ANANTRAM JI	\N	\N	0.00	\N
efba90e7-ebdd-4e86-b501-32880636bdad	cmofmpqxp0000tms4st6fcb8x	Rajat SWEAPER	Staff & Worker ( SALARY )	\N	\N	0.00	\N
c8fcedf6-4c37-4f71-ae9d-c918e5040d8f	cmofmpqxp0000tms4st6fcb8x	RAJ BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
3addf232-896c-4ddb-9518-3d2d34749600	cmofmpqxp0000tms4st6fcb8x	RAJENDRA FARUKHABAD, Nayaganj	AMAR SONKAR	\N	\N	-3100.00	\N
4f621f31-49ab-43f7-b2ff-2637c4ad40cb	cmofmpqxp0000tms4st6fcb8x	RAJESH BAJAJ	BAJAJ JI	\N	\N	0.00	\N
567d6f35-668d-40f9-89f8-6ae2907092ee	cmofmpqxp0000tms4st6fcb8x	RAJESH ( BISCUIT THEKEDAR )	Sundry Debtors	\N	\N	0.00	\N
75cae26a-4471-4153-8c30-dcee6e86dd03	cmofmpqxp0000tms4st6fcb8x	RAJESH NAMKEEN, NAYA GANJ	AMAR SONKAR	\N	\N	0.00	\N
ca8271bd-e84e-4ae1-81b5-347a97ce484a	cmofmpqxp0000tms4st6fcb8x	Rajjak Ali -Maudaha	Ashutosh Ji	\N	\N	-74940.00	\N
6ed09f56-9141-45cf-8469-989ffeacba33	cmofmpqxp0000tms4st6fcb8x	RAJU BAJPAI	BAJAJ JI	\N	\N	0.00	\N
fea0945b-75d9-4106-ad88-fefc1f4d76a2	cmofmpqxp0000tms4st6fcb8x	RAJU SAHU	ANANTRAM JI	\N	\N	0.00	\N
2a58e72e-aa28-401c-8b3f-8718e6b29942	cmofmpqxp0000tms4st6fcb8x	RAKESH BAJAJ	BAJAJ JI	\N	\N	0.00	\N
f429a435-b155-4808-8b61-85c48eb5409d	cmofmpqxp0000tms4st6fcb8x	RAKESH BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
d8ce8b1e-e656-4ebd-b003-d813bcd9042a	cmofmpqxp0000tms4st6fcb8x	RAKESH KUMAR OJHA-LUCKNOW	Lucknow Distributor	\N	\N	0.00	\N
e7a634d5-5d12-4be6-a2d8-72c1d1755dd4	cmofmpqxp0000tms4st6fcb8x	Rakesh Sahu	ANANTRAM JI	\N	\N	0.00	\N
d1cd02a6-d69d-4199-b4a8-e12aecb99878	cmofmpqxp0000tms4st6fcb8x	RAMA AGENCIES	BAJAJ JI NEW	\N	\N	300000.00	\N
50efb6d6-b183-4077-8202-5a3911836821	cmofmpqxp0000tms4st6fcb8x	Raman Bajpai	BAJAJ JI NEW	\N	\N	0.00	\N
6490bca8-c934-44c5-95c4-814277e9e205	cmofmpqxp0000tms4st6fcb8x	RAM ASREY SONS, FATEHPUR	Ashutosh Ji	\N	\N	0.00	\N
192e7164-8289-42fd-ac38-2a1d22270d03	cmofmpqxp0000tms4st6fcb8x	RAM BAJPAI	BAJAJ JI	\N	\N	0.00	\N
03e2671e-d5a2-4aa2-ae9f-4050e5d1bda0	cmofmpqxp0000tms4st6fcb8x	RAM BAKERY, Ram Narayan Bajar	AMAR SONKAR	\N	\N	-1320.00	\N
8ae70712-175b-45df-8d86-852c3f2b436b	cmofmpqxp0000tms4st6fcb8x	RAM CHANDRA BAJPAI	BAJAJ JI	\N	\N	0.00	\N
e76e2c72-0722-461b-87ad-8d26282837db	cmofmpqxp0000tms4st6fcb8x	RAM CHANDRA SAHU	ANANTRAM JI	\N	\N	0.00	\N
1d0fdb9a-a869-4cf4-932c-ea43ce904f3c	cmofmpqxp0000tms4st6fcb8x	RAM CHANDRA &amp; SONS, DATIA	DATIA	\N	\N	0.00	\N
c47f7b10-3375-4fcb-93c8-a1ad019fcaa0	cmofmpqxp0000tms4st6fcb8x	RAM DATT SAHU	ANANTRAM JI	\N	\N	0.00	\N
5f0ee667-8c91-4ae0-ac58-81e7ca3759fd	cmofmpqxp0000tms4st6fcb8x	RAM DUTT BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
c79ea92b-ced2-458a-bff9-5dd040a666a1	cmofmpqxp0000tms4st6fcb8x	RAMESH BAJAJ	BAJAJ JI	\N	\N	0.00	\N
c62d6617-b3f4-4bf3-b216-ad37bf78d40c	cmofmpqxp0000tms4st6fcb8x	Ramesh Ji	BAJAJ JI	\N	\N	0.00	\N
263b006e-ea3b-4cf5-bbaa-32b6ebcea3da	cmofmpqxp0000tms4st6fcb8x	RAMESH KUMAR JAIN, SATNA	SATNA	\N	\N	0.00	\N
d5f2900d-1e0b-44d1-b794-a8cf0254fd92	cmofmpqxp0000tms4st6fcb8x	Ramesh Kumar Tejumal  Departmental Store	BAJAJ JI	\N	\N	0.00	\N
56daeec9-f337-484d-94c6-5115048e4d12	cmofmpqxp0000tms4st6fcb8x	Ramesh Sahu	ANANTRAM JI	\N	\N	0.00	\N
da6d2f63-9db7-4f80-bf28-43783cf07c11	cmofmpqxp0000tms4st6fcb8x	RAM KHILAWAN ( SCRAP )	Sundry Debtors	\N	\N	0.00	\N
5b37ab37-61b9-4911-a883-d8bb29338472	cmofmpqxp0000tms4st6fcb8x	RAM KUMAR BAJPAI	BAJAJ JI	\N	\N	0.00	\N
87ef1593-b198-4990-bc2c-f4f408b4c141	cmofmpqxp0000tms4st6fcb8x	RAM LAL	Sundry Debtors	\N	\N	0.00	\N
faa3aada-26e7-48b3-8da1-bd2fe3c9308a	cmofmpqxp0000tms4st6fcb8x	Ram Lal Sahu	ANANTRAM JI	\N	\N	0.00	\N
5bd66c91-7949-4f1a-a7c4-1e2cd89f629e	cmofmpqxp0000tms4st6fcb8x	RAM MOHAN SAHU	ANANTRAM JI	\N	\N	0.00	\N
582667b3-a345-46eb-8059-74bd4d66437b	cmofmpqxp0000tms4st6fcb8x	RAM MOHAN &amp; SONS, KANNAUJ	Ashutosh Ji	\N	\N	0.00	\N
63a52b17-7101-4310-b117-510207e9a1d3	cmofmpqxp0000tms4st6fcb8x	RAM SAHU	ANANTRAM JI	\N	\N	0.00	\N
bd91dedc-d762-4337-9147-954c9c97f51f	cmofmpqxp0000tms4st6fcb8x	Ram Shankar Gupta, Bangermau	Sundry Debtors	\N	\N	0.00	\N
eb315131-1e5a-4164-a2da-9111e4793ca8	cmofmpqxp0000tms4st6fcb8x	RAM TRADERS	ANANTRAM JI	\N	\N	0.00	\N
a414daf0-1ca2-4660-9717-5984b6fd1e6b	cmofmpqxp0000tms4st6fcb8x	RAMU SAHU	ANANTRAM JI	\N	\N	0.00	\N
c91ff1a5-ed94-482d-895c-ca89743261a0	cmofmpqxp0000tms4st6fcb8x	Ramveer	Sundry Creditors -Exp	\N	\N	0.00	\N
c5261eda-51cc-49da-8471-b7e011fffe42	cmofmpqxp0000tms4st6fcb8x	RANJAN E-Rikshaw	FREIGHT OUTWORD	\N	\N	0.00	\N
c0b116f8-bdf2-4faa-bf9b-148b07d367f1	cmofmpqxp0000tms4st6fcb8x	Ranjan Sahu	ANANTRAM JI	\N	\N	0.00	\N
8da34e0c-97f9-4e61-9ef3-6ffab5968ee1	cmofmpqxp0000tms4st6fcb8x	RANJEET BAJAJ	BAJAJ JI	\N	\N	0.00	\N
dc89b34b-3922-40ab-a00f-2ef628713e68	cmofmpqxp0000tms4st6fcb8x	Ranjeet Enterprises	Sundry Creditors -Exp	\N	\N	0.00	\N
80c4189d-ab26-4956-bbcf-9e6cdfacb154	cmofmpqxp0000tms4st6fcb8x	RANSHA ENTERPRISES-Lucknow	Lucknow Distributor	\N	\N	0.00	\N
62cf82b0-5e81-460a-8ab4-063fde14c732	cmofmpqxp0000tms4st6fcb8x	RAPUT GUARD	Staff & Worker ( SALARY )	\N	\N	0.00	\N
7a8d1ba4-fa5d-4471-84ac-78d40a5cbe82	cmofmpqxp0000tms4st6fcb8x	RASHAN ( BISCUITS DEPARTMENT )	Staff & Welfare	\N	\N	0.00	\N
785e4441-19af-4c81-913d-8e622f5b5666	cmofmpqxp0000tms4st6fcb8x	Rate Diff	Rate Difference	\N	\N	0.00	\N
5d709628-fda0-45dc-b2cb-a1e31d81034d	cmofmpqxp0000tms4st6fcb8x	Rate Diff @12%	Indirect Expenses	\N	\N	0.00	\N
689eb7a6-ca49-41f4-9d65-573018786c82	cmofmpqxp0000tms4st6fcb8x	Rate Diff @18%	Indirect Incomes	\N	\N	0.00	\N
dde1d79f-d1b4-4f94-a20a-ff274bd6d362	cmofmpqxp0000tms4st6fcb8x	Rate Diff @ 5%	Sales Accounts	\N	\N	0.00	\N
c635c7f4-7af2-4cdf-ac78-5dc25ac29096	cmofmpqxp0000tms4st6fcb8x	Rate Diff ( Damage &amp; Expire )	Sales Accounts	\N	\N	0.00	\N
fe485c3d-ea1c-4da5-b774-c2a4b2cad351	cmofmpqxp0000tms4st6fcb8x	Rate Difference(28%)	Indirect Expenses	\N	\N	0.00	\N
2ae5be36-2cb8-4ac8-ba71-24c838913ac3	cmofmpqxp0000tms4st6fcb8x	Rate Difference@12%	Rate Difference	\N	\N	0.00	\N
2bfa618f-d5fa-4776-8390-bb3372aa66e6	cmofmpqxp0000tms4st6fcb8x	Rate Diffrence @ 5%	Rate Difference	\N	\N	0.00	\N
58bfe167-6557-4f79-8aab-191237ddd010	cmofmpqxp0000tms4st6fcb8x	RAUNAK ENTERPRISES	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
7eed4605-2219-402e-8e42-dc34bc8c24e3	cmofmpqxp0000tms4st6fcb8x	RAVEDOR PAC OPR Sale	Sundry Debtors	\N	\N	0.00	\N
56ca831a-93b5-40ec-9958-c65385dcb923	cmofmpqxp0000tms4st6fcb8x	RAVENDOR SAHU	ANANTRAM JI	\N	\N	0.00	\N
0aabddd2-cded-4a99-a5cd-422992a530c0	cmofmpqxp0000tms4st6fcb8x	RAVENDRA YADAV PACKING MACHINE	Staff & Worker ( SALARY )	\N	\N	0.00	\N
6093d52e-de35-47d9-a540-e71f5b587396	cmofmpqxp0000tms4st6fcb8x	RAVI BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
9597a6c1-e559-4e5d-b580-30738e81fe18	cmofmpqxp0000tms4st6fcb8x	RAVI SAHU	ANANTRAM JI	\N	\N	0.00	\N
2e6fcb17-4a53-45a9-90ae-820588e61d8b	cmofmpqxp0000tms4st6fcb8x	RAVI - SIPAHI	Sipahi	\N	\N	0.00	\N
40eca674-d03a-49ef-bd24-39fb8c395f6b	cmofmpqxp0000tms4st6fcb8x	RAZA ENTERPRISES	Raza Bhai Unnao	\N	\N	0.00	\N
9faf2cc9-5fad-4cb8-b8e5-f8a3c3570de7	cmofmpqxp0000tms4st6fcb8x	REAL PACKAGING	CREDITORS ( DIPESH JI )	\N	\N	80184.00	\N
84eecfde-858f-41eb-97a6-0aa9c845460b	cmofmpqxp0000tms4st6fcb8x	Refrigerator	Fixed Assets	\N	\N	-14808.79	\N
3430922d-5860-495a-9878-ac89e2cb6e37	cmofmpqxp0000tms4st6fcb8x	REHAN LKO SALES	KAVITA	\N	\N	0.00	\N
d3914d87-3827-4f7b-b4b6-8f6a8bd1ea96	cmofmpqxp0000tms4st6fcb8x	RELLO BURNER FS 20	Fixed Assets	\N	\N	-35000.00	\N
34371b2a-e1a3-4f02-9951-6d5725d9f91b	cmofmpqxp0000tms4st6fcb8x	RENEWAL FEES	Indirect Expenses	\N	\N	0.00	\N
215f8932-848b-4338-84db-7ad2606390e6	cmofmpqxp0000tms4st6fcb8x	Rent	Indirect Expenses	\N	\N	0.00	\N
ec01b920-ca1a-4dcb-960b-8acfda410ab0	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE 12%	Repair and Maintanence	\N	\N	0.00	\N
7938d799-3a9f-4c24-8a59-e61a548362f6	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE 18%	Repair and Maintanence	\N	\N	0.00	\N
9d6d3bd1-dd18-40ec-93a5-aa4c4ef01b55	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE 18% ( D-33)	D-33 EXP	\N	\N	0.00	\N
3032f4ea-de85-4b75-8138-cb2eb1e3431f	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE 28%	Repair and Maintanence	\N	\N	0.00	\N
9487be11-9414-4fe4-9d71-22abde575bf4	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE ( D-33)	D-33 EXP	\N	\N	0.00	\N
04af1f64-17fa-48d4-9947-254c4053c0de	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE DROPING-1 ( PRAMOD )	REPAIR & MENTINANCE	\N	\N	0.00	\N
0f508257-a504-4e78-ae55-da8bbe20f48a	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE DROPING-1 ( PRAMOD ) 18%	REPAIR & MENTINANCE	\N	\N	0.00	\N
70b872ea-2891-4383-a0ac-c6d9ce0e38e9	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE MIXTURE-1 ( SIPAHILAL )	REPAIR & MENTINANCE	\N	\N	0.00	\N
d1adda3d-193c-475e-9d2b-0382d49036a2	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE MIXTURE-2 ( SIPAHILAL )	REPAIR & MENTINANCE	\N	\N	0.00	\N
b92c4794-31a3-46b8-b0c8-2b140ac1e0dc	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE MIXTURE-3 ( SIPAHILAL )	REPAIR & MENTINANCE	\N	\N	0.00	\N
58cac170-f710-4533-a81d-b95a4b24423e	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE MIXTURE-4 ( AFAK )	REPAIR & MENTINANCE	\N	\N	0.00	\N
0b16bf70-a670-40f0-a3a1-1bad47b67900	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE MIXTURE-5 ( AFAK )	REPAIR & MENTINANCE	\N	\N	0.00	\N
4682e957-a16b-40ef-a807-5faf0d7b70ee	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE MIXTURE-6 ( PRAMOD )	REPAIR & MENTINANCE	\N	\N	0.00	\N
9e5c4079-896d-4f30-8954-3e26d8327e26	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE MIXTURE-7 ( BABLU )	REPAIR & MENTINANCE	\N	\N	0.00	\N
a44ea907-20d0-4b6c-91b6-60252bbf89dc	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE MIXTURE-8 ( AZAD )	REPAIR & MENTINANCE	\N	\N	0.00	\N
60243a6c-1ebe-4811-aec3-18c0db05decb	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE MIXTURE-9 ( AZAD )	REPAIR & MENTINANCE	\N	\N	0.00	\N
cd831c1a-2805-4e03-a023-1c904efd61ae	cmofmpqxp0000tms4st6fcb8x	Repairing &amp; Maintenance Other	Repair and Maintanence	\N	\N	0.00	\N
c32469ed-4fd8-4ae7-b4dc-00b5e3a9940b	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE OVON -1 ( SIPAHILAL )	REPAIR & MENTINANCE	\N	\N	0.00	\N
506d62c4-126f-4254-b4fd-b0a7d9dcab79	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE OVON -1 ( SIPAHILAL ) 18%	REPAIR & MENTINANCE	\N	\N	0.00	\N
cbd124b1-711a-4ba3-8b64-765b4a61a106	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE OVON -2 ( SIPAHILAL )	REPAIR & MENTINANCE	\N	\N	0.00	\N
f9e17fac-eb7f-4da9-baa5-3a665243f3db	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE OVON -3 ( AFAK )	REPAIR & MENTINANCE	\N	\N	0.00	\N
46660b94-679b-4a90-9db9-a7233e0600c0	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE OVON -4 ( AFAK )	REPAIR & MENTINANCE	\N	\N	0.00	\N
f4ea8b99-358d-4117-97f3-1569696a2e94	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE OVON -4 ( AFAK ) 18%	REPAIR & MENTINANCE	\N	\N	0.00	\N
6f46c017-26fb-44d4-b196-973f9da41743	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE OVON -5 (PRAMOD )	REPAIR & MENTINANCE	\N	\N	0.00	\N
51fb7ce9-c01c-4895-95b3-eda7f0d0fe91	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE OVON -6 (BABLU )	REPAIR & MENTINANCE	\N	\N	0.00	\N
59784eb3-32a1-4d24-9a53-175f3bceaade	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE OVON -7 (AZAD)	REPAIR & MENTINANCE	\N	\N	0.00	\N
740ec497-b539-49ea-ad82-8707ec497f26	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE PACKING-1 ( SIPAHILAL )	REPAIR & MENTINANCE	\N	\N	0.00	\N
cf1de9a9-ac3f-4497-8fcf-51d3e33583c0	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE PACKING-2 ( PRAMOD )	REPAIR & MENTINANCE	\N	\N	0.00	\N
483ac43e-5219-4e32-986e-7ce09f85d4ec	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE PACKING-3 ( AZAD )	REPAIR & MENTINANCE	\N	\N	0.00	\N
ccf4b93f-ccfc-4482-9ee8-1c8fd27a73d4	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE PACKING-4 ( AZAD )	REPAIR & MENTINANCE	\N	\N	0.00	\N
3daf643e-7918-4c5b-b032-81dcf91b3d4a	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE PACKING-4 ( AZAD ) 18%	REPAIR & MENTINANCE	\N	\N	0.00	\N
22c69161-2f69-4a17-88e1-c68758eff742	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE SLIZER -1 (SIPAHILAL )	REPAIR & MENTINANCE	\N	\N	0.00	\N
36587cc6-6653-46dc-9698-3e55a8603ec6	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE SLIZER -2 (AFAK )	REPAIR & MENTINANCE	\N	\N	0.00	\N
3da6567a-69f6-4061-9dbf-b6e030e95a35	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE SLIZER -3 ( AZAD )	REPAIR & MENTINANCE	\N	\N	0.00	\N
99d6efd4-739f-4924-8da5-d0a6f4f3a084	cmofmpqxp0000tms4st6fcb8x	Repairing &amp; Maintenance U/r S3 Oven	Repair and Maintanence	\N	\N	0.00	\N
f56ac6a6-c3ca-4eb0-bdd4-8fa1780f9724	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE - VEHECLE	Repair and Maintanence(Vehicle)	\N	\N	0.00	\N
656fdd2b-62be-419d-9c97-f9f6f8602846	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE - VEHECLE 28%	Repair and Maintanence(Vehicle)	\N	\N	0.00	\N
02a8859c-a734-4d16-8f9a-30d5cf09e105	cmofmpqxp0000tms4st6fcb8x	REPAIRING &amp; MAINTENANCE VEHICLE 18%	Repair and Maintanence(Vehicle)	\N	\N	0.00	\N
37904e6d-9386-4c00-8153-cfdcc3a155d3	cmofmpqxp0000tms4st6fcb8x	Reserve and Surplus	Share Holders  Fund	\N	\N	637778.48	\N
44b94e03-3ec2-4531-8787-fa7c1ebf65f4	cmofmpqxp0000tms4st6fcb8x	REVRSE OSMOSIS PLANT (RO-250LPH)	Fixed Assets	\N	\N	-71000.00	\N
184c022b-d994-47cc-9169-133558321abe	cmofmpqxp0000tms4st6fcb8x	REWINDER MACHINE( PRINTER )	Fixed Assets	\N	\N	-175000.00	\N
092399da-9233-4316-b303-4a13da1eac33	cmofmpqxp0000tms4st6fcb8x	Rishabh Bajaj	BAJAJ JI	\N	\N	0.00	\N
c33a869d-d180-4325-9d50-4f3801de3024	cmofmpqxp0000tms4st6fcb8x	Rishabh E-Rikshaw	FREIGHT OUTWORD	\N	\N	0.00	\N
6d21769a-0ac7-4981-8d18-1e01141914df	cmofmpqxp0000tms4st6fcb8x	Rishi Kumar	Freight & Cartage O/W	\N	\N	0.00	\N
30cce2bd-43c2-406d-b326-b9711950cb76	cmofmpqxp0000tms4st6fcb8x	RISHU GUPTA	Staff & Worker ( SALARY )	\N	\N	-9808.00	\N
6b562075-c6b8-47af-a515-ccd9f8120f70	cmofmpqxp0000tms4st6fcb8x	RISHU GUPTA DR	Sundry Debtors	\N	\N	-6462.00	\N
0d54a5b7-7ad0-4265-9ff8-906693c3d298	cmofmpqxp0000tms4st6fcb8x	R K INDUSTRIES ( Madhuram )	CREDITORS ( DIPESH JI )	\N	\N	878070.00	\N
385565e6-b9ab-4ddf-8a25-ced3e21bcf6a	cmofmpqxp0000tms4st6fcb8x	R K STORE, CANAL ROAD	AMAR SONKAR	\N	\N	-1160.00	\N
e0d6f673-0874-4726-aa29-f6b679fb32ac	cmofmpqxp0000tms4st6fcb8x	Robi -Sipahi	Sipahi	\N	\N	0.00	\N
a9632cdd-bd67-44e2-86e4-80cb901b73be	cmofmpqxp0000tms4st6fcb8x	R/OFF	Indirect Expenses	\N	\N	0.00	\N
20f957b9-35ee-4a8d-bccf-94a87b8ee252	cmofmpqxp0000tms4st6fcb8x	ROHAN BAJAJ	BAJAJ JI	\N	\N	0.00	\N
52386dd6-a37a-4f24-99ee-af49bad144fd	cmofmpqxp0000tms4st6fcb8x	ROHAN BAJPAI	BAJAJ JI	\N	\N	0.00	\N
6de554ee-585f-4525-b83c-fbddde21062b	cmofmpqxp0000tms4st6fcb8x	Rohan Staff	Staff & Worker ( SALARY )	\N	\N	0.00	\N
8ff530ff-0935-4674-989a-1e36cf4b1a02	cmofmpqxp0000tms4st6fcb8x	ROHIT DM	Sundry Debtors	\N	\N	0.00	\N
d492b414-16d5-465e-aa65-4ee94734faa4	cmofmpqxp0000tms4st6fcb8x	ROHIT ENTERPRISES, ACHALGANJ	DILIP PANDYE	\N	\N	2100.00	\N
28387714-6dea-494c-9b96-8a052d5eea6e	cmofmpqxp0000tms4st6fcb8x	Rohit Enterprises,  BADARKHA	DILIP PANDYE	\N	\N	0.00	\N
b82584b5-36c0-440a-a638-623d569f4380	cmofmpqxp0000tms4st6fcb8x	ROOP RAM JI, KATRA	DILIP PANDYE	\N	\N	0.00	\N
b6c087e9-0475-4439-9a47-853848dc9814	cmofmpqxp0000tms4st6fcb8x	RO (Water Filter)	Fixed Assets	\N	\N	-6854.96	\N
345a877f-1326-4224-a251-09d06c0cae72	cmofmpqxp0000tms4st6fcb8x	ROYAL PLASTIC	Sundry Creditors	\N	\N	0.00	\N
e9f6b255-1bd6-4e3f-a1b9-e71539e4b6f0	cmofmpqxp0000tms4st6fcb8x	ROYAL SAFETY	Sundry Creditors	\N	\N	0.00	\N
6aeca1df-e8a0-4455-a7ad-e89ab940f483	cmofmpqxp0000tms4st6fcb8x	R P ENTERPRISES	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
9b3b6ca1-bce4-4d18-9358-8025f5a5b611	cmofmpqxp0000tms4st6fcb8x	R.P INDUSTRIES (INDIA) ( Creditor )	Sundry Creditors	\N	\N	0.00	\N
eaa1ad7a-4cab-4ab5-8977-e3f673556198	cmofmpqxp0000tms4st6fcb8x	R.P.&amp; Sons ( Creditor )	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
9904930c-d8ef-4d95-a8f5-b7b9d43011cd	cmofmpqxp0000tms4st6fcb8x	Rsg Profile Manufacturing Private Limited	Sundry Creditors	\N	\N	0.00	\N
211590d5-e044-4485-92ef-32722f1b1dc0	cmofmpqxp0000tms4st6fcb8x	R.T.K Enterprises, Banthra	Ashutosh Ji	\N	\N	0.00	\N
32099f94-2758-49c7-9924-bcb4baabcf4a	cmofmpqxp0000tms4st6fcb8x	Rudransh Sahu	ANANTRAM JI	\N	\N	0.00	\N
e2d5102b-2d89-4157-a555-35e7be00af66	cmofmpqxp0000tms4st6fcb8x	RUDRA SAHU	ANANTRAM JI	\N	\N	0.00	\N
a673629d-aa1a-4518-883c-f42d311405ac	cmofmpqxp0000tms4st6fcb8x	RUSK PACKING MACHINE	Fixed Assets	\N	\N	-467500.00	\N
a0992eb8-0f04-44af-8c22-014138ad4c82	cmofmpqxp0000tms4st6fcb8x	Rusk Production Labour Charges ( GATTU )	Direct Expenses	\N	\N	0.00	\N
fc49f7eb-7fec-4262-a14b-bfc2f5a71694	cmofmpqxp0000tms4st6fcb8x	SAAWARIYA ENTERPRISES-KNP	KANPUR	\N	\N	0.00	\N
3b6cae0f-689b-4760-84b8-eba6f5d6ddb5	cmofmpqxp0000tms4st6fcb8x	SACHE (BISCUITS)	Fixed Assets	\N	\N	0.00	\N
eb520345-25da-4947-8ae7-deb7653112a9	cmofmpqxp0000tms4st6fcb8x	SACHE GATTU	Fixed Assets	\N	\N	-103309.31	\N
c63b14e1-ac09-4b80-b0a2-6a1fcd6716be	cmofmpqxp0000tms4st6fcb8x	SACHHE &amp; DHAKKAN 80G	Fixed Assets	\N	\N	-67623.50	\N
8c44ae53-3f6c-478f-961e-3de1b94fe227	cmofmpqxp0000tms4st6fcb8x	SACHHE &amp; DHAKKAN CUSTOM	Fixed Assets	\N	\N	-7728.20	\N
d5fd3909-22fe-4661-b338-89db8bc3bad6	cmofmpqxp0000tms4st6fcb8x	Sachin (Baba Pac)	Sundry Debtors	\N	\N	0.00	\N
e24c3d5a-7ba6-44a8-91aa-478b795e96a5	cmofmpqxp0000tms4st6fcb8x	SACHIN SAHU	ANANTRAM JI	\N	\N	0.00	\N
1cd8d3a2-24e8-40a7-b563-8935429d344d	cmofmpqxp0000tms4st6fcb8x	Sadhana Agencies	ANANTRAM JI	\N	\N	0.00	\N
0e4c9b66-828b-4e8c-97ca-f3e4059c318d	cmofmpqxp0000tms4st6fcb8x	SAEED AHMAD-RAIBARELI	OUT OF KANPUR	\N	\N	0.00	\N
4f295822-8637-4d07-b4d8-a436b740e685	cmofmpqxp0000tms4st6fcb8x	SAHU BAKERS	ANANTRAM JI	\N	\N	0.00	\N
2804e8cf-761a-4e5e-b33a-c7475bd8f499	cmofmpqxp0000tms4st6fcb8x	SAHU ENTERPRISES	ANANTRAM JI	\N	\N	0.00	\N
f5f7753f-a8df-4f0b-89af-4c9b7202ae9a	cmofmpqxp0000tms4st6fcb8x	SAHU NAMKEEN Nayaganj	AMAR SONKAR	\N	\N	-3100.00	\N
d7b6f04b-6020-46d9-84e6-f3ea869bd4b2	cmofmpqxp0000tms4st6fcb8x	SAHU TRADERS	ANANTRAM JI	\N	\N	0.00	\N
00284abb-eba8-45d9-b3c1-b34334426bce	cmofmpqxp0000tms4st6fcb8x	SAIF STORE,FAITHFULL GANJ	AMAR SONKAR	\N	\N	0.00	\N
5f543aa1-fa31-400f-9687-2fbf3c53e8b2	cmofmpqxp0000tms4st6fcb8x	SAI MANIT INDUSTRIES	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
3deb8ea8-3746-4248-bc76-135b39965919	cmofmpqxp0000tms4st6fcb8x	SAKIR RAHMANI BREAD WALE, KALPI	Ashutosh Ji	\N	\N	0.00	\N
c5a24ae5-aebc-4182-9763-416fe059a067	cmofmpqxp0000tms4st6fcb8x	Saksham Prahari Security and Manpower Services	Sundry Creditors	\N	\N	0.00	\N
e9c28038-a40c-46ee-8a9c-e6f24c65856a	cmofmpqxp0000tms4st6fcb8x	Salary Payable	Provisions	\N	\N	0.00	\N
1c1ccd8a-35f1-4464-9c48-fea83deca428	cmofmpqxp0000tms4st6fcb8x	Salary &amp; Wages(Staff)	Indirect Expenses	\N	\N	0.00	\N
58a74fed-7273-481d-93ba-e0ef7290a6d2	cmofmpqxp0000tms4st6fcb8x	SALE@ 18%	Sales Accounts	\N	\N	0.00	\N
c798fe1f-e2fe-4b20-92a8-ef056f42fb2b	cmofmpqxp0000tms4st6fcb8x	SALE @5%	Sales Accounts	\N	\N	0.00	\N
c7868e76-9c1b-4376-ae1c-8b40da70fa1b	cmofmpqxp0000tms4st6fcb8x	SALES EXEMPTED	Sales Accounts	\N	\N	0.00	\N
e704f4e7-12f3-47a0-b8bc-4b5ac2eece45	cmofmpqxp0000tms4st6fcb8x	Sales to Branch(HR)	Sales Accounts	\N	\N	0.00	\N
43425f31-92e2-4e0c-92d5-b5ff6cb50b13	cmofmpqxp0000tms4st6fcb8x	V.K Stores, Lalitpur	Lalitpur	\N	\N	-84288.00	\N
819176a4-4b67-4f33-b80c-3e549a0c08ac	cmofmpqxp0000tms4st6fcb8x	Sameer Bakery Bardana	Sundry Creditors -Exp	\N	\N	-8523.00	\N
537c8f56-400c-4891-a0c1-d94501503d42	cmofmpqxp0000tms4st6fcb8x	SAMPLE (THEKEDAAR)	Indirect Expenses	\N	\N	0.00	\N
fe0626b8-2539-4ec6-abe7-7533a1a5aa99	cmofmpqxp0000tms4st6fcb8x	SANATAN PRESS	CREDITORS ( DIPESH JI )	\N	\N	100159.00	\N
8b0d0388-d894-423a-b349-21f4ec3ae747	cmofmpqxp0000tms4st6fcb8x	Sanchey	Fixed Assets	\N	\N	-151350.03	\N
edd0d604-84b0-4667-b67a-46a0fd23cd53	cmofmpqxp0000tms4st6fcb8x	SANDEEP BAJPAI	BAJAJ JI NEW	\N	\N	160000.00	\N
82167c59-f302-4146-a0d3-cff60fe1bab8	cmofmpqxp0000tms4st6fcb8x	SANDEEP ( CARPENTER )	Indirect Expenses	\N	\N	0.00	\N
d5b527a7-3a0c-4b38-865e-b86fd6946df3	cmofmpqxp0000tms4st6fcb8x	SANDEEP STORE, MASALA GALI	AMAR SONKAR	\N	\N	0.00	\N
a66c61e9-90a8-4977-88a9-6ad57ade1ad7	cmofmpqxp0000tms4st6fcb8x	Sangam Packaging	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
5241149e-28a0-4147-8f54-3170ace64cd8	cmofmpqxp0000tms4st6fcb8x	SANGAM SHAKAR PISAI KENDRA(Gogiya)	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
4ffc53e4-1b64-4f61-b791-e64211b09df8	cmofmpqxp0000tms4st6fcb8x	SANITATION EXP.	Office Exp	\N	\N	0.00	\N
0d59ba41-0818-4640-889b-4b50ba215dfe	cmofmpqxp0000tms4st6fcb8x	SANJAY BAJAJ	BAJAJ JI	\N	\N	0.00	\N
219f4359-5cf9-47a3-b7bc-fde5f486b45b	cmofmpqxp0000tms4st6fcb8x	SANJAY BAJPAI	BAJAJ JI	\N	\N	0.00	\N
74ff9973-a629-4a5f-b935-ed60c170f979	cmofmpqxp0000tms4st6fcb8x	SANJAY ( LOADER )	FREIGHT OUTWORD	\N	\N	0.00	\N
1623ae89-750f-426f-91f3-51d43a1a8d9c	cmofmpqxp0000tms4st6fcb8x	SANJAY SAHU	ANANTRAM JI	\N	\N	0.00	\N
8910e70c-e23e-4d3a-989f-123de7a0a172	cmofmpqxp0000tms4st6fcb8x	SANJEEVAN ( LOADER )	FREIGHT OUTWORD	\N	\N	0.00	\N
063a77e7-fe49-4910-b9f2-fc6c10373087	cmofmpqxp0000tms4st6fcb8x	SANJEEV KUMAR JAIN-JHANSI(Moth)	OUT OF KANPUR	\N	\N	0.00	\N
58cb2e8e-f25c-4c96-8d22-9e407628e988	cmofmpqxp0000tms4st6fcb8x	Sanjivani Tea	Sundry Creditors	\N	\N	0.00	\N
8840fe03-e80c-4e3d-8f4b-df4c04859f87	cmofmpqxp0000tms4st6fcb8x	SANTOSH BAJPAI	BAJAJ JI	\N	\N	0.00	\N
d290a0d9-8669-4832-8010-817aad149087	cmofmpqxp0000tms4st6fcb8x	SANTOSH KUMAR VISHWAKARMA	Staff & Worker ( SALARY )	\N	\N	0.00	\N
fb83cc60-5712-4463-9872-cf54ca20c89e	cmofmpqxp0000tms4st6fcb8x	SANTOSH NAMKEEN, EXPRESS ROAD	AMAR SONKAR	\N	\N	-1200.00	\N
11526abe-5232-44e3-a002-aad4baa25ba3	cmofmpqxp0000tms4st6fcb8x	SANTOSH PROVISION Hoolaganj	AMAR SONKAR	\N	\N	0.00	\N
d9ce4b9b-0622-4b24-ab71-f8fb9e21a9ca	cmofmpqxp0000tms4st6fcb8x	SANTOSH SAHU	ANANTRAM JI	\N	\N	0.00	\N
0b5646bb-d2b8-4779-b4f9-005a9d63830d	cmofmpqxp0000tms4st6fcb8x	Sara Traders, Gorakhpur	OUT OF KANPUR	\N	\N	0.00	\N
aadac34f-1335-4bc5-b5c6-e743642c066c	cmofmpqxp0000tms4st6fcb8x	SATENDRA SAHU	ANANTRAM JI	\N	\N	0.00	\N
2dcf4202-227b-444f-84ce-f5167ca10c94	cmofmpqxp0000tms4st6fcb8x	Satish Kumar ( Jhansi ) - 09/12/2024	Staff & Worker ( SALARY )	\N	\N	0.00	\N
902d8d1c-2c16-48ca-9b7f-d09e9370b32b	cmofmpqxp0000tms4st6fcb8x	SATISH KUMAR SUNIL KUMAR, Sitapur	OUT OF KANPUR	\N	\N	-96706.00	\N
8c1eb259-a4e2-4c3c-a512-d07fe309d017	cmofmpqxp0000tms4st6fcb8x	SATISH LOADING BILL	Sundry Debtors	\N	\N	0.00	\N
245d07ca-810b-4d75-b37e-787a021d65cd	cmofmpqxp0000tms4st6fcb8x	SATISH  (LOADING STAFF )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
ab2caf72-aacd-42fb-8c00-10832b572af1	cmofmpqxp0000tms4st6fcb8x	SATISH PLUMBER	Sundry Creditors -Exp	\N	\N	0.00	\N
629bc0a9-c2ca-4162-aa81-311962259469	cmofmpqxp0000tms4st6fcb8x	SATISH SAHU	ANANTRAM JI	\N	\N	0.00	\N
dc7eb594-79c9-48cf-96e8-79da154d77f5	cmofmpqxp0000tms4st6fcb8x	Satish- Sipahi	Sipahi	\N	\N	0.00	\N
bc95c617-0633-44da-adea-fa691362762c	cmofmpqxp0000tms4st6fcb8x	SATYAM &amp; CO.	Sundry Creditors -Exp	\N	\N	2300.00	\N
2ef236ce-8e8a-4253-98ac-762dd733c952	cmofmpqxp0000tms4st6fcb8x	SAURABH SAHU	ANANTRAM JI	\N	\N	0.00	\N
98fa9483-9052-409f-9d32-1e4a63b61bc6	cmofmpqxp0000tms4st6fcb8x	SAURABH STORE, HULA GANJ	AMAR SONKAR	\N	\N	-1100.00	\N
afd972a8-5d29-4350-ba52-3c0dde92ff0c	cmofmpqxp0000tms4st6fcb8x	SAVARIYA TRADERS, CHIRGAON	SATISH	\N	\N	0.00	\N
58683b74-2111-401d-8362-7d7198d43f5d	cmofmpqxp0000tms4st6fcb8x	SBI A/c No.43061657013	Bank Accounts	\N	\N	-11017.00	\N
39b4cbbd-2f38-44b4-a8c1-4125c8739c63	cmofmpqxp0000tms4st6fcb8x	S.B. PRODUCTS	Sundry Creditors	\N	\N	0.00	\N
f9783fce-efdb-4296-9196-4eb62fb2e099	cmofmpqxp0000tms4st6fcb8x	Scrap Sale Gatte @12%	Indirect Incomes	\N	\N	0.00	\N
fbfc8505-916d-4c7d-bbae-3864db42291b	cmofmpqxp0000tms4st6fcb8x	Scrap Sale Gatte @5%	Indirect Incomes	\N	\N	0.00	\N
bf03107c-38ee-4da5-9e95-ca3b0b43cdc6	cmofmpqxp0000tms4st6fcb8x	SCRAP SALE PLASTIC 18%	Indirect Incomes	\N	\N	0.00	\N
9243175b-c28f-4be2-96ec-98577d353821	cmofmpqxp0000tms4st6fcb8x	SCRAP TIN 18%	Indirect Incomes	\N	\N	0.00	\N
9c79ce23-297e-4019-a715-4a92f5daf511	cmofmpqxp0000tms4st6fcb8x	SCRENING	Direct Expenses	\N	\N	0.00	\N
638033f1-7fd0-43df-9cd5-3f7fcb1c132c	cmofmpqxp0000tms4st6fcb8x	S D Food  ( Google Pay )	Bank Accounts	\N	\N	59985.92	\N
9980a9d3-813c-4a80-ac6e-c34ac13a6c7a	cmofmpqxp0000tms4st6fcb8x	S D FOOD PRODUCTS	Sundry Creditors	\N	\N	0.00	\N
674fb5dc-a434-4500-8b35-3e2e52334af3	cmofmpqxp0000tms4st6fcb8x	S D Food Products(After Transfer)	Sundry Debtors	\N	\N	0.00	\N
9889d1a6-83f4-4c65-8460-a1fc62a0bff2	cmofmpqxp0000tms4st6fcb8x	SDZ Food Products Private Limited	Sundry Creditors	\N	\N	0.00	\N
76257b27-12ba-4506-8888-8fc98e13c904	cmofmpqxp0000tms4st6fcb8x	SECURITY GUARD	Indirect Expenses	\N	\N	0.00	\N
cf0bf093-a7fd-4763-8708-b32274a1b605	cmofmpqxp0000tms4st6fcb8x	SECURITY WITH CUGL	Loans & Advances (Asset)	\N	\N	-11225.00	\N
43d333be-f755-441f-aa30-ad124c09118f	cmofmpqxp0000tms4st6fcb8x	SERVICE CHARGES 18 %	Indirect Expenses	\N	\N	0.00	\N
f0637b2d-acb1-44c9-95f4-03153c08216c	cmofmpqxp0000tms4st6fcb8x	Servokon Stavilizer ( SKR190A )	Fixed Assets	\N	\N	-4673.13	\N
0828947b-d988-4fe9-8b1c-e277a73fcd0d	cmofmpqxp0000tms4st6fcb8x	SERVO SET	Fixed Assets	\N	\N	-143600.00	\N
89e06a9c-ba4d-4b7a-b827-87fd3e7f4a60	cmofmpqxp0000tms4st6fcb8x	SETHI TYREWALA	Sundry Creditors	\N	\N	0.00	\N
87f37912-07d1-429f-a554-0bcb3ff4cc29	cmofmpqxp0000tms4st6fcb8x	SEVANA 200V2 (SEALING MACHINE)	Fixed Assets	\N	\N	-1175.68	\N
ef0a61f9-c12e-420f-8885-f450861cec73	cmofmpqxp0000tms4st6fcb8x	SGST 6%	Duties & Taxes	\N	\N	0.00	\N
2f06c8fc-4d3f-45fa-a8bb-a87e2d37abf9	cmofmpqxp0000tms4st6fcb8x	Sgst 9%	Duties & Taxes	\N	\N	1953.15	\N
282f0e6b-c77a-4a76-8779-e63095753275	cmofmpqxp0000tms4st6fcb8x	SGST Payable	Duties & Taxes	\N	\N	0.00	\N
310f5f37-7da4-44f7-b325-8e07ae0aa9fd	cmofmpqxp0000tms4st6fcb8x	SGST Receivable	Duties & Taxes	\N	\N	0.00	\N
4afa5500-d8d6-4b10-89f0-f5f1b9b90f48	cmofmpqxp0000tms4st6fcb8x	SHANI KUMAR, PUKHRAYA	OUT OF KANPUR	\N	\N	0.00	\N
4509020d-9a2e-4cca-beb3-67be891e116f	cmofmpqxp0000tms4st6fcb8x	SHANKAR BAJAJ	BAJAJ JI	\N	\N	0.00	\N
dab6a44d-71bd-413b-84cf-5b866a177cef	cmofmpqxp0000tms4st6fcb8x	SHANKAR DADA	Staff & Worker ( SALARY )	\N	\N	0.00	\N
fb060ae3-79d1-46b5-bfff-76385c70cee8	cmofmpqxp0000tms4st6fcb8x	SHANKAR DADA BILL	Sundry Debtors	\N	\N	0.00	\N
92420494-7d00-4dd4-a018-e4bf8f4cb5f8	cmofmpqxp0000tms4st6fcb8x	SHANKAR DADA (convenience)	Conveyance	\N	\N	0.00	\N
1cf75d5e-fd16-440a-896e-14fed2c8ebd1	cmofmpqxp0000tms4st6fcb8x	SHANKAR SAHU	ANANTRAM JI	\N	\N	0.00	\N
71aac7e2-07d9-436e-a523-81f0b72bb8b0	cmofmpqxp0000tms4st6fcb8x	Shanker Bajpai	BAJAJ JI	\N	\N	0.00	\N
969d62bc-80bc-4e9d-ba14-d87ff165242c	cmofmpqxp0000tms4st6fcb8x	Shanti Krishna Trader	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
ce04e566-a200-4d5b-a2c8-a39de263ae33	cmofmpqxp0000tms4st6fcb8x	SHANTI PACKING STAFF	Staff & Worker ( SALARY )	\N	\N	0.00	\N
5a38794b-2fd4-4248-9090-8e37e731b181	cmofmpqxp0000tms4st6fcb8x	SHANU BAJAJ	BAJAJ JI	\N	\N	0.00	\N
b92746e0-9885-43a5-babe-ab316c346619	cmofmpqxp0000tms4st6fcb8x	SHANU STORE, RIAL BAZAR	AMAR SONKAR	\N	\N	0.00	\N
8f1e9c52-a9ce-4ad7-9820-e44db196410b	cmofmpqxp0000tms4st6fcb8x	Shanvi Packaging	Sundry Creditors -Exp	\N	\N	0.00	\N
8748e0ce-8321-4fdd-981e-5dd09bc935ea	cmofmpqxp0000tms4st6fcb8x	SHARAPHAT &amp; COMPANY, JHINJHAK	DILIP PANDYE	\N	\N	0.00	\N
2a4964a1-7107-4d6a-8d6f-51a9cedbe8bc	cmofmpqxp0000tms4st6fcb8x	SHARDDHA NIGHT PATROLLING SECURITY SERVICES	Sundry Creditors	\N	\N	0.00	\N
c366b99c-4195-4562-a96d-cb092efe85f1	cmofmpqxp0000tms4st6fcb8x	SHARMA FRAGRANEAS, BACHHARAWA	RAIBERELY	\N	\N	0.00	\N
036bfa51-1795-4509-9324-726b33fea863	cmofmpqxp0000tms4st6fcb8x	SHARMA JI GAUARD Bill	Sundry Debtors	\N	\N	0.00	\N
17e35cd5-c4a7-49e9-9081-54f188fb5eaa	cmofmpqxp0000tms4st6fcb8x	SHARMA JI GAURD	Staff & Worker ( SALARY )	\N	\N	-14660.00	\N
8805d255-0fe6-49ae-af3e-07c550d04105	cmofmpqxp0000tms4st6fcb8x	SHARMA TRADERS	ANANTRAM JI	\N	\N	0.00	\N
5d807018-9627-4743-b4be-f29e2876cc97	cmofmpqxp0000tms4st6fcb8x	SHEERAZ HUSAIN WARSI  Lucknow	Ashutosh Ji	\N	\N	0.00	\N
ade88de1-740c-441b-9b9f-39517efdfb10	cmofmpqxp0000tms4st6fcb8x	SHIFTER (S.S)	Fixed Assets	\N	\N	-50000.00	\N
40e2b401-a714-45a6-86f1-11babf91bc64	cmofmpqxp0000tms4st6fcb8x	SHIKHA ENTERPRISES, LUCKNOW	Gaurav, LUCKNOW	\N	\N	0.00	\N
c4307e54-734f-4031-9cf6-632eeb7f0763	cmofmpqxp0000tms4st6fcb8x	SHIVA BAJAJ	BAJAJ JI	\N	\N	0.00	\N
8f155076-a4f9-4979-a942-e9a47cf600e0	cmofmpqxp0000tms4st6fcb8x	SHIVA BAJPAI	BAJAJ JI	\N	\N	0.00	\N
bae0c2c6-2648-4bea-87ed-8bc66b9d79f9	cmofmpqxp0000tms4st6fcb8x	SHIVAM BAJPAI	BAJAJ JI	\N	\N	0.00	\N
97f140b8-c971-49ba-aea4-a7a48a77d3e1	cmofmpqxp0000tms4st6fcb8x	SHIVAM BISCUITS	BISCUITS SALARY	\N	\N	0.00	\N
1eabe1f0-857d-4c8f-ba20-921351907351	cmofmpqxp0000tms4st6fcb8x	SHIVAM B RUSK	Sundry Debtors	\N	\N	0.00	\N
ea95cb2a-1392-454e-985a-bf6f953aedf9	cmofmpqxp0000tms4st6fcb8x	Shivam Conveyar	CONVEYAR	\N	\N	0.00	\N
db0c0472-036b-44ef-98bb-1cd7540afcb9	cmofmpqxp0000tms4st6fcb8x	SHIVAM INDUSTRIES	Sundry Creditors	\N	\N	0.00	\N
52821b9a-d9d9-4e3a-a822-d8b035c191b9	cmofmpqxp0000tms4st6fcb8x	SHIVAM MALHOTRA, SHIKHOHABAD	SHIKHOHABAD	\N	\N	0.00	\N
9651e0bd-a26a-46e5-97bd-bfe4e6aa8cf3	cmofmpqxp0000tms4st6fcb8x	SHIVAM SAHU	ANANTRAM JI	\N	\N	0.00	\N
4813632a-ea47-4e6e-b446-0e36c3c97d2c	cmofmpqxp0000tms4st6fcb8x	SHIVANGI ENTERPRISES	ANANTRAM JI	\N	\N	0.00	\N
799afc2a-9ece-45fe-8390-8c2713c9920c	cmofmpqxp0000tms4st6fcb8x	SHIVANI BATHAM	VIJAY BATHAM	\N	\N	-300000.00	\N
b39d98fa-addf-4406-a975-881f4d2922b0	cmofmpqxp0000tms4st6fcb8x	SHIVAp E-Rikshaw	FREIGHT OUTWORD	\N	\N	0.00	\N
038e2eb0-6ef8-476d-ac82-a3e722ea928b	cmofmpqxp0000tms4st6fcb8x	SHIV BAJAJ	BAJAJ JI	\N	\N	0.00	\N
ff200fd4-7f9a-4476-9309-c08ced77b1d9	cmofmpqxp0000tms4st6fcb8x	SHIV BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
3d27a336-1e64-4ee3-85e9-563782951171	cmofmpqxp0000tms4st6fcb8x	SHIV ENTERPRISES (LUCKNOW)	Lucknow Distributor	\N	\N	0.00	\N
3d578d3b-1e74-45f2-8197-cf191bfd0bf6	cmofmpqxp0000tms4st6fcb8x	SHIV KUMAR ( LOADER )	FREIGHT OUTWORD	\N	\N	0.00	\N
163e2d14-723d-4a38-91cb-ee1b1a8a7bd2	cmofmpqxp0000tms4st6fcb8x	Shivkumar Sahu	ANANTRAM JI	\N	\N	0.00	\N
398707c3-75cd-4fb0-abc6-a07b7bf7e122	cmofmpqxp0000tms4st6fcb8x	Shivoham Bajpai	BAJAJ JI	\N	\N	0.00	\N
756d4760-d61b-4314-81a0-0970ef03a179	cmofmpqxp0000tms4st6fcb8x	SHIV OHAM SHUKLA ( 22/10/24 )	Staff & Worker ( SALARY )	\N	\N	0.00	\N
01860968-2635-466f-b658-21d47faaaa65	cmofmpqxp0000tms4st6fcb8x	SHIV OHAM SHUKLA ( TOUR )	Sundry Creditors(Tour)	\N	\N	0.00	\N
b9b7bb72-3ad5-47c6-8c2f-69a4ff38010a	cmofmpqxp0000tms4st6fcb8x	SHIV SAHU	ANANTRAM JI	\N	\N	0.00	\N
4da687e6-194d-4216-aca9-8669fc48a8be	cmofmpqxp0000tms4st6fcb8x	SHIV SHANKAR BAJPAI	BAJAJ JI	\N	\N	0.00	\N
44233b61-30ec-4eb2-bd12-faaf60c7f13a	cmofmpqxp0000tms4st6fcb8x	SHREE ANAND KIRANA STORE	CREDITORS ( DIPESH JI )	\N	\N	-75969.00	\N
f4e8306f-8c62-4e08-9ee4-72fef40401a7	cmofmpqxp0000tms4st6fcb8x	Shree Annapurna Bhandar ( Creditor )	CREDITORS ( DIPESH JI )	\N	\N	1698928.96	\N
0f25340a-6370-4f40-96c4-8f4d0b13da8e	cmofmpqxp0000tms4st6fcb8x	Shree Bherav Baba Industries	Sundry Creditors -Exp	\N	\N	0.00	\N
03ebbb48-3641-4c12-ab51-6c0f9fb40c3b	cmofmpqxp0000tms4st6fcb8x	Shree D.M. Electrical Agencies	Sundry Creditors	\N	\N	0.00	\N
8156bc67-022a-4795-8793-c875cfc17618	cmofmpqxp0000tms4st6fcb8x	Shree D M Electric Co. ( Creditor )	Sundry Creditors -Exp	\N	\N	123585.00	\N
fe2ad61b-2959-4501-a311-6e339cdb4df1	cmofmpqxp0000tms4st6fcb8x	SHREE OM BAKING SYSTEM &amp; MACHINE	Sundry Creditors	\N	\N	0.00	\N
cb3dd97a-e579-4e5c-baee-5ce1c253c416	cmofmpqxp0000tms4st6fcb8x	SHREE RADHEY RADHEY TRADERS, DIBIYAPUR	DIBIYAPUR	\N	\N	0.00	\N
8aa690a7-d665-42d9-96fc-2dd6e6501172	cmofmpqxp0000tms4st6fcb8x	SHREE RAM DISTRIBUTORS	Sundry Creditors -Exp	\N	\N	0.00	\N
ced2d194-1fb7-49e6-a458-8ab7b463d2e6	cmofmpqxp0000tms4st6fcb8x	SHREE SHYAM AGENCIES	Ashutosh Ji	\N	\N	0.00	\N
bad8c259-ce45-43fc-bd8b-8baeba364cb6	cmofmpqxp0000tms4st6fcb8x	Shree Shyam Enterprises	KANPUR	\N	\N	0.00	\N
4dce121f-d232-45c2-9fb7-fecb9f79c347	cmofmpqxp0000tms4st6fcb8x	Shree Shyam Traders, BAREILLY	Gaurav, LUCKNOW	\N	\N	-138083.00	\N
959ac363-f397-411b-94ce-1077bc9db20c	cmofmpqxp0000tms4st6fcb8x	Shreyansh Gupta, Shuklaganj	SHUKLAGANJ	\N	\N	0.00	\N
dcc53b0c-4965-4197-a30a-e91114cd5dab	cmofmpqxp0000tms4st6fcb8x	Shri Balaji Enterprises	Sundry Creditors	\N	\N	0.00	\N
0b56b84b-99ce-4b73-9cda-0a6fd27444e4	cmofmpqxp0000tms4st6fcb8x	SHRI BALAJI TRADERS-KONCH	OUT OF KANPUR	\N	\N	0.00	\N
3fabad37-5251-4ab4-958f-10a7b9dab953	cmofmpqxp0000tms4st6fcb8x	SHRI BALAJI TRADERS, YASHODA NAGAR	Ashutosh Ji	\N	\N	0.00	\N
3e5bbdc9-78f6-4937-b21d-e0d356c9cbd4	cmofmpqxp0000tms4st6fcb8x	SHRI BALAJI TRADING CO., Mahoba	OUT OF KANPUR	\N	\N	0.00	\N
814b9164-e2b4-41ea-8552-f66c1f07c2bd	cmofmpqxp0000tms4st6fcb8x	Shri Belaji Traders, GORAKHPUR	OUT OF KANPUR	\N	\N	-2978.00	\N
c0ec15a0-fb22-4651-aa02-125dc824e77c	cmofmpqxp0000tms4st6fcb8x	SHRI GAJANAN AGENCY, BIGHAPUR	OUT OF KANPUR	\N	\N	0.00	\N
8d101ffd-8412-4d86-bde2-6738b17beb84	cmofmpqxp0000tms4st6fcb8x	Shri Girraj Traders, Bareilly	Gaurav, LUCKNOW	\N	\N	0.00	\N
81ca6127-43d2-47cb-aa37-e86a61dbca7a	cmofmpqxp0000tms4st6fcb8x	SHRI GURUNANAK AGENCY, KATNI	OUT OF KANPUR	\N	\N	0.00	\N
c1751f79-06df-41a6-8ede-e4561483d0d1	cmofmpqxp0000tms4st6fcb8x	Shri Lalwani Traders	KAVITA	\N	\N	0.00	\N
e0d12e81-9bb1-4a8b-bdca-4982804f58eb	cmofmpqxp0000tms4st6fcb8x	Shri PRAKHAS STORE, EXPRESS ROAD	AMAR SONKAR	\N	\N	-3100.00	\N
01b13b10-5278-4252-8c14-5a18c254e5c4	cmofmpqxp0000tms4st6fcb8x	SHRI RAM FIRE EQUIPMENT &amp; SERVICES	Sundry Creditors -Exp	\N	\N	0.00	\N
086e06d4-2dd8-4a39-8f16-2569b9eeaa7c	cmofmpqxp0000tms4st6fcb8x	Shri Ram Traders	KANPUR	\N	\N	0.00	\N
be4caaae-d889-401c-b28f-ec43f1df0739	cmofmpqxp0000tms4st6fcb8x	SHRI SAWAN TRADING CO.	Sundry Creditors	\N	\N	0.00	\N
34605671-5822-4048-b35c-c0ad63434859	cmofmpqxp0000tms4st6fcb8x	Shrish Chandra Gupta , Bachrawa	Gaurav, LUCKNOW	\N	\N	-3574.00	\N
7c502469-906b-49f2-aa5b-545004462673	cmofmpqxp0000tms4st6fcb8x	SHRI SHYAM TRADERS Balrampur	Ashutosh Ji	\N	\N	16390.00	\N
f72a87e9-a56a-482d-8818-09403e78fb1e	cmofmpqxp0000tms4st6fcb8x	SHRI SHYAM TRADERS(NAUTANWA)	Sundry Debtors	\N	\N	0.00	\N
0ac604b6-86d7-4cef-a00a-c845109acd54	cmofmpqxp0000tms4st6fcb8x	SHRI VJV ENTERPRISES	CREDITORS ( DIPESH JI )	\N	\N	25200.00	\N
0ff937fc-d7f0-4e5b-b46b-98aea0fb8416	cmofmpqxp0000tms4st6fcb8x	SHUBASH  SAHU	ANANTRAM JI	\N	\N	0.00	\N
425d8e2a-beee-4d8a-9324-bd39f9cd2f69	cmofmpqxp0000tms4st6fcb8x	SHUBHAM ACCOUNTING &amp; ONSULTANCY	Sundry Creditors -Exp	\N	\N	0.00	\N
34bd4fef-a811-402a-98e8-9474e3815ae2	cmofmpqxp0000tms4st6fcb8x	Shubham Computronics ( Creditor )	Sundry Creditors -Exp	\N	\N	15940.00	\N
ec7f7815-6122-4edc-b95a-a9af9e5243ea	cmofmpqxp0000tms4st6fcb8x	SHUBHAM GUPTA, NAYAGANJ	AMAR SONKAR	\N	\N	-1240.00	\N
19495218-3ca6-4fb3-860b-44468ef155a5	cmofmpqxp0000tms4st6fcb8x	Shubham Ji	BAJAJ JI	\N	\N	0.00	\N
33646b44-acf7-4177-880c-39af02d17055	cmofmpqxp0000tms4st6fcb8x	SHUBHAM MISHRA	Sundry Creditors(Tour)	\N	\N	0.00	\N
32567eaf-718d-4555-810e-0ef63f3b946d	cmofmpqxp0000tms4st6fcb8x	Shubham Omer(Safipur)	Ashutosh Ji	\N	\N	5428.00	\N
d842122a-c716-4bec-9c51-592aae02aa98	cmofmpqxp0000tms4st6fcb8x	SHUBHAM YADAV (BILHAUR)	OUT OF KANPUR	\N	\N	0.00	\N
5680f61a-28c2-4b69-b960-015b22d9c10f	cmofmpqxp0000tms4st6fcb8x	Shubharambh Marketing, SATNA	OUT OF KANPUR	\N	\N	0.00	\N
68566986-7874-4484-951c-6e00f6d6ffb7	cmofmpqxp0000tms4st6fcb8x	Shubh Traders, Auriya	Ashutosh Ji	\N	\N	-15081.00	\N
311a3d6c-7495-430c-b9e8-538e02855aa4	cmofmpqxp0000tms4st6fcb8x	shukla ji Convyance	Conveyance	\N	\N	0.00	\N
cff2b1fa-779a-4645-a88c-c87d912e6901	cmofmpqxp0000tms4st6fcb8x	SHUSHMA ELAICHI BILL	Sundry Debtors	\N	\N	-5595.00	\N
09b3fec7-f092-4b5b-b0b0-c692c5efcc4d	cmofmpqxp0000tms4st6fcb8x	Shusma Staff	Staff & Worker ( SALARY )	\N	\N	0.00	\N
a49b9f35-6ea6-4692-a644-33cb1b1a4036	cmofmpqxp0000tms4st6fcb8x	SHYAM BAJAJ	BAJAJ JI	\N	\N	0.00	\N
328cffb1-a7b4-44b6-9cca-c889e94a61c7	cmofmpqxp0000tms4st6fcb8x	Shyam Bajpai	BAJAJ JI NEW	\N	\N	0.00	\N
44a9829b-34dd-4f8d-ba03-2b2516a105ca	cmofmpqxp0000tms4st6fcb8x	SHYAM LAL	BAJAJ JI	\N	\N	0.00	\N
d0faef60-f893-4a92-9804-b912fe674899	cmofmpqxp0000tms4st6fcb8x	SHYAM SAHU	ANANTRAM JI	\N	\N	0.00	\N
c0c981f9-b29b-4131-a828-43bf40f3c33e	cmofmpqxp0000tms4st6fcb8x	SHYAM TRADERS	ANANTRAM JI	\N	\N	0.00	\N
436a0b9e-25aa-4b8d-85f9-dbd0db71a979	cmofmpqxp0000tms4st6fcb8x	SHYAM TRADING COMPANY	BAJAJ JI	\N	\N	0.00	\N
cc4f736b-9c46-41e2-b23e-a475cae7fd17	cmofmpqxp0000tms4st6fcb8x	SHYAM TRADING COMPANY GHI	Sundry Creditors	\N	\N	0.00	\N
7ef58320-f409-4c89-b822-71bd6e2d6360	cmofmpqxp0000tms4st6fcb8x	SIDDHI ENTERPRISES	ANANTRAM JI	\N	\N	0.00	\N
b8c231a0-392d-4e32-b15f-651c13bcbcda	cmofmpqxp0000tms4st6fcb8x	SIPAHILAL( ADVANCE )	Staff & Worker ( SALARY )	\N	\N	-20000.00	\N
c0ca9d2e-c8de-4228-bdd4-81db2ad33c3a	cmofmpqxp0000tms4st6fcb8x	SIPAHILAL(REPAIRING )	Indirect Expenses	\N	\N	0.00	\N
a2fa34aa-601b-42c7-97a4-9034ae6c4a16	cmofmpqxp0000tms4st6fcb8x	SIPAHILAL |( THEKEDAR )	Sipahi	\N	\N	-585058.00	\N
72921488-03ba-46bd-ba27-a88383dc1bb1	cmofmpqxp0000tms4st6fcb8x	SIPAHI- RABI	Sipahi	\N	\N	0.00	\N
80d55aee-eba1-4f45-9033-a3f40fd48ec3	cmofmpqxp0000tms4st6fcb8x	S K Traders , AURAIYA	OUT OF KANPUR	\N	\N	0.00	\N
5b4eaff9-ce61-4ab4-8879-b02eae62408e	cmofmpqxp0000tms4st6fcb8x	SLICER MACHINE (MLK, MAWA)	Fixed Assets	\N	\N	-170000.00	\N
309a1994-9636-4597-8597-6181620f1f4e	cmofmpqxp0000tms4st6fcb8x	Slizer Machine	Fixed Assets	\N	\N	0.00	\N
e48e04b8-eda8-4cfa-add6-b4c46024c93f	cmofmpqxp0000tms4st6fcb8x	S.N. Enterprises, COMPUTER	Sundry Creditors -Exp	\N	\N	0.00	\N
be72cbe5-6532-4767-8e0d-d68900700740	cmofmpqxp0000tms4st6fcb8x	S.N.Services, BLUE STAR SERVICE CENTER	Sundry Creditors -Exp	\N	\N	0.00	\N
bf93686d-462d-4c3d-a844-4ff62d2fa865	cmofmpqxp0000tms4st6fcb8x	SOHAN BAJAJ	BAJAJ JI	\N	\N	0.00	\N
c2f2b6ed-fa92-420f-8757-90de7f70ad53	cmofmpqxp0000tms4st6fcb8x	SOHAN BAJPAI	BAJAJ JI	\N	\N	0.00	\N
5096c37e-5936-4f4e-acb0-d144e57c3d6b	cmofmpqxp0000tms4st6fcb8x	SOHAN SAHU	ANANTRAM JI	\N	\N	0.00	\N
7d87bc6e-8a68-4672-97c2-8c516b65b9dc	cmofmpqxp0000tms4st6fcb8x	SOHIT ( FREIGHT )	Freight & Cartage O/W	\N	\N	0.00	\N
d51eec2b-3d13-4759-af3b-f1ca3ef2bc15	cmofmpqxp0000tms4st6fcb8x	SOHIT KUMAR	ANANTRAM JI	\N	\N	0.00	\N
2268dadb-e0a0-4cb3-a7bd-dffde6834dd4	cmofmpqxp0000tms4st6fcb8x	SOHIT SAHU	ANANTRAM JI	\N	\N	0.00	\N
075c5acd-7e91-4bbf-87da-864fe8a1ce00	cmofmpqxp0000tms4st6fcb8x	SOMA	Staff & Worker ( SALARY )	\N	\N	0.00	\N
7b1a4566-15ca-4dc3-85ac-487fa0642dfc	cmofmpqxp0000tms4st6fcb8x	SOMA S..	Sundry Debtors	\N	\N	0.00	\N
2fe47913-3e3a-44bc-8790-a04fece68a21	cmofmpqxp0000tms4st6fcb8x	SONAM TECHNOLOGIES	Sundry Creditors	\N	\N	5500.00	\N
732ce515-cb2a-4f94-a3ca-8c66574562e2	cmofmpqxp0000tms4st6fcb8x	SONA TRADERS, BADAUN	Gaurav, LUCKNOW	\N	\N	0.00	\N
77d10d63-db0f-4740-abfb-684c75822871	cmofmpqxp0000tms4st6fcb8x	Soni Sales Corporation	Sundry Creditors	\N	\N	0.00	\N
c1939726-d7db-4000-9ad8-eb4de583cfe1	cmofmpqxp0000tms4st6fcb8x	Soni Sweaper	Staff & Worker ( SALARY )	\N	\N	0.00	\N
90406b70-d180-4913-bc56-2181ea505959	cmofmpqxp0000tms4st6fcb8x	SONU BAJAJ	BAJAJ JI	\N	\N	0.00	\N
6d0b8c87-a6b2-4118-9d27-700876a9a0cc	cmofmpqxp0000tms4st6fcb8x	SONU BAJPAI	BAJAJ JI NEW	\N	\N	140000.00	\N
1ecac948-4467-47fa-b0fc-987c4afbfaa9	cmofmpqxp0000tms4st6fcb8x	SONU SAHU	ANANTRAM JI	\N	\N	0.00	\N
7dd1abd9-8b0b-4bf4-8b69-eb948db1dadf	cmofmpqxp0000tms4st6fcb8x	SOSHA	Sundry Creditors	\N	\N	0.00	\N
1ab15891-a328-472c-85ef-1fb522d44047	cmofmpqxp0000tms4st6fcb8x	South Mart	VIJAY BATHAM	\N	\N	0.00	\N
aff90367-18c3-4583-add9-6031acd95d0d	cmofmpqxp0000tms4st6fcb8x	SPIRAL MIXTURE	Fixed Assets	\N	\N	-152542.37	\N
38a4ef64-ec48-4768-97f6-a6226855dd74	cmofmpqxp0000tms4st6fcb8x	SPIRAL MIXTURE ( CHITRA THEKEDAR )	Fixed Assets	\N	\N	-100000.00	\N
09067673-085d-44b6-b39b-a0b1494269c2	cmofmpqxp0000tms4st6fcb8x	S R Bakery Machines	Sundry Creditors -Exp	\N	\N	0.00	\N
269b6a2e-ee9a-4dbc-8da0-f829eb2a3b3c	cmofmpqxp0000tms4st6fcb8x	SRI SAI TRADERS, MIRZAPUR	Ashutosh Ji	\N	\N	0.00	\N
03afd7a5-2af0-4734-b6ad-d0fa4e7eb32e	cmofmpqxp0000tms4st6fcb8x	S. S. D. Marketing REWA	Ashutosh Ji	\N	\N	0.00	\N
3e433d4a-982e-419b-8365-f28c4cf37d4d	cmofmpqxp0000tms4st6fcb8x	S S ENTERPRISE	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
98a797ac-ae32-48f1-9978-b56ab24dc32e	cmofmpqxp0000tms4st6fcb8x	S S ENTERPRISES, KANPUR	Sundry Creditors -Exp	\N	\N	0.00	\N
ac2b485f-8912-44a8-97ae-a73f73f80a12	cmofmpqxp0000tms4st6fcb8x	S.S.N.J. Food Private Limited	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
a19e3f07-79cd-43a0-8a41-d940fdbe5b5a	cmofmpqxp0000tms4st6fcb8x	SS WATER TANK 1500LTR (RO)	Fixed Assets	\N	\N	-25200.00	\N
c2d2357c-53cb-444f-b69c-1c056db366c3	cmofmpqxp0000tms4st6fcb8x	STABLIZER (SERVO)	Fixed Assets	\N	\N	-200000.00	\N
830b7d57-efa1-4ca8-b729-363cf9ec721a	cmofmpqxp0000tms4st6fcb8x	STAFF WELFARE EXP	Staff & Welfare	\N	\N	0.00	\N
772afad3-3e81-4b14-a5d6-3cf48dc2db04	cmofmpqxp0000tms4st6fcb8x	STAFF WELFARE EXP@12%	Staff & Welfare	\N	\N	0.00	\N
2c57c116-8aca-4be6-95a8-0522665aefc7	cmofmpqxp0000tms4st6fcb8x	STAFF WELFARE EXP @18%	Staff & Welfare	\N	\N	0.00	\N
9b224a34-6a7e-439a-b428-8734ef8c8a32	cmofmpqxp0000tms4st6fcb8x	STAFF WELFARE EXP@5%	Staff & Welfare	\N	\N	0.00	\N
d4bc112e-22ff-48b0-95b8-75e841c63ad9	cmofmpqxp0000tms4st6fcb8x	STANLEY GRINDER 850W	Fixed Assets	\N	\N	-1912.50	\N
f1f8fd5b-5bee-4d60-aa64-0971c702ad1e	cmofmpqxp0000tms4st6fcb8x	STAR ENTERPRISES, BIJNOR	Sundry Debtors	\N	\N	0.00	\N
c0337490-c1db-4b3c-8faf-d596b0fd5d6b	cmofmpqxp0000tms4st6fcb8x	Stock in Hand	Purchase Accounts	\N	\N	0.00	\N
3fc1b648-87d1-41a0-9004-79c73c1bdd11	cmofmpqxp0000tms4st6fcb8x	Subh Traders, LUCKNOW	Ashutosh Ji	\N	\N	-2344.00	\N
6d86a58b-da30-4bb8-9e6a-0b7242191da4	cmofmpqxp0000tms4st6fcb8x	SUBMERSEBIL OIL BASE 18%	Fixed Assets	\N	\N	-8439.75	\N
b7ebe346-9963-470b-b495-aa3ffc0f3b29	cmofmpqxp0000tms4st6fcb8x	SUDHEER SAHU	ANANTRAM JI	\N	\N	0.00	\N
a40f0a37-64ef-4224-9bde-6203e274719f	cmofmpqxp0000tms4st6fcb8x	SUMAN PAL - ALLAHABAD	ALLAHABAD	\N	\N	0.00	\N
900e0693-8dad-4137-b1da-f921ad18f019	cmofmpqxp0000tms4st6fcb8x	SUNDER SALES	Sundry Debtors	\N	\N	0.00	\N
e5b573ae-fa46-41d7-b6be-7c9090661875	cmofmpqxp0000tms4st6fcb8x	SUNEEL SAHU	ANANTRAM JI	\N	\N	0.00	\N
ac416ca6-9756-48ed-90b1-d4a33286c650	cmofmpqxp0000tms4st6fcb8x	SUNIL BAJAJ	BAJAJ JI	\N	\N	0.00	\N
ee7132df-a27f-40a1-af8a-51ac3090cc92	cmofmpqxp0000tms4st6fcb8x	Sunil Bajpai	BAJAJ JI	\N	\N	0.00	\N
327aca7b-b038-43bf-8913-9221f81adff5	cmofmpqxp0000tms4st6fcb8x	Sunilkumar Sudhirkumar	CREDITORS ( DIPESH JI )	\N	\N	515351.00	\N
a17386e3-40fa-4212-a5fa-46ce274b857b	cmofmpqxp0000tms4st6fcb8x	Suraj Bajaj	BAJAJ JI	\N	\N	0.00	\N
38786df2-76df-4eca-970b-13811f46f97b	cmofmpqxp0000tms4st6fcb8x	Suraj Enterprises, SALON	Ashutosh Ji	\N	\N	288.00	\N
a74698cf-18a7-4990-9ce2-5be6d982a0e8	cmofmpqxp0000tms4st6fcb8x	Suraj Sahu	ANANTRAM JI	\N	\N	0.00	\N
493cd01a-22af-4f48-a1d0-22c8b0a43677	cmofmpqxp0000tms4st6fcb8x	Suraj Sweaper	Staff & Worker ( SALARY )	\N	\N	0.00	\N
823d48db-52cb-404f-a0b9-6334312c205e	cmofmpqxp0000tms4st6fcb8x	Suresh Bajaj	BAJAJ JI	\N	\N	0.00	\N
f8cece57-0275-4b1d-a794-0e48d58f93c2	cmofmpqxp0000tms4st6fcb8x	Suresh Banwari Ji	Sundry Debtors	\N	\N	0.00	\N
95ca9682-448a-4613-a7b6-61acbc99d3ed	cmofmpqxp0000tms4st6fcb8x	SURESH CHANDRA-JALAUN	Ashutosh Ji	\N	\N	0.00	\N
a04135e2-654a-48ce-bab7-f07ef76624c9	cmofmpqxp0000tms4st6fcb8x	SURESH GUPTA &amp; SONS	Sundry Creditors	\N	\N	0.00	\N
ebb81224-e80f-4ac4-8bb0-68abaaa182c8	cmofmpqxp0000tms4st6fcb8x	Suresh Ji	BAJAJ JI	\N	\N	0.00	\N
163b78fd-18f2-4dfe-b202-6d2367fe2a65	cmofmpqxp0000tms4st6fcb8x	SURESH SAHU	ANANTRAM JI	\N	\N	0.00	\N
4ec1b258-c658-4a90-80e8-f580f63bb57d	cmofmpqxp0000tms4st6fcb8x	SURESH TRADING CO	Sundry Creditors	\N	\N	0.00	\N
23ec3f3c-d1fd-48ec-b2ec-c9d5cea033fb	cmofmpqxp0000tms4st6fcb8x	SURYA KUMAR ( TROLLY MAKER )	Sundry Creditors -Exp	\N	\N	0.00	\N
d7bf5552-82f2-417a-9587-29e905be8ccc	cmofmpqxp0000tms4st6fcb8x	Surya Trading Company	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
4400cceb-b7eb-470d-a868-85a4f141c411	cmofmpqxp0000tms4st6fcb8x	SUSHEEL KUMAR GUPTA, BANGARMAU ( NEW )	Ashutosh Ji	\N	\N	-40036.00	\N
bff32df3-9df7-46e6-8681-7c2fca082249	cmofmpqxp0000tms4st6fcb8x	Sushma Elaichi	Indirect Expenses	\N	\N	0.00	\N
0cef83bf-bb3f-49ee-9b60-71bd51ebaf41	cmofmpqxp0000tms4st6fcb8x	SUSPENCE A/C	Suspense A/c	\N	\N	33804.00	\N
58598452-ca7c-4918-94cb-4870ecd6b6f7	cmofmpqxp0000tms4st6fcb8x	SWAGTAM TRADE, UNNAO	MOTWANI UNNAO	\N	\N	0.00	\N
07539fab-961a-4244-950a-669652cef144	cmofmpqxp0000tms4st6fcb8x	SWASTIK ENTERPRISES	Sundry Creditors	\N	\N	0.00	\N
28500f0c-6f5f-422a-ba2e-f79f41f0be71	cmofmpqxp0000tms4st6fcb8x	SWEET STORE , CIVIL LINES	AMAR SONKAR	\N	\N	-660.00	\N
4b098ae0-0274-453a-9e43-75884a8a2936	cmofmpqxp0000tms4st6fcb8x	SYMPHONY WIND BLAST 95L	Fixed Assets	\N	\N	-10000.03	\N
17b1517f-750b-4895-944d-5d44c62c87c9	cmofmpqxp0000tms4st6fcb8x	System &amp; Technology ( Creditor )	Sundry Creditors	\N	\N	0.00	\N
3111c4e7-f81a-466d-a0b2-6a410bd21a1c	cmofmpqxp0000tms4st6fcb8x	TALLY  AMC	Indirect Expenses	\N	\N	0.00	\N
c1213776-8ddc-4003-b3cb-6e39c3f89faa	cmofmpqxp0000tms4st6fcb8x	TANK 5000 LTR	Fixed Assets	\N	\N	-20763.00	\N
c9fe1423-0f07-47d7-9f89-d2b22fd4410c	cmofmpqxp0000tms4st6fcb8x	TANKI (CYLINDER)	Fixed Assets	\N	\N	-5346.50	\N
b7d800f7-943d-42d7-ae74-6690028fc653	cmofmpqxp0000tms4st6fcb8x	TAPAN	Sundry Debtors	\N	\N	0.00	\N
8cbb60ed-b1ab-4816-ab25-689c50e5ee2c	cmofmpqxp0000tms4st6fcb8x	TAPAN BAJAJ	BAJAJ JI	\N	\N	0.00	\N
adb91c0d-8419-4d7e-912a-43337ac0fe5a	cmofmpqxp0000tms4st6fcb8x	Tapan Staff	Staff & Worker ( SALARY )	\N	\N	0.00	\N
8288dce6-3d10-4389-bd91-49e963ac0119	cmofmpqxp0000tms4st6fcb8x	TATA AIG GIC LTD	Sundry Creditors -Exp	\N	\N	0.00	\N
38815d3c-b645-4b73-bf12-c25082c7c2cc	cmofmpqxp0000tms4st6fcb8x	Tax Payable on RCM	Provisions	\N	\N	0.00	\N
fbc71ff5-92f8-47cb-8f68-525b27a3afde	cmofmpqxp0000tms4st6fcb8x	TCS	Loans & Advances (Asset)	\N	\N	-11109.00	\N
c1981c53-d1ce-463c-b518-fad015609278	cmofmpqxp0000tms4st6fcb8x	TCS on Sale	Duties & Taxes	\N	\N	0.00	\N
50442b3b-1929-4333-b5dc-9a78ac6f2c70	cmofmpqxp0000tms4st6fcb8x	TDS (194C)	Duties & Taxes	\N	\N	20930.00	\N
6fef94d3-d8b0-4ccd-91a3-21128606e0c3	cmofmpqxp0000tms4st6fcb8x	TDS 194H	Duties & Taxes	\N	\N	0.00	\N
749c47ab-c4bf-4802-a140-f23163b4d0e7	cmofmpqxp0000tms4st6fcb8x	TDS (194I)	Duties & Taxes	\N	\N	0.00	\N
8d558959-9281-4a3d-8abb-b25236509ee2	cmofmpqxp0000tms4st6fcb8x	TDS (194J)	Duties & Taxes	\N	\N	7650.00	\N
40c21d5f-2a99-43b5-b9af-b4fe6d842b17	cmofmpqxp0000tms4st6fcb8x	TDS (194Q)	Duties & Taxes	\N	\N	18994.00	\N
7c6b55b3-180f-421f-bbea-da2bada27a2d	cmofmpqxp0000tms4st6fcb8x	Tejamal General Store ( Creditor )	CREDITORS ( DIPESH JI )	\N	\N	81867.60	\N
6d690e35-d358-4b8d-a04e-e0d631e62e50	cmofmpqxp0000tms4st6fcb8x	TESTING 18%	Indirect Expenses	\N	\N	0.00	\N
52ae0a1f-2152-4b93-8c7a-c19a30dd34de	cmofmpqxp0000tms4st6fcb8x	T.L.ENTERPRISES, KHEERO	RAIBERELY	\N	\N	0.00	\N
2b62449d-f32a-408d-bcc0-17d476818d28	cmofmpqxp0000tms4st6fcb8x	TOUR &amp; TRAVELLING EXP	Indirect Expenses	\N	\N	0.00	\N
4813733a-9308-45e5-8806-ba38c3531111	cmofmpqxp0000tms4st6fcb8x	TPS SUGAR SUPPLIERS-(2020-21)	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
0a55c3e0-6ff4-48b7-8f1f-3f65aa26b323	cmofmpqxp0000tms4st6fcb8x	TRAYS &amp; MOLD	Fixed Assets	\N	\N	-1201570.30	\N
7e627de1-b5a8-4cb2-9a10-2c74f4b373e2	cmofmpqxp0000tms4st6fcb8x	Trays &amp; Moulds	Fixed Assets	\N	\N	-192909.46	\N
f4f22a0c-ad43-4103-8674-4552c7822e88	cmofmpqxp0000tms4st6fcb8x	TROLLY	Fixed Assets	\N	\N	-65169.49	\N
7f8e662b-4d00-4580-adf7-4dd46621d0f0	cmofmpqxp0000tms4st6fcb8x	Trolly 18%	Fixed Assets	\N	\N	-166238.09	\N
b51ad0c1-d5b2-488b-8f0c-0488a1625706	cmofmpqxp0000tms4st6fcb8x	TRUPATI TRADERS	BAJAJ JI	\N	\N	0.00	\N
2a4d46d2-bde5-4382-b161-52c9af748fdd	cmofmpqxp0000tms4st6fcb8x	T-SHIRT	Indirect Expenses	\N	\N	0.00	\N
d8b71b08-0439-43c7-baad-5b1da5ed9429	cmofmpqxp0000tms4st6fcb8x	TUSHAR CHHABRA, DATIA	DATIA	\N	\N	0.00	\N
186a4a1a-6419-4063-be29-98f4a71618c2	cmofmpqxp0000tms4st6fcb8x	UDIT CONFECTIONERY	BAJAJ JI	\N	\N	0.00	\N
4f8065b3-c2ac-4c1a-88e1-36f70219a515	cmofmpqxp0000tms4st6fcb8x	UJJWAL SAHU	ANANTRAM JI	\N	\N	0.00	\N
d74ef2db-c523-4502-9a40-2784821b9103	cmofmpqxp0000tms4st6fcb8x	UMA CANOPY	Sundry Debtors	\N	\N	0.00	\N
3fed044a-4a10-41c0-af95-a0bc3cd94030	cmofmpqxp0000tms4st6fcb8x	UMA PACKIMG	Staff & Worker ( SALARY )	\N	\N	0.00	\N
b065ddd2-e65d-4cc6-be53-f4f58a9f5403	cmofmpqxp0000tms4st6fcb8x	Uma Sweaper	Staff & Worker ( SALARY )	\N	\N	0.00	\N
b91c527c-01e1-43c1-a786-2760e1e3b3de	cmofmpqxp0000tms4st6fcb8x	Unnao Roller Flour Mill (P) Ltd.	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
527bdca3-e135-4cee-8594-ae24b2bd3388	cmofmpqxp0000tms4st6fcb8x	U.P.S.I.D.A.	Loans & Advances (Asset)	\N	\N	0.00	\N
ed45b2bb-c36b-4ba1-b2de-3aeac49a4746	cmofmpqxp0000tms4st6fcb8x	Usha Packing Staff	Staff & Worker ( SALARY )	\N	\N	0.00	\N
8dda33ba-8a2e-4668-8d19-bfb4762d34cf	cmofmpqxp0000tms4st6fcb8x	Utkarsh Bajaj	BAJAJ JI	\N	\N	0.00	\N
52307157-412a-411e-9362-05bed43ae17c	cmofmpqxp0000tms4st6fcb8x	UTKARSH BAJPAI	BAJAJ JI	\N	\N	0.00	\N
c5ef35f8-8904-4c29-a81e-4db88b98b220	cmofmpqxp0000tms4st6fcb8x	UTKARSH GUPTA - JALAUN	Ashutosh Ji	\N	\N	0.00	\N
3ca60aad-0f1a-40db-823d-1a6b781410c2	cmofmpqxp0000tms4st6fcb8x	UVR COMMERCIAL PVT LTD	CREDITORS ( DIPESH JI )	\N	\N	29148.00	\N
be764d37-e9e7-4914-a24e-af2375de77a3	cmofmpqxp0000tms4st6fcb8x	Vaani JI	Sundry Creditors	\N	\N	404700.00	\N
91bb336d-98bf-4220-bd09-20c96e7b9ee7	cmofmpqxp0000tms4st6fcb8x	VAISHNAVI NAMKEEN, Lucknow Phatak	AMAR SONKAR	\N	\N	-2480.00	\N
f09353a9-5018-4e9d-a3d0-a14607865372	cmofmpqxp0000tms4st6fcb8x	Vaishnavi Traders	ANANTRAM JI	\N	\N	0.00	\N
d56c0b17-55e5-4584-8be0-56a13061593f	cmofmpqxp0000tms4st6fcb8x	Vam Advertising &amp; Marketing Pvt Ltd. ( Creditor )	Sundry Creditors -Exp	\N	\N	0.00	\N
6cc46948-7880-4966-883d-ba8645b7cc6f	cmofmpqxp0000tms4st6fcb8x	Vansal Air Cooler Rhino Blast 1400RPM	Fixed Assets	\N	\N	-10932.23	\N
7b332b5d-4e79-4a93-8674-a969b5df8958	cmofmpqxp0000tms4st6fcb8x	VANSH BAJAJ	BAJAJ JI	\N	\N	0.00	\N
46d0fab3-97ec-43a4-a588-2a30c2800f81	cmofmpqxp0000tms4st6fcb8x	VASTRA COLLECTION-NANPARA	OUT OF KANPUR	\N	\N	0.00	\N
04ef713b-1a51-4c91-a3e0-45cc0804d4e4	cmofmpqxp0000tms4st6fcb8x	Vedant Enterprises	Sundry Creditors	\N	\N	0.00	\N
8ee992af-f100-4a9a-a9d2-aad77f1e07dc	cmofmpqxp0000tms4st6fcb8x	Ved Trading  Barasingha Maida Mill	CREDITORS ( DIPESH JI )	\N	\N	770848.00	\N
a421786f-0e67-4e29-83dd-7e65684fe61b	cmofmpqxp0000tms4st6fcb8x	Veeresh Ohri, Punjab	Sundry Debtors	\N	\N	0.00	\N
2b8ebc33-a155-48a8-a3fa-bac3126ffe4d	cmofmpqxp0000tms4st6fcb8x	VENUS WHEELS INTERNATION	Sundry Creditors	\N	\N	0.00	\N
494be723-c63c-4bfa-bb19-6a339d104bfb	cmofmpqxp0000tms4st6fcb8x	Vibha Gupta &amp; Associates	Sundry Creditors -Exp	\N	\N	-15000.00	\N
32d9c5a3-909a-4a94-8db7-ec5fcc23f50f	cmofmpqxp0000tms4st6fcb8x	VIC INDUSTRIES	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
f42be1d9-b73e-46e2-846c-a8e24500003f	cmofmpqxp0000tms4st6fcb8x	VICKY METEL &amp; STEEL	Sundry Creditors -Exp	\N	\N	0.00	\N
f681d2f6-9ee4-4e51-9256-e3f04b787be9	cmofmpqxp0000tms4st6fcb8x	VIJAY BAJAJ	BAJAJ JI	\N	\N	0.00	\N
ba816818-ce5d-44e9-ac05-a92344fd0d16	cmofmpqxp0000tms4st6fcb8x	VIJAY BAJPAI	BAJAJ JI	\N	\N	0.00	\N
34834352-252a-4899-b1de-b99d857c3402	cmofmpqxp0000tms4st6fcb8x	Vijay Batham (Devki Nagar)	VIJAY BATHAM	\N	\N	0.00	\N
4f148e40-b1d9-408f-b087-a29ce9742ed9	cmofmpqxp0000tms4st6fcb8x	VIJAY GUPTA, BALAJI	BALAJI TRADER( YASHODA NAGAR )	\N	\N	0.00	\N
5894f2fa-305c-4b30-ab54-3d8eebb0ad5a	cmofmpqxp0000tms4st6fcb8x	VIJAY JI	BAJAJ JI	\N	\N	0.00	\N
bd17c680-b7c8-4dc3-9630-a8ad345eecd7	cmofmpqxp0000tms4st6fcb8x	VIJAY SAHU	ANANTRAM JI	\N	\N	0.00	\N
15b768c5-4514-4c6d-bf14-346fac29ef86	cmofmpqxp0000tms4st6fcb8x	VIJAY TRADERS, LUCKNOW	Sundry Debtors	\N	\N	-11208.00	\N
29feb738-3fde-4235-b6f0-480d3494499b	cmofmpqxp0000tms4st6fcb8x	VIKAS HARDWARE AND MILL STORE	Sundry Creditors	\N	\N	0.00	\N
2e19607f-b2f0-4af2-a209-9913dc70bfef	cmofmpqxp0000tms4st6fcb8x	VIKAS SWEAPER	Staff & Worker ( SALARY )	\N	\N	0.00	\N
ea108e38-5e98-4819-8f2f-462f4ad27e13	cmofmpqxp0000tms4st6fcb8x	VIMAL BAJAJ	BAJAJ JI	\N	\N	0.00	\N
6c27bf01-4d8c-4b72-aefb-a3e4670de596	cmofmpqxp0000tms4st6fcb8x	VIMAL SAHU	ANANTRAM JI	\N	\N	0.00	\N
25b40327-af5b-4b11-a9ef-efba07120145	cmofmpqxp0000tms4st6fcb8x	VIMLESH BAJAJ	BAJAJ JI	\N	\N	0.00	\N
e1b207d6-6c8f-4157-8384-c3889c64737f	cmofmpqxp0000tms4st6fcb8x	Vimlesh Bajpai	BAJAJ JI	\N	\N	0.00	\N
612cfffc-770d-4c72-a8f9-660b7144da57	cmofmpqxp0000tms4st6fcb8x	VIMLESH SAHU	ANANTRAM JI	\N	\N	0.00	\N
359a916e-ed71-48d7-8b18-c1d47aafaf61	cmofmpqxp0000tms4st6fcb8x	VIMLESH SHARMA  ( TOUR )	Sundry Creditors(Tour)	\N	\N	0.00	\N
5d14aab4-30d7-4db1-b3e8-2ee973724359	cmofmpqxp0000tms4st6fcb8x	VINAY BAJPAI	BAJAJ JI NEW	\N	\N	0.00	\N
90989ea4-0a2b-481e-a20c-60d879f1443e	cmofmpqxp0000tms4st6fcb8x	VINAY SAHU, NAYA GANJ	AMAR SONKAR	\N	\N	0.00	\N
6fbcb158-8cc5-4da0-98d8-8fd5c8a80c6e	cmofmpqxp0000tms4st6fcb8x	VIRENDRA BAJPAI	BAJAJ JI	\N	\N	0.00	\N
758f1977-bd0e-4ac4-b2a4-6c4dd53a5957	cmofmpqxp0000tms4st6fcb8x	VIVEK GUPTA-GHATAMPUR	Ashutosh Ji	\N	\N	0.00	\N
0e9392df-5aeb-488e-bab4-0dc8f655c412	cmofmpqxp0000tms4st6fcb8x	VIVEK MARBLE &amp; GRANITEM STORE	Sundry Creditors -Exp	\N	\N	6500.00	\N
ceeea9e9-92c7-4335-875b-d2f062a70b53	cmofmpqxp0000tms4st6fcb8x	VK BROTHERS	CREDITORS ( DIPESH JI )	\N	\N	0.00	\N
0b34351e-a384-4051-8a66-12b1ace016e7	cmofmpqxp0000tms4st6fcb8x	VOHRA RUBBER &amp; ELECTICALS	Sundry Creditors	\N	\N	0.00	\N
e042ad5f-7410-43f3-a915-ea793d17f602	cmofmpqxp0000tms4st6fcb8x	Wages A/c (Production)	Direct Expenses	\N	\N	0.00	\N
efd1013f-821e-41ac-9cf9-97cb24c1ad30	cmofmpqxp0000tms4st6fcb8x	Wall Fan @ 18%	FAN	\N	\N	-34682.89	\N
a5bd5d68-e28d-4093-aeff-ef85198f4787	cmofmpqxp0000tms4st6fcb8x	Warsi &amp; Sons	BAJAJ JI	\N	\N	0.00	\N
f8fc4681-713b-497a-a48f-dfbc7021b386	cmofmpqxp0000tms4st6fcb8x	Water Purifier	Fixed Assets	\N	\N	-487.59	\N
a5bdaea1-674a-499e-94d2-f8b386a801ab	cmofmpqxp0000tms4st6fcb8x	WEB DEVELOPMENT 18%	Indirect Expenses	\N	\N	0.00	\N
71fc9e50-af52-4f41-8705-64e6e59ac2ba	cmofmpqxp0000tms4st6fcb8x	Weighing Machine	Fixed Assets	\N	\N	-14656.63	\N
cd5ac8cc-2c10-40a5-9947-4cda4e5b24ab	cmofmpqxp0000tms4st6fcb8x	Weight Machine 10kg	Fixed Assets	\N	\N	-4080.00	\N
e03c9aa0-4fe6-4aac-a7ef-f500fc5f0ef3	cmofmpqxp0000tms4st6fcb8x	WEIGHT MACHINE 5KG	Fixed Assets	\N	\N	-1850.00	\N
007a0d93-4819-40a3-9f18-00bd03fadeca	cmofmpqxp0000tms4st6fcb8x	Welding Machine	Fixed Assets	\N	\N	-1503.52	\N
173594ae-61ca-46d3-9b1e-8a2babb10dc2	cmofmpqxp0000tms4st6fcb8x	WHITEOAK CAPITAL MID CAP FUND ( 1000799021 ) 3/1/25	SIP	\N	\N	0.00	\N
dd9ce600-f838-46b4-8de4-6cc2edf25bff	cmofmpqxp0000tms4st6fcb8x	Wow Accessory World, DELHI	Sundry Creditors -Exp	\N	\N	0.00	\N
8d261d41-34e1-4cf6-b321-058dc1449bfe	cmofmpqxp0000tms4st6fcb8x	X	ANANTRAM JI	\N	\N	0.00	\N
bc99f11c-296e-4b65-bcfa-d6fad3d08720	cmofmpqxp0000tms4st6fcb8x	XXXX SHRI RAM ENTERPRISES-MIRZAPUR	Sundry Debtors	\N	\N	2053.00	\N
d96d4c42-dc92-4e3a-888b-a9225d003d96	cmofmpqxp0000tms4st6fcb8x	YASH BHAIYA (GEELI CUTTING)	SCRAP ( DEBTORS )	\N	\N	-686.00	\N
da5a1b88-9542-484d-a4d1-8879248ba21e	cmofmpqxp0000tms4st6fcb8x	YONO ( S.B.I.)	Bank Accounts	\N	\N	95178.44	\N
c9816e40-c3d2-4040-941b-f3d4cfb39dd7	cmofmpqxp0000tms4st6fcb8x	Zahir	Sipahi	\N	\N	-300000.00	\N
a0e268db-cb55-445a-b0bf-4a76702f4a66	cmofmpqxp0000tms4st6fcb8x	ZAKIR HUSAIN	WAGES ( CONTRACTOR )	\N	\N	0.00	\N
\.


--
-- Data for Name: LineItem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LineItem" (id, "billId", description, "hsnCode", quantity, unit, "unitPrice", "discountPercent", "gstRate", amount, "tallyLedger", "tallyStockItem") FROM stdin;
cmoflfmi3000umjdm3r7th9nr	b_1777197318515	HSD Bar (TMT) (8MM-550)	72142090	2990	KG	51.78	0	18	154822.2	\N	HSD BAR (TMT)
cmoflfmi3000vmjdmxr3spvcd	b_1777197318515	HSD Bar (TMT) (10-12 MM-550)	72142090	7010	KG	50.08	0	18	351060.8	\N	HSD BAR (TMT)
cmoflfmi3000wmjdme88xjf91	b_1777197318515	HSD Bar (TMT) (10-12 MM-550)	72142090	2070	KG	49.41	0	18	102278.7	\N	HSD BAR (TMT)
li_1777197585382_0	b_1777197585382	HSD Bar (TMT) (8MM-550)		1	Nos	154822.2	\N	0	154822.2	\N	\N
li_1777197585382_1	b_1777197585382	HSD Bar (TMT) (10-12 MM-550)		1	Nos	351060.8	\N	0	351060.8	\N	\N
li_1777197585382_2	b_1777197585382	HSD Bar (TMT) (10-12 MM-550)		1	Nos	102278.7	\N	0	102278.7	\N	\N
cmoflqrc70016mjdm7igvo51g	b_1777197881172	HSD Bar (TMT) (8MM-550)	72142090	2990	KG	51.78	0	18	154822.2	\N	HSD BAR (TMT)
cmoflqrc80017mjdm2dytlo4v	b_1777197881172	HSD Bar (TMT) (10-12 MM-550)	72142090	7010	KG	50.08	0	18	351060.8	\N	HSD BAR (TMT)
cmoflqrc80018mjdmyyplai1o	b_1777197881172	HSD Bar (TMT) (10-12 MM-550)	72142090	2070	KG	49.41	0	18	102278.7	\N	HSD BAR (TMT)
cmofn22f4000stms4s6rmirr7	b_1777199938773	Publication/Edition - Amarujala- Kanpur, Date: 27/Mar/2026, Size: 10x8 sq.cm, Rate: 75.00		1	Nos	6000	0	0	6000	ADVERTISEMENT EXP @5%	\N
li_1777200253059_0	b_1777200253059	Publication/Edition - Amarujala - Kanpur, Date: 27/Mar/2026, Size: 10x8 sq.cm, Rate: 75.00		1	Nos	6000	\N	0	6000	\N	\N
cmofo2m9g0004pmll70xq64za	b_1777201686406	Publication/Edition - Amarujala- Kanpur, Date: 27/Mar/2026, Size: 10x8 sq.cm, Rate: 75.00		1	Nos	6000	0	0	6000	ADVERTISEMENT EXP @5%	\N
cmofo9d580007pmllb2k0f5dh	b_1777202033396	Carton 400x280x255 (Sd Khari)	48191010	740	pcs	13.25	0	5	9805	\N	CORRUGATED BOX B RUSK PRINTED
cmofo9d580008pmll7hy00gsc	b_1777202033396	CARTON-445X227X280-SD COOKIES	48191010	2200	pcs	12	0	5	26400	\N	CORRUGATED BOX CUSTOM
cmofog4pq000epmll5a910gqq	b_1777201972911	Publication/Edition - Amarujala - Kanpur, Date: 27/Mar/2026, Size: 10x8 sq.cm, Rate: 75.00		1	Nos	6000	0	0	6000	ADVERTISEMENT EXP @5%	\N
cmofp2zrh0001gze5xhds1zjy	b_1777203448596	Publication/Edition - Amarujala- Kanpur, Date: 27/Mar/2026, Size: 10x8 sq.cm, Rate: 75.00		1	Nos	6000	0	0	6000	ADVERTISEMENT EXP @5%	\N
li_1777203608459_0	b_1777203608459	DTI FEK 72x72	9032	1	Pc	1000	\N	18	1000	\N	\N
\.


--
-- Data for Name: StockGroupCache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockGroupCache" (id, "companyId", name, parent) FROM stdin;
cmofl4zfi000omjdmt21d9xq8	cmofl3ut6000hmjdmwqd3dziu	Sariya	&#4; Primary
cmofmtx6o0007tms4gyz3gl4l	cmofmpqxp0000tms4st6fcb8x	Damage Goods	&#4; Primary
cmofmtx6s0009tms4mtfozqyu	cmofmpqxp0000tms4st6fcb8x	Finished Goods	&#4; Primary
cmofmtx6u000btms4pepk52nv	cmofmpqxp0000tms4st6fcb8x	PACKAGING 12%	PKG
cmofmtx6w000dtms4o1av5gwf	cmofmpqxp0000tms4st6fcb8x	PACKAGING 18%	PKG
cmofmtx6y000ftms43eg6pr4p	cmofmpqxp0000tms4st6fcb8x	PKG	&#4; Primary
cmofmtx70000htms48rttectc	cmofmpqxp0000tms4st6fcb8x	RAW MATERIAL	&#4; Primary
cmofmtx72000jtms4vhb4hhtp	cmofmpqxp0000tms4st6fcb8x	SCRAP	&#4; Primary
\.


--
-- Data for Name: StockItemAlias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockItemAlias" (id, "companyId", "stockItemCacheId", "billItemName") FROM stdin;
cmoflfmlb000ymjdmh6n53nkv	cmofl3ut6000hmjdmwqd3dziu	fed411ff-5a73-4f02-a226-ffe10119c24d	hsd bar (tmt) (8mm-550)
cmoflfmm90010mjdmjcl1itdw	cmofl3ut6000hmjdmwqd3dziu	fed411ff-5a73-4f02-a226-ffe10119c24d	hsd bar (tmt) (10-12 mm-550)
cmofo9d7p000apmllbmq2sz01	cmofmpqxp0000tms4st6fcb8x	647af5bf-40f0-4948-92c0-15101be2b183	carton 400x280x255 (sd khari)
cmofo9d8e000cpmllc07c3ofq	cmofmpqxp0000tms4st6fcb8x	0602dc0f-4be7-46b3-a104-795a9b0077f5	carton-445x227x280-sd cookies
\.


--
-- Data for Name: StockItemCache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockItemCache" (id, "companyId", name, "group", unit) FROM stdin;
70e98b83-d9ac-478b-9198-62a7d8a17dc9	cmofl3ut6000hmjdmwqd3dziu	AANKUR TMX BAR-72142090	&#4; Primary	M.T.
2bdc7392-c44b-4032-b828-a56642e4fc5d	cmofl3ut6000hmjdmwqd3dziu	Binding Wire-72171010	&#4; Primary	M.T.
7151cf2a-2e6b-46c9-a141-1ed3892d9fde	cmofl3ut6000hmjdmwqd3dziu	CEMENT---252390	&#4; Primary	BAG
fed411ff-5a73-4f02-a226-ffe10119c24d	cmofl3ut6000hmjdmwqd3dziu	HSD BAR (TMT)	&#4; Primary	M.T.
1447e6e7-fc45-4bd0-873a-294ca926dfcf	cmofl3ut6000hmjdmwqd3dziu	IRON BAR -72142090	&#4; Primary	M.T.
6cebc7de-42ca-459d-b530-aece28ff35ee	cmofl3ut6000hmjdmwqd3dziu	Jindal Panther Tmt Fe550d-10mm	&#4; Primary	M.T.
c90e5fc3-a0d8-4d07-8261-3a32cafe88bd	cmofl3ut6000hmjdmwqd3dziu	Jindal Panther Tmt Fe550d_25mm	&#4; Primary	M.T.
5ede1750-8717-4482-bff1-dfc987d52329	cmofl3ut6000hmjdmwqd3dziu	Miss Roll Sariya Cutting	&#4; Primary	M.T.
322a98d1-939f-4e99-901d-99aa7671ff61	cmofl3ut6000hmjdmwqd3dziu	M.S. BAR  721410	&#4; Primary	M.T.
e28dce9c-e55b-4093-8fc2-1d53bff54d61	cmofl3ut6000hmjdmwqd3dziu	M.S. BAR  72141090	&#4; Primary	M.T.
bb0d17e4-e04e-483a-8f7f-33361c780269	cmofl3ut6000hmjdmwqd3dziu	M.S. BAR -72142090	&#4; Primary	M.T.
0f8cec18-487f-45d4-a266-57a23dc3858d	cmofl3ut6000hmjdmwqd3dziu	M.S. Bars	&#4; Primary	M.T.
aa6127f1-3e76-4176-81b0-1231f3c7f1b8	cmofl3ut6000hmjdmwqd3dziu	M.S Bars 10 MM	Sariya	kg.
c8a10f0d-9bb4-4623-ac41-0a5acab248b1	cmofl3ut6000hmjdmwqd3dziu	M.S Bars 12 MM	Sariya	kg.
0a9c1513-8b2a-4c5c-a4be-e684c2494cf7	cmofl3ut6000hmjdmwqd3dziu	M.S Bars 16MM	Sariya	kg.
06ed56ed-eb0d-4c0a-865d-d931392379e7	cmofl3ut6000hmjdmwqd3dziu	M.S Bars 20 MM	Sariya	kg.
a0864a52-73ba-4730-a732-b835224d65d8	cmofl3ut6000hmjdmwqd3dziu	M.S Bars 25 MM	Sariya	kg.
03bca202-0f80-43c9-8ad9-e40fd18a341c	cmofl3ut6000hmjdmwqd3dziu	M.S Bars 32 MM	Sariya	kg.
a53fe12b-77e3-4e99-a91d-e00b883808f1	cmofl3ut6000hmjdmwqd3dziu	MS BARS- 72142090	&#4; Primary	M.T.
feb44324-3e7a-41fc-b3d7-a71ea4accd2d	cmofl3ut6000hmjdmwqd3dziu	M.S Bars 8MM	Sariya	kg.
f85b5366-a3ed-4a0c-b7d3-f93cc8eca10d	cmofl3ut6000hmjdmwqd3dziu	M.S. Ribbed Bar-721550	&#4; Primary	M.T.
84d63312-0a79-4383-8786-a0300c7907ac	cmofl3ut6000hmjdmwqd3dziu	M.S. Ribbers Bar(7215)	&#4; Primary	M.T.
acae2285-51e7-4449-98a5-ac56b4f45785	cmofl3ut6000hmjdmwqd3dziu	M.S. Rod-7214	&#4; Primary	M.T.
f521a7aa-3d36-4c69-adba-bf26df5d6cb7	cmofl3ut6000hmjdmwqd3dziu	M S ROUND BAR-7106	&#4; Primary	M.T.
3b1af07a-fee8-4227-a7f6-6c367392907d	cmofl3ut6000hmjdmwqd3dziu	M S ROUND BAR-72142090	&#4; Primary	M.T.
1f841a96-20e1-4896-b5de-1422765e4cac	cmofl3ut6000hmjdmwqd3dziu	MS TMT BAR 72142090	&#4; Primary	M.T.
84a8b6da-6fa7-461f-93d5-876078cd4ea3	cmofl3ut6000hmjdmwqd3dziu	Reinforcement Bar Ring	&#4; Primary	M.T.
1d97180b-894a-4dea-a26d-d3c9a88e995c	cmofl3ut6000hmjdmwqd3dziu	STEEL TUBE-73066100	&#4; Primary	M.T.
dd5eced0-7bde-43dc-af71-901de5e20414	cmofl3ut6000hmjdmwqd3dziu	TISCON-TMT-721420	&#4; Primary	M.T.
1939980f-c7f1-418c-9a99-f94b1100202e	cmofl3ut6000hmjdmwqd3dziu	TMT BAR-------721410	&#4; Primary	M.T.
de194e13-93ad-4af6-8ad2-cd993c2c7ce9	cmofl3ut6000hmjdmwqd3dziu	TMT BAR 721499	&#4; Primary	M.T.
e7cc29a6-a0fa-4ee2-a5bd-e8af39bbdbf2	cmofl3ut6000hmjdmwqd3dziu	TMT BAR-72149990	&#4; Primary	M.T.
5b5e673e-0d8b-4e00-a352-c15e39d6117a	cmofl3ut6000hmjdmwqd3dziu	TMT BARS	&#4; Primary	M.T.
4a9aeb89-dab5-478e-95e9-889c3f1428ee	cmofl3ut6000hmjdmwqd3dziu	WIRES-721710	&#4; Primary	M.T.
62a80455-828c-4d11-a2bd-a722a970a181	cmofmpqxp0000tms4st6fcb8x	7.25 PP (CUSTOM)	PACKAGING 18%	KG
517d8d75-65e3-43e2-a490-b9a3647e675c	cmofmpqxp0000tms4st6fcb8x	7.75*12 PP	PACKAGING 18%	KG
b2d5cf3c-29cb-4382-b58c-ae8a22bb798e	cmofmpqxp0000tms4st6fcb8x	8.25*12 Plain  PP	PACKAGING 18%	KG
0f5c56f3-1335-4d82-9ee6-036e278aa392	cmofmpqxp0000tms4st6fcb8x	85GM PACKING MATERIAL	PACKAGING 18%	KG
6f268319-11cb-450e-8187-5ed70515b167	cmofmpqxp0000tms4st6fcb8x	Air Cooler Hummer 500mm 140ltr	&#4; Primary	PCS
b6664877-1ecb-4f2a-b79e-44a121bfb369	cmofmpqxp0000tms4st6fcb8x	Ajanta 555	RAW MATERIAL	DIBBI
2021ab79-8d79-4141-a92c-d6832207e7ed	cmofmpqxp0000tms4st6fcb8x	AJWAINE	RAW MATERIAL	KG
caf37916-8570-467d-a72b-8ae40c050b23	cmofmpqxp0000tms4st6fcb8x	AJWAINE ESSENCE	RAW MATERIAL	ML
b6aa866f-37c0-4bfb-a668-1d64eabac417	cmofmpqxp0000tms4st6fcb8x	AKASH MAIDA (JEERA)	RAW MATERIAL	KG
a79ddaa6-78b2-4c01-88a5-cb85bb47cc4b	cmofmpqxp0000tms4st6fcb8x	ALMOND	RAW MATERIAL	KG
79ff3fa8-767e-4bad-85e4-8118b0e744f3	cmofmpqxp0000tms4st6fcb8x	ALMOND ESSENCE	RAW MATERIAL	LTR
958f83f4-f5d9-4c41-b706-fb88c6ee858d	cmofmpqxp0000tms4st6fcb8x	ALSI	RAW MATERIAL	KG
02e3d8b7-bae4-445f-9e98-2cca63127c08	cmofmpqxp0000tms4st6fcb8x	AMMONIA	RAW MATERIAL	KG
df6f960f-904d-473a-bdf1-3dbc0c94dfe2	cmofmpqxp0000tms4st6fcb8x	AMRIT DILITE VANASPATI(BISCUITS &amp; SACHE)	RAW MATERIAL	TIN
02b9f2fd-140b-4d8e-bf79-9e6acec071e4	cmofmpqxp0000tms4st6fcb8x	Amrit Dilite Vansapati	RAW MATERIAL	TIN
7c040c20-7021-473b-b9aa-ea2f47cd5f7f	cmofmpqxp0000tms4st6fcb8x	AMRITH YELLOW PUFF	RAW MATERIAL	KG
0beba37f-c013-4a7a-b27f-08379f69d34a	cmofmpqxp0000tms4st6fcb8x	AMUL MILK POWDER 1KG	RAW MATERIAL	KG
d80fe934-613b-4710-ad7d-399485a43621	cmofmpqxp0000tms4st6fcb8x	Amul Milk Powder (1kg) SMP, MM90	RAW MATERIAL	KG
2162790c-da37-462e-b0fe-89fc0f0f42d6	cmofmpqxp0000tms4st6fcb8x	AROMA STRAWBERRY COLOUR MIST 200GM	RAW MATERIAL	GM
866b598b-2fc3-48cb-855b-9c9c85a99144	cmofmpqxp0000tms4st6fcb8x	ATTA 50KG	RAW MATERIAL	KG
141551db-7d03-4284-a095-9fb9ac90ba7a	cmofmpqxp0000tms4st6fcb8x	BADAM	RAW MATERIAL	KG
d57a9a71-3432-4850-9db2-f05ec7e01954	cmofmpqxp0000tms4st6fcb8x	BAKERY SHORTENING GHI	RAW MATERIAL	KG
88c678da-6f2e-463d-b0f9-5110ce8b734a	cmofmpqxp0000tms4st6fcb8x	BAKING POWDER	RAW MATERIAL	KG
645d1f77-1dca-418c-995c-45a844238b92	cmofmpqxp0000tms4st6fcb8x	BANDHAN NAMAK	RAW MATERIAL	KG
e2790fae-8eb1-4d16-921e-e61390693017	cmofmpqxp0000tms4st6fcb8x	BANSARI GHI B RUSK	RAW MATERIAL	KG
6d8f0a6c-2a56-4192-8fce-0085ddce17d2	cmofmpqxp0000tms4st6fcb8x	BESAN	RAW MATERIAL	KG
fd3c0eea-cb33-472d-8c28-6026e9cfa90f	cmofmpqxp0000tms4st6fcb8x	Biscuits Maida	RAW MATERIAL	KG
ba4f5093-3eed-4478-80c5-878cdc847722	cmofmpqxp0000tms4st6fcb8x	BISCUITS PLAIN ROLL 380MM	PACKAGING 18%	KG
ef92ed0e-5a7e-4388-8e04-893e4c533171	cmofmpqxp0000tms4st6fcb8x	Biscuits Tray	PACKAGING 18%	KG
709d6782-435e-4688-894c-3df47027acd2	cmofmpqxp0000tms4st6fcb8x	BROKEN BRUSK	SCRAP	KG
087bde2b-8775-4b21-a690-2726b611d871	cmofmpqxp0000tms4st6fcb8x	BROKEN KJ RUSK	SCRAP	KG
7ee6bb76-96df-4977-8125-a9cb66d09aad	cmofmpqxp0000tms4st6fcb8x	Broken Rusk	SCRAP	KG
31840398-151b-4eb4-b0c8-ef957d6b1c2d	cmofmpqxp0000tms4st6fcb8x	B RUSK AJWAINE 250GM	Finished Goods	CB
6b6926aa-1b15-45f4-a521-4c738bdcac56	cmofmpqxp0000tms4st6fcb8x	B RUSK AJWAINE 300GM	Finished Goods	CB
abae460d-5eaa-4399-8ca5-a91ec4a33839	cmofmpqxp0000tms4st6fcb8x	B RUSK ATTA 250GM	Finished Goods	CB
fd343c2b-2a34-4776-b1df-abb058e2567d	cmofmpqxp0000tms4st6fcb8x	B RUSK BESAN K 250GM	Finished Goods	CB
31dc142a-660b-4a97-88e8-f37246721d73	cmofmpqxp0000tms4st6fcb8x	B RUSK CHERRY 250G	Finished Goods	CB
93f2055a-b9f0-4cf9-9d4e-63a636e4f545	cmofmpqxp0000tms4st6fcb8x	B RUSK CHERRY K 250GM	Finished Goods	CB
0df0a7fc-13cf-4d64-8cb1-3b88d5d8dc70	cmofmpqxp0000tms4st6fcb8x	B RUSK CHOCO-CHIPS 250GM	Finished Goods	CB
9795de25-258a-4cc9-a1c3-ea6f4befe081	cmofmpqxp0000tms4st6fcb8x	B RUSK CHOCO CHIPS 300GM	Finished Goods	CB
a1322c9e-1b78-4122-bd66-a9a52d465484	cmofmpqxp0000tms4st6fcb8x	B RUSK CHOCOCLATE PEANUT 250GM	Finished Goods	CB
21fab3cb-9d00-433b-b186-0566b8e68893	cmofmpqxp0000tms4st6fcb8x	B RUSK CHOCOLATE K 250G	Finished Goods	CB
a9ae4954-5ecb-4ab1-8331-120dad480502	cmofmpqxp0000tms4st6fcb8x	B Rusk Chocolate K250gm	Finished Goods	CB
b87c23d1-fc6e-44bb-9b67-f642b1819ead	cmofmpqxp0000tms4st6fcb8x	B RUSK CHOCOLATE PEANUT 300G	Finished Goods	CB
0458ce37-389f-4919-af5b-2657ae879865	cmofmpqxp0000tms4st6fcb8x	B Rusk Choco-Till	Finished Goods	CB
ced3683c-75ca-469a-9914-609a26498976	cmofmpqxp0000tms4st6fcb8x	B RUSK COCONUT 250 GM	Finished Goods	CB
1d3b8b8e-0ac8-4d4a-a75c-7b7f83dec717	cmofmpqxp0000tms4st6fcb8x	B RUSK COCONUT 300GM	Finished Goods	CB
e8553cba-480f-4a76-a116-51851c9f99ea	cmofmpqxp0000tms4st6fcb8x	BRUSK COCONUT JAM 300GM	Finished Goods	CB
1d7e80a1-d39c-4a5d-9859-a247413b898c	cmofmpqxp0000tms4st6fcb8x	B RUSK COOCKIES 300gm	Finished Goods	CB
2f650532-2537-4311-a6c5-848a8b15ba2d	cmofmpqxp0000tms4st6fcb8x	B RUSK D JEERA 250GM	Finished Goods	CB
4008caac-2d88-4d99-81cc-dc284b15d134	cmofmpqxp0000tms4st6fcb8x	B RUSK D KALAUNJI 250GM	Finished Goods	CB
0be52e5f-7a46-47e3-8aac-d89f0bcc3863	cmofmpqxp0000tms4st6fcb8x	B RUSK D KALI MRICH 250GM	Finished Goods	CB
a57c4f53-77ad-46b0-8ab9-63080b49a20f	cmofmpqxp0000tms4st6fcb8x	B RUSK D LACHHA 250GM	Finished Goods	CB
2c44227d-6562-420d-8e7d-fa34c4ccdcfd	cmofmpqxp0000tms4st6fcb8x	B RUSK DRY FRUIT 250GM	Finished Goods	CB
c3bfa47a-d14a-4408-be06-e888760eddd0	cmofmpqxp0000tms4st6fcb8x	B RUSK DRY FRUIT 300GM	Finished Goods	CB
f5d665cd-4448-4cba-9027-bee62da14b68	cmofmpqxp0000tms4st6fcb8x	B Rusk DRY-FRUIT (ALMOND) 250g	Finished Goods	CB
7c9186e1-963c-4a30-9f30-fe566d4b6abc	cmofmpqxp0000tms4st6fcb8x	B RUSK DRY-FRUIT (CASHEW) 250g	Finished Goods	CB
546eb57d-e1d7-4f61-968d-e180d6bd5080	cmofmpqxp0000tms4st6fcb8x	B RUSK DRY-FRUIT MIX 250g	Finished Goods	CB
5cc655b9-5ad2-4b57-b56c-67b635246e5d	cmofmpqxp0000tms4st6fcb8x	B RUSK ELAICHE K 250GM	Finished Goods	CB
e816fe01-3166-447e-93c7-a1b07d321a14	cmofmpqxp0000tms4st6fcb8x	B RUSK (HONEY-ALMOND)250g	Finished Goods	CB
f727756c-ca05-4aa8-af12-c5573cb1febf	cmofmpqxp0000tms4st6fcb8x	B RUSK JAM 250GM	Finished Goods	CB
5d016205-5771-4923-b09e-f49bceed9a62	cmofmpqxp0000tms4st6fcb8x	B RUSK JEERA 300GM	Finished Goods	CB
3bd15c09-07d4-4460-88eb-3acca5c6bc4b	cmofmpqxp0000tms4st6fcb8x	B RUSK KALAUNJI 300GM	Finished Goods	CB
653b3625-b738-44e8-8be4-2a9c798755d9	cmofmpqxp0000tms4st6fcb8x	B RUSK KALIMIRCH 300GM	Finished Goods	CB
e8496d47-cf30-4a81-ad0f-11ff2a91d493	cmofmpqxp0000tms4st6fcb8x	B RUSK LACHHA 300GM	Finished Goods	CB
6aba0e8b-e918-4d22-a521-3280fa84dbfd	cmofmpqxp0000tms4st6fcb8x	B RUSK NAURATAN	Finished Goods	CB
254af0f2-40b9-47e3-91ea-e2d3f691e430	cmofmpqxp0000tms4st6fcb8x	B RUSK PACKING MATERIAL	PACKAGING 18%	KG
26ca099f-f34e-4e2e-ac38-48cf1087e6ef	cmofmpqxp0000tms4st6fcb8x	B RUSK PANCHRATAN	Finished Goods	CB
bfca6167-697e-4037-bd9a-ad6e58fc6b96	cmofmpqxp0000tms4st6fcb8x	B RUSK PEANUT 250GM	Finished Goods	CB
d54098e6-f886-4917-a09c-5b2ed14dbe60	cmofmpqxp0000tms4st6fcb8x	B RUSK PEANUT 300GM	Finished Goods	CB
91ef204f-bf9a-4746-a3f7-849091d858e7	cmofmpqxp0000tms4st6fcb8x	B RUSK PEANUT PISTA 250GM	Finished Goods	CB
080bf32f-594e-494a-8033-0d7a32281292	cmofmpqxp0000tms4st6fcb8x	B RUSK STRAWBERRY K 250GM	Finished Goods	CB
f981b85a-b1a9-4f90-8b15-7211a8dfd8e9	cmofmpqxp0000tms4st6fcb8x	B Rusk Tray	PACKAGING 18%	PCS
f2cb10ba-271f-4ebd-88b4-cb576ced532c	cmofmpqxp0000tms4st6fcb8x	B RUSK VANILLA K 250GM	Finished Goods	CB
be649dd1-bbaa-4451-975a-cdf34fb5e67c	cmofmpqxp0000tms4st6fcb8x	BUTTER	RAW MATERIAL	KG
eb565889-4292-4709-9df2-bc98ca59c14a	cmofmpqxp0000tms4st6fcb8x	Butter Essence	RAW MATERIAL	ML
4eb468c2-bf66-4421-944a-582af061bdc7	cmofmpqxp0000tms4st6fcb8x	Camlin Bread Improver 1 Kg	RAW MATERIAL	KG
96bc4167-809f-4f0f-ad7c-cb76f3b09b9f	cmofmpqxp0000tms4st6fcb8x	Candle	RAW MATERIAL	KG
20264a0c-f1ea-4218-b6f3-9519bb2472f6	cmofmpqxp0000tms4st6fcb8x	Caramilk	RAW MATERIAL	KG
4750c0ad-38c8-4d41-923b-a99c2f15e50d	cmofmpqxp0000tms4st6fcb8x	Cardmom Essence	RAW MATERIAL	ML
5c5070c3-98e7-4272-81a8-2ca7a2dad454	cmofmpqxp0000tms4st6fcb8x	CARDOMOM ESSENCE	RAW MATERIAL	LTR
fe22c18c-82fa-4f31-b1b8-35881b8c8fc9	cmofmpqxp0000tms4st6fcb8x	CARRY BAG JHOLA	PACKAGING 18%	PCS
6fc14fee-ecaa-4e38-9612-218f8f6562bc	cmofmpqxp0000tms4st6fcb8x	CASHEW FLAVOUR ESSENCE	RAW MATERIAL	LTR
d6070b68-5cfb-4937-829b-7cea6b5d962d	cmofmpqxp0000tms4st6fcb8x	Cashew (Kaju)	RAW MATERIAL	KG
c7a4c8f0-7120-434d-aebc-61ffdd86293b	cmofmpqxp0000tms4st6fcb8x	CHAMPION MAIDA (BISCUITS)	RAW MATERIAL	BAG
e66af8b0-adb7-44d5-8424-c2f5cd3c00c8	cmofmpqxp0000tms4st6fcb8x	CHANA	RAW MATERIAL	KG
236503a2-5389-4caa-8520-7d6bd3d37887	cmofmpqxp0000tms4st6fcb8x	CHERRY	RAW MATERIAL	KG
ba2c3fdb-c14f-4479-a418-acf819adb3d1	cmofmpqxp0000tms4st6fcb8x	CHOCO CHIPS	RAW MATERIAL	KG
66e2a8b3-f18e-42ae-bd25-a909c51f8fa4	cmofmpqxp0000tms4st6fcb8x	Chocolate Essence	RAW MATERIAL	ML
30762529-1eab-4be2-9b3a-956e30b804c9	cmofmpqxp0000tms4st6fcb8x	COCONUT ESSENCE	RAW MATERIAL	BOTTEL
d96cf567-2231-423e-a519-e6bcb80110ab	cmofmpqxp0000tms4st6fcb8x	COCONUT ESSENCE 1 LTR PEACOCK	RAW MATERIAL	ML
8e112aae-90d2-4d8e-b550-eeadec0b7a61	cmofmpqxp0000tms4st6fcb8x	COCONUT FLAKES (BURADA 25KG)	RAW MATERIAL	KG
9e883ebf-4fc0-4828-8aff-8f5ff222477b	cmofmpqxp0000tms4st6fcb8x	Coconut Flakes (Lachha)	RAW MATERIAL	KG
fab934ad-019d-42c9-8cfa-715e3f94c8e2	cmofmpqxp0000tms4st6fcb8x	COCO POWDER	RAW MATERIAL	KG
ac8a2e56-a660-4485-b6be-be842d11a77e	cmofmpqxp0000tms4st6fcb8x	Coockies Sticker	PACKAGING 18%	PCS
18d053d8-3589-4d3c-9c5c-bc99aa08fbad	cmofmpqxp0000tms4st6fcb8x	Coockies Tag	PACKAGING 18%	PCS
95f54110-a2d4-446c-83ae-3ae9baed234d	cmofmpqxp0000tms4st6fcb8x	CORRUGATED 70 Gm Partition	PACKAGING 18%	PCS
851cf4d7-72f7-4426-b062-daa8163604bd	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX (300GM  GREEN)	PACKAGING 18%	PCS
9287ce30-a210-497a-96d9-cfa22b9a40d9	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX 80G NEW (VIRGIN)	PACKAGING 18%	PCS
c6485217-968c-407a-9c32-fc01447260bc	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX 85GM	PACKAGING 18%	PCS
0f05d2dc-5a88-4304-83e8-55ca13ae2f95	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX 85GM 48 PC	PACKAGING 18%	PCS
e81b60aa-4a92-4401-a7f7-241e5ae8c210	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX B RUSK PLAIN	PACKAGING 12%	PCS
647af5bf-40f0-4948-92c0-15101be2b183	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX B RUSK PRINTED	PACKAGING 18%	PCS
342e9471-245a-4507-89dc-2c146ee77f96	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX-COOKIES	PACKAGING 18%	PCS
7b779ffe-2ea7-40e9-94f9-0798615da016	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX-COOKIES PRINTED	PACKAGING 18%	PCS
0602dc0f-4be7-46b3-a104-795a9b0077f5	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX CUSTOM	PACKAGING 18%	PCS
1019adf6-b3c3-4add-9b02-e6429ea78e7f	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX DRF12 PKT	PACKAGING 18%	PCS
17e503f7-c197-4902-9d61-3b3e764516f7	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX DUPLEX MAWA	PACKAGING 18%	PCS
3df2d19b-8176-4553-9f2e-33d4fea21de3	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX GATTU	PACKAGING 18%	PCS
e15a50ef-fb1e-4768-9109-36036ca8be65	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX GATTU 275GM	PACKAGING 18%	PCS
bd472eb9-91a9-466d-8434-078ff048f814	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX GATTU PLAIN	PACKAGING 18%	PCS
0b747fbe-58de-4281-a0e6-efdec44c7d75	cmofmpqxp0000tms4st6fcb8x	Corrugated Box (JEERA)	PACKAGING 18%	PCS
417b35b7-8a8a-4dd4-a954-57a757bc4d54	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX MAWA	PACKAGING 18%	PCS
6f5cc5f9-4e69-49c5-8781-c68910dfba89	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX MAWA (20PKT)	PACKAGING 18%	PCS
9477feb8-a954-42cd-b333-02924033ad70	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX MAWA PLAIN	PACKAGING 18%	PCS
3e1974c1-c86c-47a9-8204-416ba636c5d9	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX MILK 275GM	PACKAGING 18%	PCS
d8ffcfa2-ab05-4a48-96ca-c1ea2f02651b	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX MILK 300GM	PACKAGING 18%	PCS
f7358c74-ae04-4fb8-b1dd-f7ee1eb4b824	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX MILK 300GM PLAIN	PACKAGING 18%	PCS
ff810e4a-e507-44eb-b2aa-d94dfc8838c3	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX MILK NEW	PACKAGING 18%	PCS
567b6281-253a-478a-b596-9d4d1e537c35	cmofmpqxp0000tms4st6fcb8x	CORRUGATED BOX PLANE	PACKAGING 18%	PCS
1e276999-be06-436d-aa6a-05b760f1dcc3	cmofmpqxp0000tms4st6fcb8x	Cottonseed Oil 15kg Tin	RAW MATERIAL	KG
4184365c-27a9-4576-9eb6-203cce737d7e	cmofmpqxp0000tms4st6fcb8x	Cumin Essence	RAW MATERIAL	ML
17a5f5a6-5538-45e6-80b0-b34a5d8107ee	cmofmpqxp0000tms4st6fcb8x	Custom Sticker	PACKAGING 18%	KG
4036b260-f932-4446-93ae-869dbdb589f3	cmofmpqxp0000tms4st6fcb8x	CUSTOM STICKER A	PACKAGING 18%	PCS
7e57e745-a12b-4447-99ff-948868d6079d	cmofmpqxp0000tms4st6fcb8x	Custred Powder	RAW MATERIAL	KG
c05ad958-e27c-4dc0-8c91-77f9f9f3a940	cmofmpqxp0000tms4st6fcb8x	Dahi	RAW MATERIAL	KG
9d0c39cb-a466-4669-97bb-d90a7da65c04	cmofmpqxp0000tms4st6fcb8x	DAMAGE B RUSK 250GM	Damage Goods	CB
9cf02bb9-a2d8-4dc3-901d-e339a6c1802f	cmofmpqxp0000tms4st6fcb8x	DAMAGE B RUSK 300GM	Damage Goods	CB
13a77e43-00d1-461e-a2f3-bccc7c70a080	cmofmpqxp0000tms4st6fcb8x	DAMAGE KJ RUSK 24PKT 180GM	Damage Goods	CB
a85e1a63-c491-4599-a04d-21fb19c4f43e	cmofmpqxp0000tms4st6fcb8x	DAMAGE SD MILK RUSK 275GM	Damage Goods	CB
dc822879-c634-4150-acd9-cd9b08387948	cmofmpqxp0000tms4st6fcb8x	DAMAGE Sd Milk Rusk 300gm	Damage Goods	CB
7ec13096-9072-43b4-a6aa-a50025fb6d97	cmofmpqxp0000tms4st6fcb8x	DAMAGE SD MILK RUSK GATTU 300GM	Damage Goods	CB
270c114f-6882-453e-a666-41ce907f0c57	cmofmpqxp0000tms4st6fcb8x	DAMAGE SD RUSK 85GM	Damage Goods	CB
e2c8f75e-57aa-4766-996a-6443e512cd37	cmofmpqxp0000tms4st6fcb8x	DAMAGE SD RUSK DRY FRUIT 400GM	Damage Goods	CB
8b1478ed-3dd5-4f27-8bb2-5e5417dc5b42	cmofmpqxp0000tms4st6fcb8x	DAMAGE SD RUSK MAWA 12 PKT	Damage Goods	CB
13111cc8-584c-4ae1-b6fb-64e6a42f4821	cmofmpqxp0000tms4st6fcb8x	DAMAGE Suji Elaichi Rusk 350g	Damage Goods	CB
e1926aba-587b-46a8-9a3c-ee8bca7028e6	cmofmpqxp0000tms4st6fcb8x	Dhru Gold 15kg 1 Tin(Rep. Rath)	RAW MATERIAL	KG
1f91e317-7c57-4057-82ef-42d91f627eaa	cmofmpqxp0000tms4st6fcb8x	DHRU PLATINUM (RATH)	RAW MATERIAL	KG
aac706fd-c90d-449e-8100-bf8513498fde	cmofmpqxp0000tms4st6fcb8x	DRY-FRUIT PLAIN ROLL 450MM	PACKAGING 18%	KG
e9ee7dc9-5f59-435e-8ab4-c0970daa32a0	cmofmpqxp0000tms4st6fcb8x	DRY FRUITS ENVELOP	PACKAGING 18%	PCS
cc4fa37d-d7aa-4e64-b2f1-24ff00a70e54	cmofmpqxp0000tms4st6fcb8x	ELAICHI BADI SPECIAL	RAW MATERIAL	KG
abc2de66-69e5-4924-b664-a0f822a5c3d0	cmofmpqxp0000tms4st6fcb8x	ELAICHI DANA	RAW MATERIAL	KG
dc282c97-f1ed-43d3-80a2-6b3a64f2ebf9	cmofmpqxp0000tms4st6fcb8x	ENVELOP MILK	PACKAGING 18%	PCS
5ace8421-e0b9-4db2-aeb3-ed217727f71e	cmofmpqxp0000tms4st6fcb8x	Envelops ( 350 Mawa )	PACKAGING 18%	PCS
dd3fb952-baba-42da-ab3c-0a5facd247a6	cmofmpqxp0000tms4st6fcb8x	ENVELOP SUJI ELAICHI RUSK	PACKAGING 18%	PCS
46506d58-0463-46ce-8404-045bc6216526	cmofmpqxp0000tms4st6fcb8x	GARDEN YELLOW LIQ	RAW MATERIAL	ML
18135e05-b826-49d0-935f-527dfef7d618	cmofmpqxp0000tms4st6fcb8x	Gattu Lable Single Side	PACKAGING 18%	PCS
c348e2b1-f693-49df-8e44-563b9181ad4e	cmofmpqxp0000tms4st6fcb8x	GATTU PACKING MATERIAL	PACKAGING 18%	KG
f736f4a2-fb14-44a9-8973-4e47502041f4	cmofmpqxp0000tms4st6fcb8x	Ghi Biskin Gold (80g)	RAW MATERIAL	KG
0e8dc314-b4ad-4f1a-b229-90489329bf70	cmofmpqxp0000tms4st6fcb8x	GLUCOSE	RAW MATERIAL	KG
559ff7d7-fb8f-4c3a-b9f9-47222386bee0	cmofmpqxp0000tms4st6fcb8x	Gopi Maida	RAW MATERIAL	KG
5150aa13-9073-4b01-86e3-df2d5c6cc728	cmofmpqxp0000tms4st6fcb8x	Green Govind Maida	RAW MATERIAL	KG
3927cdf3-aca3-4c9a-a95e-df91ad03b501	cmofmpqxp0000tms4st6fcb8x	Green Peanut	RAW MATERIAL	KG
45edd36f-5854-4524-884c-8fff8724096b	cmofmpqxp0000tms4st6fcb8x	HONEY	RAW MATERIAL	KG
3ba76ad1-3e44-4b08-a704-9acb8ab62bf6	cmofmpqxp0000tms4st6fcb8x	INNER CARTON DRF	PACKAGING 18%	PCS
c9627bf0-4b1a-449c-b44e-b06742f3a3b4	cmofmpqxp0000tms4st6fcb8x	JEERA	RAW MATERIAL	KG
52247eec-476d-41a8-9844-2cbf47256ceb	cmofmpqxp0000tms4st6fcb8x	JEERA ESSENCE	RAW MATERIAL	ML
085c7832-4f62-41e1-8e83-9db4aee16e15	cmofmpqxp0000tms4st6fcb8x	JUBLEE YELLO	RAW MATERIAL	KG
b20949ec-d217-42db-8a0b-771d233360e5	cmofmpqxp0000tms4st6fcb8x	Kalimirch	RAW MATERIAL	KG
955ff0fe-dbd0-4725-961b-ab5d2fdcbee7	cmofmpqxp0000tms4st6fcb8x	KALUNJI	RAW MATERIAL	KG
8ef2a2e6-bef9-45d5-b171-e58812f99ca5	cmofmpqxp0000tms4st6fcb8x	KASOORI METHI	RAW MATERIAL	KG
5b01482f-7a0a-452d-ba0c-5713793db0f4	cmofmpqxp0000tms4st6fcb8x	KERRY GLUTIN	RAW MATERIAL	KG
91e4feb9-22b6-4720-a65d-1c8d17e885d5	cmofmpqxp0000tms4st6fcb8x	KEVA ALMOND ESSENCE 500GM	RAW MATERIAL	KG
22316708-4ca0-4d48-a40f-b5a9d0a2cc60	cmofmpqxp0000tms4st6fcb8x	KEVA CUMIN ESSENCE 5KG	RAW MATERIAL	KG
d1d9041f-c86a-41d5-8e38-8ad978bf8046	cmofmpqxp0000tms4st6fcb8x	KEYA ROASTED AJWAIN 5KG	RAW MATERIAL	KG
2397030d-206d-4e60-96d0-1fda040d12d3	cmofmpqxp0000tms4st6fcb8x	KHALI TIN	SCRAP	PCS
86c26245-2937-4763-9d93-613a5fac9153	cmofmpqxp0000tms4st6fcb8x	Khari Lable	PACKAGING 18%	PCS
c19731a7-dd51-4ea2-a544-8b3435825399	cmofmpqxp0000tms4st6fcb8x	KHARI PACKING MATERIAL	PACKAGING 18%	KG
11b07e68-721b-48c6-b209-6746affef286	cmofmpqxp0000tms4st6fcb8x	KJ RUSK 225G	Finished Goods	CB
c2b86a90-fdd5-478f-a201-ec43cdbe63ab	cmofmpqxp0000tms4st6fcb8x	KJ RUSK 250G 24PKT	Finished Goods	CB
9672c6f1-e59a-4079-968f-b07da925f2cd	cmofmpqxp0000tms4st6fcb8x	KJ RUSK 250GM	Finished Goods	CB
8d083958-c573-4e4a-9007-20ac755cfb68	cmofmpqxp0000tms4st6fcb8x	KJ RUSK 250GM 20PKT	Finished Goods	CB
4b0a04a8-8c50-4c56-a87f-0d76761cf64a	cmofmpqxp0000tms4st6fcb8x	KJ RUSK 300GT	Finished Goods	CB
3258b11e-dcb1-457f-8dfa-dbfdd07886a2	cmofmpqxp0000tms4st6fcb8x	Lemon Yellow Liquid	RAW MATERIAL	BOTTEL
3b942e1c-5c27-4278-9eb0-b290c72d3cda	cmofmpqxp0000tms4st6fcb8x	LILY STAR GHI (JEERA)	RAW MATERIAL	KG
e3be6386-6de2-45ff-8413-94f1a18563f5	cmofmpqxp0000tms4st6fcb8x	LOTUS MARG.15KG (RATH REP)	RAW MATERIAL	KG
967d1c03-7506-4e18-9f76-240a0d9f0008	cmofmpqxp0000tms4st6fcb8x	LOTUS PRA 15KG FOR SACHHE	RAW MATERIAL	KG
d95e5501-0d5e-4bdd-8847-8b8dbb6b720f	cmofmpqxp0000tms4st6fcb8x	Lpg Cylinder Ndne 47.5 Kg	&#4; Primary	PCS
a3d66732-f8bd-4934-a896-fda0267e1e25	cmofmpqxp0000tms4st6fcb8x	MAIDA BALA JI (MLK, MAWA, 90GM, SUJI &amp; CUSTOM)	RAW MATERIAL	KG
ae8e2116-19e9-45a1-a647-2d3909abc4d8	cmofmpqxp0000tms4st6fcb8x	Maida (Barah Singha) (GATTU JEERA)	RAW MATERIAL	KG
260dd5b1-5546-4281-beab-3b1c66b253cb	cmofmpqxp0000tms4st6fcb8x	MAIDA CHETAK (MLK MAWA 90GM, SUJI CUSTOM)	RAW MATERIAL	KG
508e596d-f818-400e-85e6-6d8745aded8b	cmofmpqxp0000tms4st6fcb8x	MAIDA KALASH (BISCUITS)	RAW MATERIAL	KG
7ccf0c28-48c9-42b3-a8d5-9b14be62f6ac	cmofmpqxp0000tms4st6fcb8x	MAIDA MADHURAM	RAW MATERIAL	KG
2fdc44ab-5337-4523-8ec8-210e474f08f8	cmofmpqxp0000tms4st6fcb8x	MAIDA ROYAL KING	RAW MATERIAL	KG
30e7b5f6-73f1-43e3-90c9-903537724b2a	cmofmpqxp0000tms4st6fcb8x	MAWA MILK BOOSTER ESSENCE	RAW MATERIAL	KG
1e88edb5-5767-4d1d-aae6-1e364908457d	cmofmpqxp0000tms4st6fcb8x	MAWA , MILK ESSENCE	RAW MATERIAL	ML
2084df56-104b-4ec9-a411-27d89279028b	cmofmpqxp0000tms4st6fcb8x	MAWA PACKING MATERIAL	PACKAGING 18%	KG
fcfcc3af-a56e-429c-81de-76a81c13a579	cmofmpqxp0000tms4st6fcb8x	MAYUR B RUSKGHI BAKERS NEED	RAW MATERIAL	KG
717226b6-340a-42ea-b17f-d1e8848bdcba	cmofmpqxp0000tms4st6fcb8x	MILK	RAW MATERIAL	KG
869081a4-74cb-4dc2-ace0-2e3bb3866fe1	cmofmpqxp0000tms4st6fcb8x	MILK ENVELOP 275GM	PACKAGING 18%	PCS
bd14d531-a89e-470e-8f5e-9b24961461d2	cmofmpqxp0000tms4st6fcb8x	MILK MAID 5KG	RAW MATERIAL	KG
2d3be9fc-a5b1-46e9-ac2e-e03d25eba040	cmofmpqxp0000tms4st6fcb8x	MILK PACKING MATERIAL	PACKAGING 18%	KG
91e7c4f7-2aa0-4742-87ab-9bab7bc9c7f8	cmofmpqxp0000tms4st6fcb8x	Milk Powder (1kg) SMP, Lucknow	RAW MATERIAL	KG
b5e33f76-1a3c-47f2-9aab-de19fc7dd0d3	cmofmpqxp0000tms4st6fcb8x	Milk Sprey 500gm (G)	RAW MATERIAL	KG
187da723-19e6-4232-ba01-5727ee53eedf	cmofmpqxp0000tms4st6fcb8x	MINI SAMPLE DRY-FRUIT	Finished Goods	PCS
4b0173d7-4a29-4995-a2b5-8dbbb8c3e432	cmofmpqxp0000tms4st6fcb8x	MINI SAMPLE MAWA	Finished Goods	PCS
c83cec98-32b6-413d-bfdb-a5a8b9a63956	cmofmpqxp0000tms4st6fcb8x	MIX B RUSK 200G	Finished Goods	CB
74895805-3cf1-45fb-96f5-3053ea3758b8	cmofmpqxp0000tms4st6fcb8x	MIX B RUSK 250GM	Finished Goods	CB
f4b03abc-492a-4a56-9f68-e1388288d23e	cmofmpqxp0000tms4st6fcb8x	MIX B RUSK 300GM	Finished Goods	CB
b9c870da-757b-4f6b-9940-3d90ab049c71	cmofmpqxp0000tms4st6fcb8x	MIXED FRUIT JAM	RAW MATERIAL	BAG
33637cfa-beaa-430f-88b5-bcddb321e5b6	cmofmpqxp0000tms4st6fcb8x	MIXED FRUIT JAM 4KG	RAW MATERIAL	KG
629fd7f5-b106-4acc-bb9a-72c78226de14	cmofmpqxp0000tms4st6fcb8x	MIX FRUIT ESSENCE	RAW MATERIAL	ML
c68321c5-e94d-40d9-bc7e-2301e2140fa3	cmofmpqxp0000tms4st6fcb8x	NAAMAK	RAW MATERIAL	KG
8786e2c5-ec1d-4be9-8db1-648a9ea6b0b5	cmofmpqxp0000tms4st6fcb8x	NAMAK	RAW MATERIAL	KG
ab7060ab-178c-4313-a5bd-faaf1e7229a0	cmofmpqxp0000tms4st6fcb8x	NATURE FRESH OIL 15KG(MLK, MAWA, GATTU JEERA)	RAW MATERIAL	TIN
0892c7d0-9557-4003-ace6-3b68dd425627	cmofmpqxp0000tms4st6fcb8x	NILONS PAPAYA FRUIT PRESERVED	RAW MATERIAL	KG
e6d9976e-9b9b-4804-b071-45c5cd5c2fa9	cmofmpqxp0000tms4st6fcb8x	ORANGE ESSENCE	RAW MATERIAL	ML
79a57885-eb7a-4cc0-8369-41793c162ed2	cmofmpqxp0000tms4st6fcb8x	Orange Oil 500ml	RAW MATERIAL	BOTTEL
8180a207-b41a-4cb1-bbb7-f979896ae1b6	cmofmpqxp0000tms4st6fcb8x	Packing Machine	&#4; Primary	PCS
ab8a9e75-0672-42ea-9fdf-1fe6f240b81d	cmofmpqxp0000tms4st6fcb8x	PACKING MATERIAL PRINTED COOKIES	PACKAGING 18%	KG
4fdfaec6-64a9-47d3-adec-ca09c9837a20	cmofmpqxp0000tms4st6fcb8x	PANGHAT GHI 90GM	RAW MATERIAL	KG
6549aa90-0640-48d7-9869-b812ecbd6344	cmofmpqxp0000tms4st6fcb8x	PANGHAT PUFF	RAW MATERIAL	KG
8d5c3c84-1d6d-44cb-a797-d79c4cc61954	cmofmpqxp0000tms4st6fcb8x	PANODAN AB 100 VEG 25 KG ( Ditam)	RAW MATERIAL	KG
957892ca-4340-45f6-a4fb-6c0c3b0f8a91	cmofmpqxp0000tms4st6fcb8x	PEACOCK CHOCOLATE ESSENCE 1LTR	RAW MATERIAL	LTR
c0009091-77a6-49e9-9b4d-85ff62e1afc5	cmofmpqxp0000tms4st6fcb8x	PEACOCK COCONUT ESSENCE	RAW MATERIAL	LTR
db38408f-813e-4263-810b-ffdceb8946fc	cmofmpqxp0000tms4st6fcb8x	Peacock Essence Butter Scotch 1ltr	RAW MATERIAL	LTR
de33c1cd-8195-4878-b68e-01df2bde6900	cmofmpqxp0000tms4st6fcb8x	Peacock Jeera Essence 1ltr	RAW MATERIAL	LTR
06a4f998-26c4-433a-87c9-64cabbf48aef	cmofmpqxp0000tms4st6fcb8x	PEANUT	RAW MATERIAL	KG
0bf9362c-a44f-4327-8a2e-4b9e7da25dcc	cmofmpqxp0000tms4st6fcb8x	PEANUT ESSENCE	RAW MATERIAL	ML
1e40cba1-8574-4ce0-a05e-953666e2ef33	cmofmpqxp0000tms4st6fcb8x	PET JAR	PACKAGING 18%	PCS
e77b5eee-a0ce-4312-bf7b-fdcc5b4f47ca	cmofmpqxp0000tms4st6fcb8x	Pineapple Essence	RAW MATERIAL	ML
ccf504cf-e7ca-44f5-a0db-54f7b95fed8c	cmofmpqxp0000tms4st6fcb8x	Pink Colour	RAW MATERIAL	ML
f0d43c65-f5ab-467c-83ee-c5876d576499	cmofmpqxp0000tms4st6fcb8x	PISTA	RAW MATERIAL	KG
f96e1d27-c969-4977-9db5-d64c3a016fc1	cmofmpqxp0000tms4st6fcb8x	PISTA ESSENCE	RAW MATERIAL	ML
a0d0d70d-5134-44fa-b580-9dea07bdcd58	cmofmpqxp0000tms4st6fcb8x	PLAIN ROLL 420MM	PACKAGING 18%	KG
08bdac16-b7cc-4d85-8c4e-0992cb895968	cmofmpqxp0000tms4st6fcb8x	PLAIN ROLL 440MM	PACKAGING 18%	KG
fb1709e2-5676-46dd-b931-ce38f4014b35	cmofmpqxp0000tms4st6fcb8x	PLAIN ROLL MLK 150GM 350MM	PACKAGING 18%	KG
03133443-0549-475e-85bf-6917e4048f41	cmofmpqxp0000tms4st6fcb8x	PLASTIC BORI (MAIDA)	SCRAP	PCS
5b0694dd-abdb-45ff-8dc3-478e197e29d8	cmofmpqxp0000tms4st6fcb8x	PLASTIC PACKING MATERIAL(6.5x12 Ss)	PACKAGING 18%	KG
f84acfef-3b53-4285-8058-14b76f25609d	cmofmpqxp0000tms4st6fcb8x	PLASTIC PACKING MATERIAL(6.5x13 )	PACKAGING 18%	KG
02fcf93e-bac9-48ea-aed3-bfde1b8707a7	cmofmpqxp0000tms4st6fcb8x	PLASTIC PACKING MATERIAL(Jeera) (6*12) P.P	PACKAGING 18%	KG
32d1af96-62f8-4743-9d67-560a6afb1742	cmofmpqxp0000tms4st6fcb8x	PLASTIC PACKING MATERIALMILK 275gm Red/yellwo	PACKAGING 18%	KG
b61efedd-52ba-403b-971c-5067fe543858	cmofmpqxp0000tms4st6fcb8x	PLASTIC PACKING MATERIAL( ML+MW) (7.5*12) P.P	PACKAGING 18%	KG
adbc955c-e997-4478-abae-3d77921861f3	cmofmpqxp0000tms4st6fcb8x	Plastic Paking Material ( 90GM ) ( 5.75 X 10 )	PACKAGING 18%	KG
2fba5f90-76d6-43de-bcaa-3b2b4e237bd4	cmofmpqxp0000tms4st6fcb8x	Plastic Paking Material ( Gattu ) ( 8.25 X 12 )	PACKAGING 18%	KG
d459958b-1780-4024-a95b-3f00f7cf22df	cmofmpqxp0000tms4st6fcb8x	Plastic Paking Material ( Gattu ) ( 8 X 12 )	PACKAGING 18%	KG
88c6df8c-0e50-4cd1-9116-5b5c1975993d	cmofmpqxp0000tms4st6fcb8x	PLASTIC (SUGER BORI)	SCRAP	PCS
843aace5-3b70-4714-b858-98f22eb45a6a	cmofmpqxp0000tms4st6fcb8x	PP 7.5*12 ML+MW	PACKAGING 18%	KG
1c2c78d4-f97a-4865-893a-9d9b73f4e7bb	cmofmpqxp0000tms4st6fcb8x	PP 8.05*12 PACKING MATERIAL	PACKAGING 18%	KG
a88cdbcd-8178-4121-a9f3-d22e1bded8d7	cmofmpqxp0000tms4st6fcb8x	PP 8.25*12 PACKING MATERIAL	PACKAGING 18%	KG
c830040b-faea-4ec4-b19d-7ec4c82673d6	cmofmpqxp0000tms4st6fcb8x	PP PRINTED GATTU	PACKAGING 18%	KG
772008d7-b509-4853-9a32-cae30391c36b	cmofmpqxp0000tms4st6fcb8x	PRINTED LAMINATED POUCH MILK	PACKAGING 18%	PCS
7e7a92f1-ae95-4fe8-ac4b-e3a20db9ff48	cmofmpqxp0000tms4st6fcb8x	PRINTED TAPE SD 130MTR	PACKAGING 18%	MTR
7ed02806-4e1f-4948-ba83-cbaf6946df99	cmofmpqxp0000tms4st6fcb8x	PUFF 180 GM	Finished Goods	PKT
f9fe4be0-e8c5-4f90-a85b-e2eb71e29f63	cmofmpqxp0000tms4st6fcb8x	RADHA BHOG MAIDA BISCUITS	RAW MATERIAL	KG
d701496c-f662-4101-842c-2b3e8c9e68e8	cmofmpqxp0000tms4st6fcb8x	RAIN CARD	Finished Goods	PCS
d5216aa6-dad7-46e9-aff0-f787718187ca	cmofmpqxp0000tms4st6fcb8x	RC LIQUID FOOD COLOUR	RAW MATERIAL	ML
25f0e637-9970-48e4-9144-dbf33d1841b3	cmofmpqxp0000tms4st6fcb8x	Refined Groundnut Oil 15 Kg Tin	RAW MATERIAL	KG
1df8cf1f-492c-453e-9269-ba7a59683bb9	cmofmpqxp0000tms4st6fcb8x	Refined Palmoil 15kg Tin (Sachhe)	RAW MATERIAL	KG
3f79e470-5517-48d2-9c72-351d58da3d2d	cmofmpqxp0000tms4st6fcb8x	REX BAKING POWDER	RAW MATERIAL	KG
dfc92437-90db-4a61-88c0-26acd5aca67d	cmofmpqxp0000tms4st6fcb8x	SAMPEL BOX COOKIES	PACKAGING 18%	PCS
cb55722d-d573-415e-a9d7-58a536d810f5	cmofmpqxp0000tms4st6fcb8x	Sampel Box Mawa	PACKAGING 18%	PCS
2b40750d-40e4-4c08-9ea9-446fbe8f7508	cmofmpqxp0000tms4st6fcb8x	Sampel Box Milk	PACKAGING 18%	PCS
15b6285d-94f7-4a52-b3f0-527a8b9cb117	cmofmpqxp0000tms4st6fcb8x	SAMPEL BOX SUJI	PACKAGING 18%	KG
4d7a523f-309e-4141-933b-00fd45d281c7	cmofmpqxp0000tms4st6fcb8x	Sampel B Rusk	Finished Goods	PCS
ae7d5b70-6489-49c0-854a-c1e34e82911a	cmofmpqxp0000tms4st6fcb8x	SAMPLE BOX DRY FRUIT MINI	PACKAGING 18%	PCS
d553a9a5-fcc8-47dc-a42b-0724062a96b5	cmofmpqxp0000tms4st6fcb8x	SAMPLE BOX GATTU	PACKAGING 18%	PCS
4923f2ab-596c-45d2-8808-b458e0b85806	cmofmpqxp0000tms4st6fcb8x	SAMPLE BOX MILK MINI	PACKAGING 18%	PCS
86e1a399-6334-4232-83dd-bb0d6dfa2c44	cmofmpqxp0000tms4st6fcb8x	SAMPLE MAWA MINI	PACKAGING 18%	PCS
4e88e75b-bbc3-4869-ac60-5862c0b9a228	cmofmpqxp0000tms4st6fcb8x	SANA IMPROVER	RAW MATERIAL	KG
81d0881d-977f-4514-9d55-83ab494f99d6	cmofmpqxp0000tms4st6fcb8x	Scrap ( Geili Cutting ) Yield	SCRAP	KG
801ef862-200d-499d-9278-ad9aecfc2ea8	cmofmpqxp0000tms4st6fcb8x	SD COOKIES AATA 250 GM	Finished Goods	CB
8bb92e2c-8af7-4432-82c2-4b6f576a21b7	cmofmpqxp0000tms4st6fcb8x	SD COOKIES AJWAIN 250 GM	Finished Goods	CB
cc4cf227-ebde-45ca-ad3d-fc751b237c83	cmofmpqxp0000tms4st6fcb8x	SD COOKIES BESAN KHATAI 250 GM	Finished Goods	CB
ac7882d6-f9ee-4bd2-bff4-d4dcb4bd9e72	cmofmpqxp0000tms4st6fcb8x	SD COOKIES CHERRY 250 GM	Finished Goods	CB
ccce92ee-1c2a-4042-bc8a-23f0aae4ff63	cmofmpqxp0000tms4st6fcb8x	SD COOKIES CHERRY KHATAI 250 GM	Finished Goods	CB
22a263f6-de81-4bba-aff6-c3ab3f3f1656	cmofmpqxp0000tms4st6fcb8x	SD COOKIES CHOCO-CHIP  250 GM	Finished Goods	CB
1e3cc61e-9cef-4d9c-907f-2b2694dc163f	cmofmpqxp0000tms4st6fcb8x	SD COOKIES CHOCOLATE KHATAI 250 GM	Finished Goods	CB
7f1c1e6e-1dbb-4cb9-b826-9fcbb3b02e33	cmofmpqxp0000tms4st6fcb8x	SD COOKIES CHOCOLATE PEANUT 250 GM	Finished Goods	CB
ec351e72-a3b3-4a6b-9b81-fa8bbeff539b	cmofmpqxp0000tms4st6fcb8x	SD COOKIES CHOCOLATE TIL 250 GM	Finished Goods	CB
ea26209d-a796-4fa8-8681-8054e90a1dcf	cmofmpqxp0000tms4st6fcb8x	SD COOKIES COCONUT 250 GM	Finished Goods	CB
e5b9cf13-041e-43f7-b8e9-2ac733be19b9	cmofmpqxp0000tms4st6fcb8x	SD COOKIES DRY FRUITS (ALMOND) 250 GM	Finished Goods	CB
f8f3e6e5-4c7b-480a-889d-29a8d56cd45d	cmofmpqxp0000tms4st6fcb8x	SD COOKIES DRY FRUITS (CASHEW) 250 GM	Finished Goods	CB
d1a8a0db-35e3-4313-8041-3c84a082351e	cmofmpqxp0000tms4st6fcb8x	SD COOKIES DRY FRUITS MIX 250 GM	Finished Goods	CB
55b58fe4-a3cb-4832-9d13-f2ed5daec882	cmofmpqxp0000tms4st6fcb8x	SD COOKIES ELAICHI KHARAI 250 GM	Finished Goods	CB
1ec63251-7c1c-4617-9649-f3e3815c34df	cmofmpqxp0000tms4st6fcb8x	SD COOKIES HONEY ALMOND 250 GM	Finished Goods	CB
eb009e28-c0ef-42fb-a321-db2776402dc3	cmofmpqxp0000tms4st6fcb8x	SD COOKIES JAM 250 GM	Finished Goods	CB
e4260142-bd59-4059-98a9-d9377013e341	cmofmpqxp0000tms4st6fcb8x	SD COOKIES JEERA 250 GM	Finished Goods	CB
eec1f9d4-eccf-4103-9578-580150271728	cmofmpqxp0000tms4st6fcb8x	SD COOKIES KALAUNJI 250 GM	Finished Goods	CB
a01bcd75-ea55-451d-a426-498aec8e4cc5	cmofmpqxp0000tms4st6fcb8x	SD COOKIES KALIMIRCH 250 GM	Finished Goods	CB
f54b10e3-9bec-4132-af58-5dcb28e2cffc	cmofmpqxp0000tms4st6fcb8x	SD COOKIES KASURI METHI 250 GM	Finished Goods	CB
35b8d922-ebf9-4d6a-9cad-899a67ae5f43	cmofmpqxp0000tms4st6fcb8x	SD COOKIES LACHHA 250 GM	Finished Goods	CB
e3ffcd79-f5c9-4d29-b11d-4fd59cf62d93	cmofmpqxp0000tms4st6fcb8x	SD COOKIES MAGIC MASALA 250 GM	Finished Goods	CB
9588bfd6-fea3-48c6-afcb-b47789a9a860	cmofmpqxp0000tms4st6fcb8x	SD COOKIES NAVRATAN 250 GM	Finished Goods	CB
219ec927-da43-4708-b441-d13c422f26a5	cmofmpqxp0000tms4st6fcb8x	SD COOKIES PANCHRATAN 250 GM	Finished Goods	CB
1f16736c-6fca-4996-92b5-fb76b005fe2a	cmofmpqxp0000tms4st6fcb8x	SD COOKIES PEANUT 250 GM	Finished Goods	CB
05f3c681-a79f-48a3-b9ca-f855c80eda80	cmofmpqxp0000tms4st6fcb8x	SD COOKIES PEANUT PISTA 250 GM	Finished Goods	CB
977c5138-7ac9-4f3b-b24f-645ced9f638d	cmofmpqxp0000tms4st6fcb8x	SD COOKIES STRAWBERRY KHATAI 250 GM	Finished Goods	CB
5c2008a1-affb-47be-9f10-9c4e80c0bd07	cmofmpqxp0000tms4st6fcb8x	SD COOKIES VANILA KHATAI 250 GM	Finished Goods	CB
61dbec81-ad93-437f-9265-33ec7e0ba82b	cmofmpqxp0000tms4st6fcb8x	SD CUSTOM Rusk 300 Gm	Finished Goods	CB
8830f5fa-3fc3-4874-96b9-a592efe88993	cmofmpqxp0000tms4st6fcb8x	SD CUSTOM Rusk 400 GM	Finished Goods	CB
ebca0e19-777b-4c01-a63f-aaa235850c28	cmofmpqxp0000tms4st6fcb8x	SD KHARI ( FAN ) 24PKT 180GM	Finished Goods	CB
fc5cd2f7-c4cb-4ccf-b763-8fea5848c222	cmofmpqxp0000tms4st6fcb8x	SD KHARI ( FAN ) 24PKT 250 GM	Finished Goods	CB
d9050108-94dc-4ed9-9eca-624961c29a64	cmofmpqxp0000tms4st6fcb8x	SD MILK JHOLA 15 PKT	Finished Goods	JHOLA
53a76c93-b1e3-4fb4-a1b1-3be89e517aaf	cmofmpqxp0000tms4st6fcb8x	SD MILK RUSK 150GM	Finished Goods	CB
b90f7d2a-5dac-4aac-acac-605c373d36f5	cmofmpqxp0000tms4st6fcb8x	SD MILK RUSK 275GM	Finished Goods	CB
2fcb2ab5-a805-4e61-be7f-ff376335c662	cmofmpqxp0000tms4st6fcb8x	SD Milk Rusk 300GM	Finished Goods	CB
7347c744-4d20-4926-b1a7-14ace0284035	cmofmpqxp0000tms4st6fcb8x	SD MILK RUSK GATTU 250g	Finished Goods	CB
05787c51-a835-49a0-81fe-20d223ce3c2f	cmofmpqxp0000tms4st6fcb8x	SD MILK RUSK GATTU 275GM	Finished Goods	CB
eca625d6-cb9f-4b6c-a49c-1063363506a9	cmofmpqxp0000tms4st6fcb8x	SD MILK RUSK GATTU 300GM	Finished Goods	CB
c9d17dcf-8707-406c-9020-165e1eaf0a80	cmofmpqxp0000tms4st6fcb8x	SD MILK RUSK GATTU 400GM	Finished Goods	CB
a6dee2d3-c772-4f9c-b2ee-f899533dc364	cmofmpqxp0000tms4st6fcb8x	SD RUSK 70gm (24 Pkt)	Finished Goods	CB
2186cd15-aec0-4d80-afb0-79c155448c05	cmofmpqxp0000tms4st6fcb8x	SD RUSK 80GM	Finished Goods	CB
2393229a-54e8-483f-bb19-40b0c260baff	cmofmpqxp0000tms4st6fcb8x	SD RUSK 80gm (24 Pkt)	Finished Goods	CB
4d983768-5640-4e68-b366-ba48450513d1	cmofmpqxp0000tms4st6fcb8x	SD RUSK 85GM	Finished Goods	CB
5ff253d2-24bd-4a92-941e-4ff839a43d68	cmofmpqxp0000tms4st6fcb8x	SD RUSK 85GM 48PKT	Finished Goods	CB
9c0650b0-28e9-4b51-8c53-5e6c545527f1	cmofmpqxp0000tms4st6fcb8x	SD RUSK DRY FRUIT 400GM	Finished Goods	CB
ba75b378-31e3-4f82-910c-cf513b85e09e	cmofmpqxp0000tms4st6fcb8x	SD RUSK MAWA 12 PKT (350G)	Finished Goods	CB
0bbd86cd-dba4-4489-9046-d30cc2e443f0	cmofmpqxp0000tms4st6fcb8x	SD RUSK MAWA 20PKT 350GM	Finished Goods	CB
ef6d62b8-efec-4069-917a-6ca09dfc22a5	cmofmpqxp0000tms4st6fcb8x	SD Suji Elaiche Rusk 350GM	Finished Goods	CB
0e1a3c3d-c117-4e51-82e0-da51a3f9390a	cmofmpqxp0000tms4st6fcb8x	Slizer Machine	&#4; Primary	PCS
7f7fe11b-d1fc-4a00-a4d2-0541e2fdfeaf	cmofmpqxp0000tms4st6fcb8x	SODA	RAW MATERIAL	KG
6e7eecfc-182b-43c2-aa9f-8e012d96039b	cmofmpqxp0000tms4st6fcb8x	SOFT TISSUE PAPER	&#4; Primary	PKT
9aecf99f-dcb8-48ac-9477-264cfacd1e47	cmofmpqxp0000tms4st6fcb8x	SOUNF	RAW MATERIAL	KG
1df5c0d7-2ec1-4f78-87f5-313708ae8a13	cmofmpqxp0000tms4st6fcb8x	SPIRAL MIXTURE	&#4; Primary	PCS
e86ae1d2-7a76-4fb9-8819-1d45e39bbd9a	cmofmpqxp0000tms4st6fcb8x	STRAWBERRY ESSENCE	RAW MATERIAL	ML
0b6849c3-fbb2-4a0d-bca3-73c82aa9be77	cmofmpqxp0000tms4st6fcb8x	SUGER	RAW MATERIAL	KG
a39e230e-b0d0-4241-b7a7-486ff2bfdfa3	cmofmpqxp0000tms4st6fcb8x	SUGER PISI	RAW MATERIAL	KG
99c58854-00d1-4795-93a8-dc1e9ddf3f96	cmofmpqxp0000tms4st6fcb8x	SUJI	RAW MATERIAL	KG
5c7336c0-ebba-4c1f-8058-ab5cad9ab29f	cmofmpqxp0000tms4st6fcb8x	SUPRA GHI (REPLACEMENT RATH)	RAW MATERIAL	KG
19339ee0-944f-43a4-9ee9-2a1d5c189b7c	cmofmpqxp0000tms4st6fcb8x	SUPRA LITE	RAW MATERIAL	KG
1ae249e9-773c-471d-85d3-779e9b30a004	cmofmpqxp0000tms4st6fcb8x	SUPRA LITE (BISCUITS)	RAW MATERIAL	KG
72ad1bbe-eb7d-4b55-a9bd-9f680cbd1c32	cmofmpqxp0000tms4st6fcb8x	Supra Magic (Sachhe)	RAW MATERIAL	KG
6b981588-cfce-480f-9133-6a32f55eec78	cmofmpqxp0000tms4st6fcb8x	SWEAT HEART KJ	Finished Goods	PKT
7f45e46f-77b2-419f-af8d-624e5e30c618	cmofmpqxp0000tms4st6fcb8x	Sweet Almond Essence	RAW MATERIAL	ML
8bac098b-7a92-4910-b2c8-d746f1eb72ff	cmofmpqxp0000tms4st6fcb8x	TIE	Finished Goods	PKT
2fc0636c-d471-4859-b049-3fcf2cc8ff0d	cmofmpqxp0000tms4st6fcb8x	Til ( Hulled Sesame Seed )	RAW MATERIAL	KG
7a5f638c-0a07-4011-94fe-ebb45ad35b8d	cmofmpqxp0000tms4st6fcb8x	TOWER GHI (SACHHE)	RAW MATERIAL	KG
fa1eaef8-05c1-4cc2-a330-b81b89b031ce	cmofmpqxp0000tms4st6fcb8x	TOWER IMPROVER	RAW MATERIAL	KG
47a52c72-8805-435d-b0da-f28749307846	cmofmpqxp0000tms4st6fcb8x	TRANSPARENT TAPE 1*65MTR	PACKAGING 18%	MTR
41f84b3d-be4e-43da-88c9-a61a493dfddf	cmofmpqxp0000tms4st6fcb8x	TRANSPARENT TAPE 2.5 INCH	PACKAGING 18%	PCS
f0a2dbc9-25b2-4aad-9510-3041cc6ed36e	cmofmpqxp0000tms4st6fcb8x	TRANSPARENT TAPE 72MM*130 MTR 3INCH	PACKAGING 18%	MTR
9c3c2e59-5226-48f9-85ee-3667df4a5521	cmofmpqxp0000tms4st6fcb8x	T-SHIRT	&#4; Primary	PCS
66618b8a-143a-4c63-8591-62be21c97e3e	cmofmpqxp0000tms4st6fcb8x	UMBRELLA	Finished Goods	PCS
83f8e732-8624-4295-bfb3-a06b6e7fcdd0	cmofmpqxp0000tms4st6fcb8x	VANASPATI ANCHAL GHI	RAW MATERIAL	TIN
a473875c-b84b-4328-b83c-fe12cfed9919	cmofmpqxp0000tms4st6fcb8x	Vanaspati  ( Ans Puff)	RAW MATERIAL	KG
23578186-2bd7-4610-94f9-2129d22135ea	cmofmpqxp0000tms4st6fcb8x	VANASPATI DHRU BLUE B RUSK(BISCUITS)	RAW MATERIAL	KG
b7af2112-4f45-4050-ab1a-4cc96bf5e5b3	cmofmpqxp0000tms4st6fcb8x	VANASPATI DHRUVPUFF GHI(Jeera Khari)	RAW MATERIAL	KG
26a6bef1-d521-4fa1-97ef-fc5d7b62809d	cmofmpqxp0000tms4st6fcb8x	VANASPATI GHI	RAW MATERIAL	KG
4ed8511e-1622-47a2-a23b-f9a017bc289a	cmofmpqxp0000tms4st6fcb8x	VANASPATI RATH TIN 15KG	RAW MATERIAL	TIN
ea26fcdf-8eab-4101-a7de-6a977377b46a	cmofmpqxp0000tms4st6fcb8x	Vanaspati Rath Tin (MLK, MAWA,80GM GATTU &amp; JEERA)	RAW MATERIAL	KG
ca268164-74cd-40bc-a226-709cfa8e4e74	cmofmpqxp0000tms4st6fcb8x	Vanilla Essence	RAW MATERIAL	ML
1df450f5-e991-4d7e-8bb4-d4683810dbcb	cmofmpqxp0000tms4st6fcb8x	YEAST	RAW MATERIAL	KG
\.


--
-- Data for Name: StockUnitCache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockUnitCache" (id, "companyId", name, symbol) FROM stdin;
6f69022d-8d3b-421a-ab56-baa343649946	cmofl3ut6000hmjdmwqd3dziu	BAG	BAG
9477a838-2f3d-490b-90a6-81c75473eef2	cmofl3ut6000hmjdmwqd3dziu	kg.	kg.
bb2caf9c-d736-4171-98b6-31121fc9f444	cmofl3ut6000hmjdmwqd3dziu	M.T.	M.T.
675d0cc1-f288-4887-9ad7-93acabc64bf4	cmofmpqxp0000tms4st6fcb8x	BAG	BAG
e4cd7535-f669-45f3-a81f-f54fa48ff4d3	cmofmpqxp0000tms4st6fcb8x	BOTTEL	BOTTEL
42feb6f1-c907-4599-9f3d-d8dd655d5183	cmofmpqxp0000tms4st6fcb8x	CB	CB
337dbb9d-8d50-4d9d-a1ba-1e59918a116d	cmofmpqxp0000tms4st6fcb8x	DIBBI	DIBBI
0a728d1d-f1f6-4258-827b-c9106ff54dad	cmofmpqxp0000tms4st6fcb8x	GM	GM
aa6fcfce-3443-4e23-ae07-ad9b72c338b4	cmofmpqxp0000tms4st6fcb8x	JHOLA	JHOLA
876c7658-8002-40b3-a1a2-e002a9755aa6	cmofmpqxp0000tms4st6fcb8x	KG	KG
6d4b96de-b1a3-4e5a-91bc-26b5d8dc3988	cmofmpqxp0000tms4st6fcb8x	LTR	LTR
84fa05c0-2982-4922-8027-6cc05a2449fc	cmofmpqxp0000tms4st6fcb8x	ML	ML
2290b339-dfdc-4300-9ce5-0abb4aa9eafa	cmofmpqxp0000tms4st6fcb8x	MTR	MTR
cbe82d91-7033-4510-9c45-af38a435af80	cmofmpqxp0000tms4st6fcb8x	PCS	PCS
ee887a88-a9d3-46bb-94fc-b3e307aa395a	cmofmpqxp0000tms4st6fcb8x	PKT	PKT
2db64c78-d57e-4151-8fa2-8d9aa38cf8e6	cmofmpqxp0000tms4st6fcb8x	TIN	TIN
\.


--
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."User" (id, name, email, "passwordHash", role, "enterpriseName", "createdAt") FROM stdin;
cmofkkib70000rne8jx31rj7u	Admin	admin@tallysync.com	$2a$10$1vmTQNtsRzfVk/n71iN6C.Zw7//GL0aGDbVc9VRiAWhYrGvwB8WbW	ADMIN	\N	2026-04-26 09:32:07.987
cmofkkieo0001rne81vkjzhxw	Sharma Group	sharma@enterprise.com	$2a$10$SRu0yJjuertuUoe4nxk0D.UgtG53rgojJFjQUryJl3D95yqJklUgi	COMPANY	Sharma Group	2026-04-26 09:32:08.112
cmofkkiex0002rne8wpcgvdt9	Raj Group	raj@enterprise.com	$2a$10$SRu0yJjuertuUoe4nxk0D.UgtG53rgojJFjQUryJl3D95yqJklUgi	COMPANY	Raj Group	2026-04-26 09:32:08.121
cmofknbkg0000mjdmrvgaqt31	anurag	anurag@gmail.com	$2a$10$Ax0bAniuWQkysNOV/zRXJ.WE1u6VRo7vRGWtNw5SjbTApLZioyzIe	COMPANY	Anurag Agencies	2026-04-26 09:34:19.216
\.


--
-- Data for Name: UserCompany; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."UserCompany" (id, "userId", "companyId", "isDefault", "createdAt") FROM stdin;
cmofkkify0004rne84wf5qykx	cmofkkieo0001rne81vkjzhxw	c1	t	2026-04-26 09:32:08.158
cmofkkigc0006rne8i52l0bjz	cmofkkieo0001rne81vkjzhxw	c2	f	2026-04-26 09:32:08.172
cmofkkigo0008rne8oehp92ul	cmofkkiex0002rne8wpcgvdt9	c3	t	2026-04-26 09:32:08.184
cmofkp2b70003mjdmpr7cqss0	cmofknbkg0000mjdmrvgaqt31	cmofkp2az0001mjdm3pw0n2wo	f	2026-04-26 09:35:40.531
cmofl3utf000jmjdm57n1nl5i	cmofknbkg0000mjdmrvgaqt31	cmofl3ut6000hmjdmwqd3dziu	f	2026-04-26 09:47:10.659
cmofmpqxx0002tms4bls4uvjk	cmofknbkg0000mjdmrvgaqt31	cmofmpqxp0000tms4st6fcb8x	t	2026-04-26 10:32:11.685
\.


--
-- Name: Bill Bill_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Bill"
    ADD CONSTRAINT "Bill_pkey" PRIMARY KEY (id);


--
-- Name: CompanyFeature CompanyFeature_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CompanyFeature"
    ADD CONSTRAINT "CompanyFeature_pkey" PRIMARY KEY (id);


--
-- Name: Company Company_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Company"
    ADD CONSTRAINT "Company_pkey" PRIMARY KEY (id);


--
-- Name: GodownCache GodownCache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."GodownCache"
    ADD CONSTRAINT "GodownCache_pkey" PRIMARY KEY (id);


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
-- Name: UserCompany UserCompany_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UserCompany"
    ADD CONSTRAINT "UserCompany_pkey" PRIMARY KEY (id);


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- Name: CompanyFeature_companyId_feature_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "CompanyFeature_companyId_feature_key" ON public."CompanyFeature" USING btree ("companyId", feature);


--
-- Name: GodownCache_companyId_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "GodownCache_companyId_name_key" ON public."GodownCache" USING btree ("companyId", name);


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
-- Name: UserCompany_userId_companyId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "UserCompany_userId_companyId_key" ON public."UserCompany" USING btree ("userId", "companyId");


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
-- Name: CompanyFeature CompanyFeature_companyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CompanyFeature"
    ADD CONSTRAINT "CompanyFeature_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES public."Company"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: GodownCache GodownCache_companyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."GodownCache"
    ADD CONSTRAINT "GodownCache_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES public."Company"(id) ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: UserCompany UserCompany_companyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UserCompany"
    ADD CONSTRAINT "UserCompany_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES public."Company"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: UserCompany UserCompany_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UserCompany"
    ADD CONSTRAINT "UserCompany_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict 4h2RaokzEl0Y0zLUJPOSW8cVUKDbadAiharQqMb3oWlLALyqaYtIUMHdkbWFUfv

