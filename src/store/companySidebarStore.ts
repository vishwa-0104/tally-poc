import { create } from 'zustand'

// Shared between CompanyLayout (owns the sidebar) and CompanyPageHeader
// (renders the mobile hamburger button inline with the page title) so the
// button lives in the header's own flex row instead of floating separately.
interface CompanySidebarStore {
  collapsed: boolean
  isOverlay: boolean
  setCollapsed: (v: boolean) => void
  setIsOverlay: (v: boolean) => void
}

export const useCompanySidebarStore = create<CompanySidebarStore>((set) => ({
  collapsed: true,
  isOverlay: false,
  setCollapsed: (v) => set({ collapsed: v }),
  setIsOverlay: (v) => set({ isOverlay: v }),
}))
