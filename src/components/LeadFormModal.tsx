import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { CheckCircle } from 'lucide-react'
import { Modal } from '@/components/ui/Modal'
import { Button } from '@/components/ui/Button'
import { toast } from 'react-hot-toast'

const schema = z.object({
  companyName: z.string().min(2, 'Company name is required'),
  phone:       z.string().min(10, 'Enter a valid phone number'),
  email:       z.string().email('Enter a valid email address'),
  description: z.string().optional(),
})

type FormValues = z.infer<typeof schema>

interface Props {
  open: boolean
  onClose: () => void
}

export function LeadFormModal({ open, onClose }: Props) {
  const [submitted, setSubmitted] = useState(false)

  const { register, handleSubmit, reset, formState: { errors, isSubmitting } } = useForm<FormValues>({
    resolver: zodResolver(schema),
  })

  const handleClose = () => {
    reset()
    setSubmitted(false)
    onClose()
  }

  const onSubmit = async (data: FormValues) => {
    try {
      const res = await fetch('/api/leads', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      })
      if (!res.ok) throw new Error('Server error')
      setSubmitted(true)
      setTimeout(handleClose, 2500)
    } catch {
      toast.error('Failed to submit. Please try again.')
    }
  }

  return (
    <Modal
      open={open}
      onClose={handleClose}
      title="Get Started for Free"
      subtitle="Tell us about your business and we'll reach out shortly."
      footer={
        !submitted ? (
          <>
            <Button variant="outline" onClick={handleClose} disabled={isSubmitting}>Cancel</Button>
            <Button variant="primary" loading={isSubmitting} onClick={handleSubmit(onSubmit)}>Submit</Button>
          </>
        ) : undefined
      }
    >
      {submitted ? (
        <div className="flex flex-col items-center gap-3 py-6 text-center">
          <CheckCircle className="w-12 h-12 text-teal-500" />
          <p className="text-lg font-semibold text-gray-900">Thank you!</p>
          <p className="text-sm text-gray-500">We've received your details and will be in touch soon.</p>
        </div>
      ) : (
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Company Name <span className="text-red-500">*</span></label>
            <input
              {...register('companyName')}
              placeholder="Sharma Enterprises Pvt Ltd"
              className="input-base w-full"
            />
            {errors.companyName && <p className="input-error">{errors.companyName.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Phone Number <span className="text-red-500">*</span></label>
            <input
              {...register('phone')}
              type="tel"
              placeholder="+91 98765 43210"
              className="input-base w-full"
            />
            {errors.phone && <p className="input-error">{errors.phone.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email Address <span className="text-red-500">*</span></label>
            <input
              {...register('email')}
              type="email"
              placeholder="you@company.com"
              className="input-base w-full"
            />
            {errors.email && <p className="input-error">{errors.email.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
            <textarea
              {...register('description')}
              rows={3}
              placeholder="Tell us about your business or any specific requirements..."
              className="input-base w-full resize-none"
            />
          </div>
        </div>
      )}
    </Modal>
  )
}
