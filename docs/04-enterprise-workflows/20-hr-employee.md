# HR và Employee Management Workflows

## Overview

Tự động hóa HR processes giúp:
- Giảm manual work cho HR team
- Cải thiện employee experience
- Đảm bảo compliance
- Streamline onboarding/offboarding

---

## Workflow 1: Employee Onboarding

### Use Case
Tự động hóa quy trình onboarding cho nhân viên mới.

### Process Flow
```
HR Creates Employee → Create Accounts → Send Welcome → 
Assign Equipment → Schedule Orientation → Setup Payroll
```

### Implementation

#### Step 1: Trigger từ HR system
```javascript
const employee = $input.first().json;

// Validate required fields
const required = ['name', 'email', 'department', 'start_date', 'manager'];
const missing = required.filter(field => !employee[field]);

if (missing.length > 0) {
  throw new Error(`Missing fields: ${missing.join(', ')}`);
}

return [{
  json: {
    ...employee,
    onboarding_status: 'initiated',
    created_at: new Date().toISOString()
  }
}];
```

#### Step 2: Create Accounts
```
Parallel branches:
├── Create Google Workspace Account
├── Create Slack Account
├── Create GitHub/GitLab Account
├── Create Jira Account
└── Create Internal System Account
```

**Google Workspace:**
```javascript
const employee = $input.first().json;

return [{
  json: {
    primaryEmail: employee.email,
    name: {
      givenName: employee.name.split(' ')[0],
      familyName: employee.name.split(' ').slice(1).join(' ')
    },
    password: generateSecurePassword(),
    orgUnitPath: '/' + employee.department,
    recoveryEmail: employee.personal_email
  }
}];

function generateSecurePassword() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%';
  let password = '';
  for (let i = 0; i < 16; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}
```

#### Step 3: Send Welcome Package
```javascript
const employee = $input.first().json;
const start_date = new Date(employee.start_date);
const start_date_formatted = start_date.toLocaleDateString('vi-VN', {
  weekday: 'long',
  year: 'numeric',
  month: 'long',
  day: 'numeric'
});

const welcomeEmail = {
  to: employee.email,
  cc: employee.manager,
  subject: `Welcome to the Team, ${employee.name.split(' ')[0]}! 🎉`,
  body: `
Dear ${employee.name},

We're excited to have you join our team!

📅 Start Date: ${start_date_formatted}
🕐 Time: 9:00 AM
📍 Location: Office / Remote

Your accounts have been created:
- Email: ${employee.email}
- Slack: ${employee.email}
- Temporary password: See separate secure message

First Day Agenda:
9:00 AM - Welcome meeting with HR
10:00 AM - IT setup
11:00 AM - Team introductions
12:00 PM - Lunch with the team
2:00 PM - Role overview with manager

What to Bring:
- ID documents
- Bank information for payroll
- Emergency contact details

If you have any questions before your start date, please don't hesitate to reach out.

Welcome aboard! 🚀

Best regards,
HR Team
`
};

return [{ json: welcomeEmail }];
```

#### Step 4: Assign Equipment
```javascript
const employee = $input.first().json;

// Equipment based on role
const equipment = {
  standard: ['Laptop', 'Monitor', 'Keyboard', 'Mouse', 'Headset'],
  developer: ['Laptop', 'Monitor', 'Keyboard', 'Mouse', 'Headset', 'Docking Station'],
  designer: ['Laptop', 'Monitor', 'Keyboard', 'Mouse', 'Headset', 'Drawing Tablet']
};

const roleEquipment = equipment[employee.role] || equipment.standard;

return [{
  json: {
    employee: employee.name,
    equipment: roleEquipment,
    delivery_address: employee.address,
    delivery_date: new Date(employee.start_date - 3*24*60*60*1000).toISOString()
  }
}];
```

---

## Workflow 2: Leave Request Approval

### Use Case
Tự động hóa quy trình xin nghỉ phép.

### Process Flow
```
Employee Request → Validate Balance → Manager Approval → 
HR Notification → Update Balance → Calendar Update
```

### Implementation

#### Validate Leave Balance
```javascript
const request = $input.first().json;
const balance = $('Get Employee Leave Balance').first().json;

const validation = {
  valid: true,
  messages: []
};

// Check sufficient balance
if (request.days > balance.remaining) {
  validation.valid = false;
  validation.messages.push('Insufficient leave balance');
}

// Check notice period
const today = new Date();
const startDate = new Date(request.start_date);
const daysNotice = (startDate - today) / (1000*60*60*24);

if (daysNotice < 2) {
  validation.messages.push('Short notice period');
}

// Check overlapping requests
const overlapping = $('Get Pending Requests').all()
  .some(r => 
    r.json.employee_id === request.employee_id &&
    r.json.status === 'pending' &&
    (r.json.start_date <= request.end_date) &&
    (r.json.end_date >= request.start_date)
  );

if (overlapping) {
  validation.valid = false;
  validation.messages.push('Overlapping leave request');
}

return [{
  json: {
    ...request,
    validation,
    remaining_after: balance.remaining - request.days
  }
}];
```

#### Manager Approval Routing
```javascript
const request = $input.first().json;
const orgChart = $('Get Org Chart').all();

// Find manager
const manager = orgChart.find(emp => 
  emp.json.employee_id === request.employee_id
);

return [{
  json: {
    ...request,
    manager: manager.json.manager,
    manager_email: manager.json.manager_email,
    approval_required: request.days > 5
  }
}];
```

---

## Workflow 3: Performance Review Automation

### Use Case
Automate performance review cycles.

### Process Flow
```
Review Cycle Starts → Self-Evaluation → Manager Review → 
Peer Reviews → Calibration → Final Review → Feedback Session
```

### Review Reminders
```javascript
const reviews = $('Get Pending Reviews').all();
const overdue = reviews.filter(r => 
  new Date(r.json.due_date) < new Date()
);

const dueToday = reviews.filter(r => 
  new Date(r.json.due_date).toDateString() === new Date().toDateString()
);

const dueThisWeek = reviews.filter(r => {
  const due = new Date(r.json.due_date);
  const now = new Date();
  return due > now && due <= new Date(now.getTime() + 7*24*60*60*1000);
});

return [
  ...overdue.map(r => ({
    json: {
      ...r.json,
      reminder_type: 'overdue',
      urgency: 'high'
    }
  })),
  ...dueToday.map(r => ({
    json: {
      ...r.json,
      reminder_type: 'due_today',
      urgency: 'medium'
    }
  })),
  ...dueThisWeek.map(r => ({
    json: {
      ...r.json,
      reminder_type: 'due_soon',
      urgency: 'low'
    }
  }))
];
```

---

## Workflow 4: Payroll Processing

### Use Case
Automate monthly payroll calculations.

### Process Flow
```
Time Data → Calculate Hours → Apply Adjustments → 
Calculate Pay → Generate Payslips → Bank Transfer → Notify Employees
```

### Payroll Calculation
```javascript
const employees = $('Get Active Employees').all();
const timeData = $('Get Time Data').all();

const payroll = employees.map(emp => {
  const empTime = timeData.filter(t => 
    t.json.employee_id === emp.json.employee_id
  );
  
  const baseSalary = emp.json.salary;
  const overtime = empTime
    .filter(t => t.json.type === 'overtime')
    .reduce((sum, t) => sum + t.json.hours, 0);
  
  const overtimePay = overtime * (baseSalary / 160 * 1.5);
  const deductions = baseSalary * 0.10; // Tax, insurance, etc.
  
  return {
    json: {
      employee_id: emp.json.employee_id,
      name: emp.json.name,
      base_salary: baseSalary,
      overtime_hours: overtime,
      overtime_pay: overtimePay,
      deductions: deductions,
      net_pay: baseSalary + overtimePay - deductions,
      pay_date: new Date().toISOString().split('T')[0]
    }
  };
});

return payroll;
```

---

## Workflow 5: Offboarding Process

### Use Case
Tự động hóa quy trình nghỉ việc.

### Process Flow
```
Resignation Received → Exit Interview → Revoke Access → 
Collect Equipment → Final Settlement → Archive Records
```

### Revoke Access
```javascript
const employee = $input.first().json;
const systems = [
  'google_workspace', 'slack', 'github', 'jira', 
  'internal_system', 'vpn', 'email'
];

const revocations = systems.map(system => ({
  json: {
    employee: employee.name,
    employee_email: employee.email,
    system: system,
    action: 'deactivate',
    effective_date: employee.last_working_day,
    offboarded_by: employee.manager
  }
}));

return revocations;
```

---

## Integration Points

### HR Systems
| System | Use Case |
|--------|----------|
| BambooHR | Employee data |
| Workday | HRIS |
| Gusto | Payroll |
| Deel | International payroll |

### Communication
| Tool | Purpose |
|------|---------|
| Slack | Notifications |
| Email | Official communications |
| Calendar | Schedule meetings |
| Teams | Video calls |

---

## Best Practices

### ✅ Do
- Get employee consent for data processing
- Maintain audit trails
- Secure sensitive data
- Set up approval workflows
- Test with edge cases
- Document all processes

### ❌ Don't
- Store passwords in plain text
- Skip approval steps
- Expose salary information
- Forget compliance requirements
- Hardcode employee data
- Skip exit interviews

---

## Compliance Considerations

### Data Protection
- GDPR for EU employees
- Local labor laws
- Data retention policies
- Access controls

### Audit Requirements
- Keep records for 3+ years
- Log all changes
- Maintain approval history
- Document exceptions
