import React from 'react';

const TermsOfUse: React.FC = () => {
  const effectiveDate = "April 29, 2026";

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      {/* Container */}
      <div className="max-w-4xl mx-auto bg-white shadow-md rounded-lg overflow-hidden print:shadow-none">
        
        {/* Header Section */}
        <div className="bg-slate-800 py-8 px-8 text-white flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold">Terms of Use</h1>
            <p className="mt-2 text-slate-300">Effective Date: {effectiveDate}</p>
          </div>
          <button 
            onClick={handlePrint}
            className="hidden md:block bg-slate-700 hover:bg-slate-600 px-4 py-2 rounded text-sm transition-colors print:hidden"
          >
            Print Version
          </button>
        </div>

        {/* Content Section */}
        <div className="p-8 prose prose-slate max-w-none text-gray-700 leading-relaxed">
          
          <section className="mb-8">
            <h2 className="text-xl font-semibold text-slate-900 border-b pb-2 mb-4">1. Acceptance of Terms</h2>
            <p>
              By accessing and using this website, you accept and agree to be bound by the terms and provision of this agreement. 
              If you do not agree to abide by these terms, please do not use this service.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-slate-900 border-b pb-2 mb-4">2. Description of Service</h2>
            <p>
              This website provides <strong>"bills parsing and document processing services"</strong>. By using our platform, 
              you agree to the following terms and conditions.
            </p>
          </section>

          <section className="mb-8 bg-blue-50 p-6 rounded-lg border-l-4 border-blue-500">
            <h2 className="text-xl font-semibold text-slate-900 mb-4">3. Use of AI</h2>
            <p className="mb-4">
              Our platform utilizes AI technology and Large Language Models (LLM) from <strong>Anthropic Claude, ChatGPT, and Gemini AI</strong> for 
              processing bills. You acknowledge and agree that:
            </p>
            <ul className="list-disc pl-5 space-y-2">
              <li>The AI processing is performed by such AI models.</li>
              <li>The AI is used solely for the purpose of extracting, parsing, and analyzing bill information.</li>
              <li>You grant us permission to transmit your documents to mentioned AI services for processing.</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-slate-900 border-b pb-2 mb-4">4. Data Privacy and Storage</h2>
            <h3 className="text-lg font-medium mt-4 mb-2">Bill Parsing Data</h3>
            <ul className="list-disc pl-5 space-y-2">
              <li>We do not store bill parsing details in our database. All operations are performed in real-time.</li>
              <li>Processed bill data is temporarily transmitted to LLM servers solely for the purpose of AI processing.</li>
              <li>We do not retain, archive, or maintain any copies of your parsed bill information after processing is complete.</li>
            </ul>

            <h3 className="text-lg font-medium mt-6 mb-2">Data Handling by AI Models</h3>
            <p>
              These AI models process bill data in accordance with their own privacy policies. We recommend reviewing the 
              privacy policy webpages of Anthropic, OpenAI, and Google Gemini to understand how your information is handled 
              at the AI processing level.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-slate-900 border-b pb-2 mb-4">5. User Responsibilities</h2>
            <ul className="list-disc pl-5 space-y-2">
              <li>Provide accurate information when using our services.</li>
              <li>Not use our platform for any unlawful purposes.</li>
              <li>Not attempt to reverse engineer, modify, or exploit any component of our service.</li>
              <li>Maintain the confidentiality of your account credentials.</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-slate-900 border-b pb-2 mb-4">6. Intellectual Property</h2>
            <p>
              All content, features, and functionality of this website are owned by us. 
              You retain no ownership rights to any materials processed through our platform.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-slate-900 border-b pb-2 mb-4">7. Disclaimer of Warranties</h2>
            <p className="italic">
              Our services are provided "AS IS" and "AS AVAILABLE" without warranties of any kind, either express or implied.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-slate-900 border-b pb-2 mb-4">8. Limitation of Liability</h2>
            <p className="mb-4">
              To the maximum extent permitted by law, the Company shall not be liable for any indirect, incidental, or 
              consequential damages, including loss of revenue or data.
            </p>
            <div className="bg-gray-100 p-4 rounded text-sm text-gray-600 border border-gray-200">
              The total aggregate liability shall be strictly limited to the total amount of fees actually paid by the user 
              during the twelve (12) months preceding the event giving rise to the claim.
            </div>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-slate-900 border-b pb-2 mb-4">9. Privacy Policy</h2>
            <p>
              Your use of our services is also governed by our Privacy Policy. Please review it to understand our data protection practices.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-slate-900 border-b pb-2 mb-4">10. Modifications to Terms</h2>
            <p>
              We reserve the right to modify these terms at any time. Your continued use of the service constitutes acceptance 
              of the modified terms.
            </p>
          </section>

          <section className="mb-8 text-center bg-slate-50 p-6 rounded-lg border border-slate-200">
            <h2 className="text-xl font-semibold text-slate-900 mb-2">11. Governing Law</h2>
            <p>
              Disputes shall be subject to the exclusive jurisdiction of the 
              competent courts in <strong>Ahmedabad, Gujarat</strong>.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-slate-900 border-b pb-2 mb-4">12. Contact Information</h2>
            <p>If you have questions, please reach out via our contact form:</p>
            <a 
              href="#" 
              className="mt-2 inline-block text-blue-600 hover:underline font-medium"
            >
              Contact Support Form
            </a>
          </section>

          <div className="mt-12 pt-8 border-t text-center text-gray-500 text-sm">
            <p>By using our website, you acknowledge that you have read, understood, and agree to be bound by these Terms of Use.</p>
          </div>
        </div>
      </div>

      {/* Back to Home Button */}
      <div className="max-w-4xl mx-auto mt-6 text-center print:hidden">
        <button 
          onClick={() => window.history.back()}
          className="text-slate-500 hover:text-slate-800 font-medium transition-colors"
        >
          &larr; Back to Dashboard
        </button>
      </div>
    </div>
  );
};

export default TermsOfUse;