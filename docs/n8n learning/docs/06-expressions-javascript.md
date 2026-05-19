# 06. Expressions và JavaScript trong N8N

## 📋 Mục lục
- [Expressions cơ bản](#expressions-cơ-bản)
- [JavaScript trong Code Node](#javascript-trong-code-node)
- [Python trong Code Node](#python-trong-code-node)
- [Data Transformation](#data-transformation)
- [Working with Dates](#working-with-dates)
- [Working with Arrays](#working-with-arrays)
- [Working with Objects](#working-with-objects)
- [HTTP Requests](#http-requests)
- [Best Practices](#best-practices)

---

## Expressions cơ bản

### Syntax

```
{{ expression }}
```

### Common Patterns

#### Access Data từ Node

```javascript
// Từ node ngay trước
{{ $json.field_name }}

// Từ node cụ thể
{{ $('Node Name').item.json.field_name }}

// Từ node đầu tiên (trong Code node)
{{ $('First Node').first().json.field }}

// Từ node cuối cùng
{{ $('Last Node').last().json.field }}

// Tất cả items từ node
{{ $('Node Name').all() }}
```

#### Built-in Variables

```javascript
// Data
$json              // Current item data
$input             // Input data
$node              // Node information
$workflow          // Workflow info
$execution         // Execution info

// Date/Time
$now               // Current DateTime
$today             // Current Date

// Environment
$env.VARIABLE_NAME // Environment variable
```

### String Operations

```javascript
// Basic
{{ $json.name.toUpperCase() }}
{{ $json.email.toLowerCase() }}
{{ $json.text.trim() }}

// Search
{{ $json.email.includes('@') }}
{{ $json.text.startsWith('Hello') }}
{{ $json.name.indexOf(' ') }}

// Extract
{{ $json.text.substring(0, 10) }}
{{ $json.email.split('@')[0] }}
{{ $json.text.slice(-5) }}

// Replace
{{ $json.text.replace('old', 'new') }}
{{ $json.phone.replace(/\D/g, '') }}  // Remove non-digits

// Template
{{ `Hello ${$json.name}!` }}
{{ `Order #${$json.id} - ${$json.status}` }}
```

### Number Operations

```javascript
// Math
{{ $json.price * 1.1 }}              // Add 10%
{{ $json.quantity * $json.unit_price }}
{{ Math.round($json.value) }}
{{ Math.floor($json.value) }}
{{ Math.ceil($json.value) }}

// Format
{{ $json.price.toFixed(2) }}
{{ `$${$json.price.toLocaleString()}` }}
{{ `${($json.value * 100).toFixed(1)}%` }}

// Random
{{ Math.random() }}
{{ Math.floor(Math.random() * 100) }}
```

### Conditional Expressions

```javascript
// Ternary
{{ $json.status === 'active' ? '✅' : '❌' }}
{{ $json.age >= 18 ? 'Adult' : 'Minor' }}

// With fallback
{{ $json.name || 'Unknown' }}
{{ $json.phone || 'N/A' }}

// Multiple conditions
{{ 
  $json.score >= 90 ? 'A' :
  $json.score >= 80 ? 'B' :
  $json.score >= 70 ? 'C' :
  $json.score >= 60 ? 'D' : 'F'
}}
```

---

## JavaScript trong Code Node

### Basic Structure

```javascript
// Code node trả về array của items
const items = $input.all();

// Transform each item
const output = items.map(item => {
  return {
    json: {
      // Your transformed data
      new_field: item.json.old_field.toUpperCase(),
      timestamp: new Date().toISOString()
    }
  };
});

// Return output
return output;
```

### Example 1: Data Transformation

```javascript
// Input: [{name: "john doe", email: "JOHN@EXAMPLE.COM", age: "25"}]

const items = $input.all();

const cleaned = items.map(item => ({
  json: {
    name: item.json.name
      .split(' ')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(' '),
    email: item.json.email.toLowerCase(),
    age: parseInt(item.json.age),
    is_adult: parseInt(item.json.age) >= 18,
    processed_at: new Date().toISOString()
  }
}));

return cleaned;

// Output: [{name: "John Doe", email: "john@example.com", age: 25, is_adult: true, processed_at: "..."}]
```

### Example 2: Filtering Items

```javascript
const items = $input.all();

// Filter active users only
const activeUsers = items.filter(item => 
  item.json.status === 'active' && 
  item.json.last_login && 
  new Date(item.json.last_login) > new Date('2024-01-01')
);

return activeUsers;
```

### Example 3: Aggregation

```javascript
const items = $input.all();

// Group by category and calculate totals
const grouped = items.reduce((acc, item) => {
  const category = item.json.category || 'Other';
  
  if (!acc[category]) {
    acc[category] = {
      category,
      count: 0,
      total_value: 0,
      avg_value: 0
    };
  }
  
  acc[category].count++;
  acc[category].total_value += item.json.value || 0;
  acc[category].avg_value = acc[category].total_value / acc[category].count;
  
  return acc;
}, {});

// Convert object to array
return Object.values(grouped).map(item => ({ json: item }));
```

### Example 4: Working with Arrays

```javascript
const items = $input.all();

// Flatten nested arrays
const allTags = items.flatMap(item => item.json.tags || []);

// Get unique values
const uniqueTags = [...new Set(allTags)];

// Count occurrences
const tagCounts = uniqueTags.map(tag => ({
  json: {
    tag,
    count: allTags.filter(t => t === tag).length
  }
}));

return tagCounts;
```

---

## Python trong Code Node

### Basic Structure

```python
# Access input
items = input().items()

# Transform
output = []
for item in items:
    output.append({
        'name': item['name'].upper(),
        'email': item['email'].lower(),
        'timestamp': datetime.now().isoformat()
    })

# Return output
return [{'json': item} for item in output]
```

### Example: Data Processing

```python
import json
from datetime import datetime

# Get input data
items = input().items()

# Process each item
results = []
for item in items:
    # Calculate age from birth year
    birth_year = item.get('birth_year', 0)
    age = datetime.now().year - birth_year if birth_year else 0
    
    # Format name
    name = item.get('name', '').title()
    
    results.append({
        'json': {
            'name': name,
            'age': age,
            'is_adult': age >= 18,
            'email': item.get('email', '').lower(),
            'processed_at': datetime.now().isoformat()
        }
    })

return results
```

---

## Data Transformation

### JSON Manipulation

```javascript
// Parse JSON string
const data = JSON.parse($json.json_string);

// Create JSON
const json = JSON.stringify({
  name: $json.name,
  metadata: {
    processed: true,
    timestamp: new Date().toISOString()
  }
});

// Deep clone
const cloned = JSON.parse(JSON.stringify($json));
```

### Restructuring Data

```javascript
// Before: {first_name: "John", last_name: "Doe", city: "NYC"}
// After: {full_name: "John Doe", location: {city: "NYC"}}

const items = $input.all();

const restructured = items.map(item => ({
  json: {
    full_name: `${item.json.first_name} ${item.json.last_name}`,
    location: {
      city: item.json.city,
      country: item.json.country || 'Unknown'
    },
    original: item.json
  }
}));

return restructured;
```

### Merging Data

```javascript
// Merge data from two nodes
const nodeA = $('Node A').all();
const nodeB = $('Node B').all();

// Join on common field (email)
const merged = nodeA.map(itemA => {
  const matchingB = nodeB.find(itemB => 
    itemB.json.email === itemA.json.email
  );
  
  return {
    json: {
      ...itemA.json,
      ...(matchingB ? matchingB.json : {})
    }
  };
});

return merged;
```

---

## Working with Dates

### Luxon DateTime (Built-in)

```javascript
// Current time
const now = $now;
const today = $today;

// Format
$now.toFormat('yyyy-MM-dd')           // 2024-01-15
$now.toFormat('dd/MM/yyyy HH:mm')     // 15/01/2024 14:30
$now.toFormat('EEEE')                 // Monday
$now.toFormat('yyyy-MM-dd HH:mm:ss')  // Full timestamp

// Parse dates
const date = DateTime.fromISO('2024-01-15');
const date2 = DateTime.fromFormat('15/01/2024', 'dd/MM/yyyy');

// Manipulate
$now.plus({ days: 7 })
$now.plus({ hours: 2, minutes: 30 })
$now.minus({ weeks: 1 })
$now.startOf('day')
$now.endOf('month')

// Compare
$now.diff(date, 'days').days          // Difference in days
$now.diff(date, 'hours').hours        // Difference in hours
$now > date                            // Is after?
$now < date                            // Is before?

// Relative time
$now.fromRelative(date)               // "2 days ago"
```

### Date Calculations

```javascript
// Age calculation
const birthDate = DateTime.fromISO($json.birth_date);
const age = $now.diff(birthDate, 'years').years;

// Days until deadline
const deadline = DateTime.fromISO($json.deadline);
const daysLeft = deadline.diff($now, 'days').days;

// Business days between dates
function businessDays(start, end) {
  let count = 0;
  let current = start;
  while (current < end) {
    current = current.plus({ days: 1 });
    if (current.weekday <= 5) count++;
  }
  return count;
}
```

---

## Working with Arrays

### Array Operations

```javascript
const items = $input.all();
const values = items.map(i => i.json.value);

// Sum
const total = values.reduce((sum, v) => sum + v, 0);

// Average
const avg = total / values.length;

// Max/Min
const max = Math.max(...values);
const min = Math.min(...values);

// Sort
const sorted = items.sort((a, b) => a.json.value - b.json.value);

// Group by
const grouped = items.reduce((acc, item) => {
  const key = item.json.category;
  if (!acc[key]) acc[key] = [];
  acc[key].push(item);
  return acc;
}, {});
```

### Split Out Pattern

```javascript
// Input: [{name: "John", tags: ["vip", "active"]}]
// Output: [{name: "John", tag: "vip"}, {name: "John", tag: "active"}]

const items = $input.all();

const split = items.flatMap(item => 
  item.json.tags.map(tag => ({
    json: {
      name: item.json.name,
      tag
    }
  }))
);

return split;
```

### Aggregate Pattern

```javascript
// Input: Multiple items
// Output: Single item with array

const items = $input.all();

const aggregated = {
  json: {
    items: items.map(i => i.json),
    total_count: items.length,
    collected_at: new Date().toISOString()
  }
};

return [aggregated];
```

---

## Working with Objects

### Object Operations

```javascript
// Access nested properties
const city = $json?.address?.city || 'Unknown';

// Check if property exists
const hasEmail = 'email' in $json;

// Get all keys
const keys = Object.keys($json);

// Get all values
const values = Object.values($json);

// Merge objects
const merged = { ...$json, new_field: 'value' };

// Delete property
const { password, ...safeData } = $json;
```

### Deep Transformation

```javascript
// Transform nested structure
const transform = (obj) => ({
  id: obj.id,
  profile: {
    name: `${obj.first_name} ${obj.last_name}`,
    contact: {
      email: obj.email.toLowerCase(),
      phone: obj.phone?.replace(/\D/g, '')
    }
  },
  metadata: {
    created: obj.created_at,
    updated: new Date().toISOString()
  }
});

const items = $input.all();
return items.map(item => ({ json: transform(item.json) }));
```

---

## HTTP Requests

### In Code Node (JavaScript)

```javascript
// GET request
const response = await fetch('https://api.example.com/users', {
  headers: {
    'Authorization': `Bearer ${process.env.API_TOKEN}`
  }
});
const data = await response.json();

// POST request
const postResponse = await fetch('https://api.example.com/users', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${process.env.API_TOKEN}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    name: $json.name,
    email: $json.email
  })
});

return { json: await postResponse.json() };
```

### Error Handling

```javascript
try {
  const response = await fetch('https://api.example.com/data');
  
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }
  
  const data = await response.json();
  return { json: data };
} catch (error) {
  console.error('API call failed:', error);
  return {
    json: {
      error: error.message,
      fallback: true
    }
  };
}
```

---

## Best Practices

### 1. Use Type Coercion Carefully

```javascript
// ❌ Bad - May cause issues
{{ $json.age + 1 }}  // "25" + 1 = "251" if string

// ✅ Good - Ensure correct type
{{ parseInt($json.age) + 1 }}  // 25 + 1 = 26
```

### 2. Handle Missing Data

```javascript
// ❌ Bad
{{ $json.name.toUpperCase() }}  // Error if null

// ✅ Good
{{ $json.name?.toUpperCase() || 'N/A' }}
```

### 3. Keep Code Readable

```javascript
// ❌ Bad - One-liner
return $input.all().map(i=>({json:{n:i.json.n.toUpperCase(),e:i.json.e.toLowerCase()}}));

// ✅ Good - Clear structure
const items = $input.all();
const transformed = items.map(item => ({
  json: {
    name: item.json.name?.toUpperCase(),
    email: item.json.email?.toLowerCase()
  }
}));
return transformed;
```

### 4. Log Important Info

```javascript
console.log('Processing item:', item.json.id);
console.warn('Missing field:', item.json.missing_field);
console.error('API failed:', error.message);
```

### 5. Test Edge Cases

```javascript
// Handle empty input
if (items.length === 0) {
  return [];
}

// Handle missing fields
const value = item.json.field ?? 'default';

// Handle invalid data
const number = parseFloat(item.json.value) || 0;
```

---

**[← Quay lại: 05. Nodes](05-nodes-integrations.md)** | **[Tiếp theo: 07. Webhooks →](07-webhooks-api.md)**
