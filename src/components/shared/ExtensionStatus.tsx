import { useExtensionStatus } from '@/hooks'

export function ExtensionStatus() {
  const { connected } = useExtensionStatus()
  return (
    <div
      className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-medium ${
        connected ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'
      }`}
      role="status"
      aria-live="polite"
    >
      <span className={`w-2 h-2 rounded-full ${connected ? 'bg-emerald-500' : 'bg-amber-500'}`} />
      {connected ? 'Connected' : 'Connection Required'}
    </div>
  )
}
