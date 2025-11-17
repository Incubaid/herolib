# 📘 **PRD Manual

# 1. **Product Overview**

### **What to Write**

A 2–4 sentence summary describing **what the product is**, **what problem it solves**, and **who it is for**.

### **Fields**

* `product_name`
* `version`
* `overview`
* `vision`

### **Example**

```
product_name: "Lumina PRD Builder"
version: "v1.0"
overview: "Lumina PRD Builder allows teams to generate structured, validated Product Requirements Documents using templates and AI guidance."
vision: "Enable any team to create clear requirements in minutes, improving alignment and execution speed."
```

---

# 2. **Goals**

### **What to Write**

A list of measurable outcomes that define success.

### **Fields**

* `id`
* `title`
* `description`
* `gtype` → product / business / operational

### **Example**

```
{
	id: "G1"
	title: "Faster Requirements Creation"
	description: "Reduce PRD creation time from 2 weeks to under 1 day for all teams."
	gtype: .product
},
{
	id: "G2"
	title: "Increase Adoption"
	description: "Achieve 500 monthly active users within 90 days of launch."
	gtype: .business
}
```

---

# 3. **Use Cases**

### **What to Write**

Realistic user interactions showing how the product will be used.

### **UseCase Fields**

* id
* title
* actor
* goal
* steps
* success
* failure

### **Example**

```
{
	id: "UC1"
	title: "Generate a PRD from Template"
	actor: "Product Manager"
	goal: "Create a validated PRD quickly"
	steps: [
		"User selects 'New PRD'",
		"User chooses template type",
		"User fills fields or uses AI suggestions",
		"User exports PRD to Markdown"
	]
	success: "A complete PRD is generated without missing required fields."
	failure: "Validation fails due to missing required data."
}
```

---

# 4. **Requirements**

### **What to Write**

Describe *what the system must do*, in clear, testable language.

### **Requirement Fields**

* id
* category
* title
* rtype
* description
* priority
* criteria
* dependencies

---

### **Example Requirement**

```
{
	id: "R1"
	category: "PRD Editor"
	title: "Template Selection"
	rtype: .functional
	description: "The system must allow users to select from a list of predefined PRD templates."
	priority: .high
	criteria: [
		{
			id: "AC1"
			description: "UI displays at least 5 templates"
			condition: "List contains >= 5 template entries"
		}
	]
	dependencies: []
}
```

---

### **Example Requirement with Dependency**

```
{
	id: "R3"
	category: "Export"
	title: "Export PRD to Markdown"
	rtype: .functional
	description: "Users must be able to export the completed PRD to a Markdown file."
	priority: .medium
	criteria: [
		{
			id: "AC4"
			description: "File saved in .md format"
			condition: "Output file ends with '.md'"
		}
	]
	dependencies: ["R1", "R2"]
}
```

---

# 5. **Constraints**

### **What to Write**

Non-negotiable boundaries the solution must respect.

### **Constraint Fields**

* id
* title
* description
* ctype

### **Example**

```
{
	id: "C1"
	title: "ARM64 Only"
	description: "The system must run on ARM64 servers to match company infrastructure."
	ctype: .technica
},
{
	id: "C2"
	title: "Q1 Deadline"
	description: "The first release must be launched before March 31."
	ctype: .business
},
{
	id: "C3"
	title: "GDPR Requirement"
	description: "All user data must be deletable within 24 hours of a user request."
	ctype: .compliance
}
```

---

# 6. **Risks**

### **What to Write**

Potential problems + mitigation strategies.

### **Example**

```
risks: {
	"RISK1": "Template library may be too small → Mitigate by allowing community contributions"
	"RISK2": "AI suggestions may be inaccurate → Add review/approve workflow"
	"RISK3": "Export format inconsistencies → Create automated format tests"
}
```

---

# 🔧 7. **Minimum PRD Example (Compact)**

Here is a minimal but valid PRD instance:

```
ProductRequirementsDoc{
	product_name: "Lumina PRD Builder"
	version: "v1.0"
	overview: "Tool to create structured PRDs."
	vision: "Fast, accurate requirements for all teams."

	goals: [
		Goal{
			id: "G1"
			title: "Speed"
			description: "Generate PRDs in under 10 minutes."
			gtype: .product
		}
	]

	use_cases: [
		UseCase{
			id: "UC1"
			title: "Create PRD"
			actor: "PM"
			goal: "Produce PRD quickly"
			steps: ["Click new", "Fill data", "Export"]
			success: "Valid PRD generated"
			failure: "Missing fields"
		}
	]

	requirements: [
		Requirement{
			id: "R1"
			category: "Editor"
			title: "Input Fields"
			rtype: .functional
			description: "User can fill out PRD fields"
			priority: .high
			criteria: []
			dependencies: []
		}
	]

	constraints: [
		constraint{
			id: "C1"
			title: "Must Support Markdown"
			description: "Export only in .md format"
			ctype: .technica
		}
	]

	risks: {
		"R1": "User confusion → Add tooltips"
	}
}
```
