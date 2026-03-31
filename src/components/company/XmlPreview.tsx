import { colorizeXml } from '@/lib/utils'

interface XmlPreviewProps {
  xml: string
}

export function XmlPreview({ xml }: XmlPreviewProps) {
  return (
    <div className="mt-6">
      <h3 className="text-sm font-bold text-gray-800 mb-2">Generated Tally XML</h3>
      <div
        className="bg-[#0D1117] rounded-xl p-5 font-mono text-[11.5px] leading-relaxed overflow-x-auto"
        aria-label="Generated Tally XML"
        role="region"
        dangerouslySetInnerHTML={{ __html: colorizeXml(xml) }}
      />
    </div>
  )
}
