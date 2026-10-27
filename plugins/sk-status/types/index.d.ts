export type Step = 'gaps' | 'spec' | 'design' | 'tasks' | 'apply' | 'verify'

export type ChangeState = {
  id: string
  step: Step
  next: string
  specCount: number
  specPaths: string[]
  design: 'none' | 'file' | 'skipped'
  hasTasks: boolean
  tasksDone: number
  tasksTotal: number
  openQuestions: string[]
  mtimeMs: number
}

export type Artifact = 'proposal' | 'spec' | 'design' | 'tasks'

export type Scan = { hasSk: boolean; changes: ChangeState[] }

declare module 'claude-code' {
  interface PluginState {
    'sk-status': {
      scan: Scan
      sort: 'recent' | 'progress'
      selected: string | null
      viewing: Artifact | null
      confirmArchive: string | null
    }
  }
}
