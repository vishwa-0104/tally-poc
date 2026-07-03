import { create } from 'zustand'

// Bridges useDaybookNotifications (mounted once at CompanyLayout, runs
// regardless of which page is visible) to Dashboard.tsx (a child route) —
// the WS listener has no direct way to tell the Dashboard "new data just
// landed in the DB, refresh yourself" other than through shared state like
// this. lastUpdated is a per-company timestamp bumped after a notify-
// triggered fetch+persist completes; Dashboard watches it and re-runs its
// DB-only read when it changes for the company currently being viewed.
interface DaybookSyncStore {
  lastUpdated: Record<string, number>
  markUpdated: (companyId: string) => void
}

export const useDaybookSyncStore = create<DaybookSyncStore>((set) => ({
  lastUpdated: {},
  markUpdated: (companyId) =>
    set((state) => ({ lastUpdated: { ...state.lastUpdated, [companyId]: Date.now() } })),
}))
