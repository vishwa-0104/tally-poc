import { Link } from 'react-router-dom'
import invoiceSyncSvg from '../assets/sync-invoice-logo-blue.svg'





export default function PrivacyPolicy() {
  return (
    <div className="min-h-screen bg-gray-50 text-white">
      {/* Header */}
      {/* <header className="sticky top-0 z-50 bg-gray-900/95 backdrop-blur border-b border-white/10">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <Link to="/" className="flex items-center gap-2.5">
            <div className="w-8 h-8 bg-teal-500 rounded-lg flex items-center justify-center flex-shrink-0">
              <svg className="w-4.5 h-4.5 stroke-white fill-none stroke-2" viewBox="0 0 24 24" width="18" height="18">
                <path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
            </div>
            <span className="text-base font-bold text-white">Tally Bill Sync</span>
          </Link>
          <Link
            to="/login"
            className="px-4 py-2 text-sm font-semibold text-teal-400 border border-teal-500/50 rounded-lg hover:bg-teal-500/10 transition-colors"
          >
            Sign In
          </Link>
        </div>
      </header> */}
     <header className="sticky top-0 z-50 bg-gray-100 backdrop-blur border-b border-white/10">
        <div className="max-w-6xl mx-auto px-6 h-[80px] flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-32 h-8  rounded-lg flex items-center justify-center flex-shrink-0">
              
              <img className='w-2xl h-4.5 stroke-white fill-none stroke-2' src={invoiceSyncSvg} alt="InvoiceSync" />
              
              {/* <svg className="w-4.5 h-4.5 stroke-white fill-none stroke-2" viewBox="0 0 24 24" width="18" height="18">
                <path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg> */}
            </div>
            {/* <span className="text-base font-bold text-white">Tally Bill Sync</span> */}
          </div>
          <Link
            to="/login"
            className="px-4 py-2 sm:w-auto bg-blue-500 hover:bg-blue-600 text-white font-bold rounded-md transition-colors text-sm shadow-lg shadow-blue-500/25"
          >
            
            Sign In
          </Link>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-3xl mx-auto px-6 py-16">
        <div className="text-gray-700">
        <h1 className="text-3xl font-extrabold text-gray-700 mb-2">Privacy Policy</h1>
        <p className="text-sm text-gray-500 mb-10">Effective Date: April 29, 2026</p>
        </div>

        <div className="prose-custom space-y-10 text-gray-500 text-sm leading-relaxed">

          <section>
            <h2>1. Introduction</h2>
            <p>
              Welcome to <span className="text-teal-400">https://www.invoiceSync.nextax.in</span> ("we," "us," or "our"), a product of <strong className="text-gray-700">Nextax Technologies Private Limited</strong>. We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our website and services.
            </p>
            <p className="mt-3">By using our website, you consent to the data practices described in this policy.</p>
          </section>

          <section>
            <h2>2. Information We Collect</h2>
            <h3>2.1 Information You Provide</h3>
            <p>We may collect the following information that you voluntarily provide:</p>
            <ul>
              <li><strong className="text-gray-700">Personal Information:</strong> Name, email address, phone number, postal address, and other contact details</li>
              <li><strong className="text-gray-700">Account Information:</strong> Username, password, and account preferences when you register for an account</li>
              <li><strong className="text-gray-700">Documents:</strong> Bills, invoices, receipts, and other documents you upload for parsing</li>
              <li><strong className="text-gray-700">Communication Data:</strong> Information you provide when contacting us via email, forms, or other channels</li>
            </ul>
            <h3>2.2 User Generated Data</h3>
            <p>Data, documents, or content you upload or process through our platform.</p>
          </section>

          <section>
            <h2>3. How We Use Your Information</h2>
            <p>We use your information for the following purposes:</p>
            <ul>
              <li><strong className="text-gray-700">Service Delivery:</strong> To provide, maintain, and improve our services</li>
              <li><strong className="text-gray-700">Bill Parsing:</strong> To process your documents using AI technology for data extraction</li>
              <li><strong className="text-gray-700">Communication:</strong> To respond to your inquiries, send updates, and provide customer support</li>
              <li><strong className="text-gray-700">Analytics:</strong> To understand how you use our website and improve user experience</li>
              <li><strong className="text-gray-700">Security:</strong> To detect, prevent, and address technical issues and security threats</li>
              <li><strong className="text-gray-700">Legal Compliance:</strong> To comply with applicable laws</li>
            </ul>
          </section>

          <section>
            <h2>4. AI Processing and Bill Parsing</h2>
            <h3>4.1 Use of AI</h3>
            <p>
              Our platform utilises various AI models such as Anthropic's Claude AI, ChatGPT, and Gemini AI for processing and analysing documents, specifically for bill parsing services. When you submit a document for parsing:
            </p>
            <ol>
              <li>Your document is transmitted to these AI models for processing</li>
              <li>The AI extracts relevant information (e.g., vendor name, amount, date, line items)</li>
              <li>The parsed results are returned to the bill sync section of your user dashboard</li>
            </ol>

            <h3>4.2 Data Handling for AI Processing</h3>
            <ul>
              <li><strong className="text-gray-700">Transmission to AI Services:</strong> Your documents are sent to the mentioned AI services for processing</li>
              <li><strong className="text-gray-700">Data Handling:</strong> These AI models process this data in accordance with their own Privacy Policies. We recommend reviewing their documentation to understand their data handling practices</li>
              <li><strong className="text-gray-700">We Do Not Store Parsed Data:</strong> After processing is complete and results are returned, we do not retain, store, or archive your parsed bill information in our database</li>
              <li><strong className="text-gray-700">Temporary Processing:</strong> Any data processed through our servers is held only temporarily for the duration of the AI request</li>
            </ul>

            <h3>4.3 Data Retention</h3>
            <div className="overflow-x-auto mt-3">
              <table>
                <thead>
                  <tr>
                    <th>Data Type</th>
                    <th>Retention Period</th>
                  </tr>
                </thead>
                <tbody>
                  <tr><td>Parsed Bill Results</td><td>Not stored in our database</td></tr>
                  <tr><td>Original Documents</td><td>Deleted immediately after AI processing</td></tr>
                  <tr><td>Server Logs</td><td>10 days</td></tr>
                  <tr><td>Account Data</td><td>Duration of your account + 0 days post-deletion</td></tr>
                </tbody>
              </table>
            </div>
          </section>

          <section>
            <h2>5. Your Rights</h2>
            <p>Depending on applicable laws, you may have the right to:</p>
            <ul>
              <li>Access your personal data</li>
              <li>Correct or update your information</li>
              <li>Request deletion of your data</li>
              <li>Withdraw consent where applicable</li>
            </ul>
            <p className="mt-3">To exercise these rights, please contact us using the form linked in Section 12.</p>
          </section>

          <section>
            <h2>6. Information Sharing and Disclosure</h2>
            <p>We do not sell, trade, or rent your personal information to third parties. We may share your information in the following circumstances:</p>

            <h3>Service Providers</h3>
            <p>We may share your information with trusted third-party service providers who assist us in:</p>
            <ul>
              <li>Website hosting and maintenance</li>
              <li>Analytics and data processing</li>
              <li>AI models (for bill parsing only)</li>
            </ul>

            <h3>Legal Requirements</h3>
            <p>We may disclose your information if required by law, court order, or governmental regulation, or if we believe disclosure is necessary to:</p>
            <ul>
              <li>Protect our rights, privacy, safety, or property</li>
              <li>Comply with legal process or governmental requests</li>
              <li>Prevent or detect illegal activities</li>
            </ul>

            <h3>Business Transfers</h3>
            <p>In the event of a merger, acquisition, or sale of our company, your information may be transferred as part of that transaction.</p>
          </section>

          <section>
            <h2>7. Cookies and Tracking Technologies</h2>
            <p>At present, we do not use cookies or similar tracking technologies.</p>
          </section>

          <section>
            <h2>8. Data Security</h2>
            <p>
              We take appropriate security measures to protect against any unauthorised access to or unauthorised alteration, disclosure or destruction of data.
            </p>
          </section>

          <section>
            <h2>9. Third-Party Links</h2>
            <p>
              Our website may contain links to third-party websites, services, or applications. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies before providing any personal information.
            </p>
          </section>

          <section>
            <h2>10. Changes to This Privacy Policy</h2>
            <p>
              We may update this privacy policy to reflect changes to our information practices. If we make any material changes we will notify you by email or by posting a notice on our website prior to the change becoming effective. We encourage you to periodically review this page for the latest information on our privacy practices.
            </p>
          </section>

          <p className="text-gray-600 text-xs pt-4 border-t border-white/5">
            This Privacy Policy was last updated on April 29, 2026.
          </p>
        </div>
      </main>

      {/* Footer */}
      <footer className="py-8 px-6 bg-gray-50 border-t border-white/5 mt-8">
        <div className="max-w-5xl mx-auto flex items-center justify-center text-xs text-gray-600">
          <Link to="/privacy-policy" className="hover:text-teal-400 transition-colors">Privacy Policy</Link>
        </div>
      </footer>
    </div>
  )
}
