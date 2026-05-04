import { useExtensionStatus } from '@/hooks'

const STORE_URL = import.meta.env.VITE_EXTENSION_STORE_URL as string | undefined

export function ExtensionStatus() {
  const { connected } = useExtensionStatus()

  if (!connected) {
    return (
      <a
        href={STORE_URL || '#'}
        target="_blank"
        rel="noopener noreferrer"
        onClick={!STORE_URL ? (e) => e.preventDefault() : undefined}
        className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-medium bg-amber-50 text-amber-700 hover:bg-amber-100 transition-colors cursor-pointer"
        title="Install the Chrome extension to sync with Tally"
      >
        <span className="w-2 h-2 rounded-full bg-amber-500" />
        Add Extension
      </a>
    )
  }

  return (
    <div
      className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-medium bg-emerald-50 text-emerald-700"
      role="status"
      aria-live="polite"
    >
      <span className="w-2 h-2 rounded-full bg-emerald-500" />
      Connected
    </div>
  )
}
