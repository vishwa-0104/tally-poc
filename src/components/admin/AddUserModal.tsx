import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'react-hot-toast'
import { Modal } from '@/components/ui/Modal'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { newUserSchema, type NewUserInput } from '@/lib/validators'
import { api } from '@/lib/api'

interface AddUserModalProps {
  open: boolean
  onClose: () => void
  onCreated: () => void
}

export function AddUserModal({ open, onClose, onCreated }: AddUserModalProps) {
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<NewUserInput>({
    resolver: zodResolver(newUserSchema),
  })

  const onSubmit = async (data: NewUserInput) => {
    try {
      await api.post('/users', data)
      toast.success(`User "${data.name}" created`)
      reset()
      onCreated()
      onClose()
    } catch {
      toast.error('Failed to create user')
    }
  }

  const handleClose = () => {
    reset()
    onClose()
  }

  return (
    <Modal
      open={open}
      onClose={handleClose}
      title="Add Enterprise User"
      subtitle="Create a login account for an enterprise user"
      footer={
        <>
          <Button variant="outline" onClick={handleClose} disabled={isSubmitting}>Cancel</Button>
          <Button variant="primary" onClick={handleSubmit(onSubmit)} loading={isSubmitting}>
            Create User
          </Button>
        </>
      }
    >
      <Input
        {...register('name')}
        label="Full name"
        placeholder="Rajesh Sharma"
        error={errors.name?.message}
      />
      <Input
        {...register('enterpriseName')}
        label="Enterprise name (display label)"
        placeholder="Sharma Group"
        error={errors.enterpriseName?.message}
      />
      <Input
        {...register('email')}
        label="Login email"
        type="email"
        placeholder="sharma@enterprise.com"
        error={errors.email?.message}
      />
      <Input
        {...register('password')}
        label="Initial password"
        type="password"
        placeholder="Min. 8 characters"
        error={errors.password?.message}
      />
    </Modal>
  )
}
