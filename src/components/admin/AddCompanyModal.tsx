import { useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'react-hot-toast'
import { Modal } from '@/components/ui/Modal'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { newCompanySchema, type NewCompanyInput } from '@/lib/validators'
import { useCompanyStore } from '@/store'
import { api } from '@/lib/api'

interface EnterpriseUser { id: string; name: string; email: string; enterpriseName?: string }

interface AddCompanyModalProps {
  open: boolean
  onClose: () => void
}

export function AddCompanyModal({ open, onClose }: AddCompanyModalProps) {
  const addCompany = useCompanyStore((s) => s.addCompany)
  const [users, setUsers]       = useState<EnterpriseUser[]>([])
  const [selectedUser, setSelectedUser] = useState('')

  useEffect(() => {
    if (!open) return
    api.get<EnterpriseUser[]>('/users').then(({ data }) => setUsers(data)).catch(() => {})
  }, [open])

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<NewCompanyInput>({
    resolver: zodResolver(newCompanySchema),
    defaultValues: { port: 9000 },
  })

  const onSubmit = async (data: NewCompanyInput) => {
    try {
      await addCompany({ name: data.name, gstin: data.gstin, port: data.port, userId: selectedUser || undefined })
      toast.success(`"${data.name}" added successfully`)
      reset()
      setSelectedUser('')
      onClose()
    } catch {
      toast.error('Failed to create company')
    }
  }

  const handleClose = () => {
    reset()
    setSelectedUser('')
    onClose()
  }

  return (
    <Modal
      open={open}
      onClose={handleClose}
      title="Add Company"
      subtitle="Create a new Tally company and optionally assign it to an enterprise user"
      footer={
        <>
          <Button variant="outline" onClick={handleClose} disabled={isSubmitting}>Cancel</Button>
          <Button
            variant="primary"
            onClick={handleSubmit(onSubmit)}
            loading={isSubmitting}
          >
            Create Company
          </Button>
        </>
      }
    >
      <Input
        {...register('name')}
        label="Company name (must exactly match Tally)"
        placeholder="Sharma Groceries Pvt Ltd"
        error={errors.name?.message}
      />
      <Input
        {...register('gstin')}
        label="GSTIN"
        placeholder="27AABCS1429B1Z1"
        className="font-mono"
        error={errors.gstin?.message}
      />
      <Input
        {...register('port', { valueAsNumber: true })}
        label="Tally port"
        type="number"
        error={errors.port?.message}
      />
      <div className="flex flex-col gap-1">
        <label className="text-xs font-medium text-gray-700">
          Enterprise user <span className="text-gray-400">(optional)</span>
        </label>
        <select
          value={selectedUser}
          onChange={(e) => setSelectedUser(e.target.value)}
          className="input-base text-sm"
        >
          <option value="">— Unassigned —</option>
          {users.map((u) => (
            <option key={u.id} value={u.id}>
              {u.enterpriseName ? `${u.enterpriseName} — ` : ''}{u.name} ({u.email})
            </option>
          ))}
        </select>
        <p className="text-[10px] text-gray-400">
          This company will be linked to the selected enterprise user. You can change this later from the Users page.
        </p>
      </div>
    </Modal>
  )
}
