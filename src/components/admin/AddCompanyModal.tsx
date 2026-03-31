import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'react-hot-toast'
import { Modal } from '@/components/ui/Modal'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { newCompanySchema, type NewCompanyInput } from '@/lib/validators'
import { useCompanyStore } from '@/store'

interface AddCompanyModalProps {
  open: boolean
  onClose: () => void
}

export function AddCompanyModal({ open, onClose }: AddCompanyModalProps) {
  const addCompany = useCompanyStore((s) => s.addCompany)

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
      await addCompany({ name: data.name, gstin: data.gstin, email: data.email, port: data.port, mapping: null, password: data.password })
      toast.success(`"${data.name}" added successfully`)
      reset()
      onClose()
    } catch {
      toast.error('Failed to create company')
    }
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Add Company"
      subtitle="Create a new company account with its own login credentials"
      footer={
        <>
          <Button variant="outline" onClick={onClose} disabled={isSubmitting}>Cancel</Button>
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
        {...register('email')}
        label="Login email for this company"
        type="email"
        placeholder="accounts@company.com"
        error={errors.email?.message}
      />
      <Input
        {...register('password')}
        label="Initial password"
        type="password"
        placeholder="Min. 8 characters"
        error={errors.password?.message}
      />
      <Input
        {...register('port', { valueAsNumber: true })}
        label="Tally port"
        type="number"
        error={errors.port?.message}
      />
    </Modal>
  )
}
