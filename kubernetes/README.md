Correct order (mandatory)
1. namespace/
2. secrets/
3. database/
4. backend/
5. frontend/
6. network-policies/

Why this order?
Step	Reason
Namespace	Everything lives inside it
Secrets	Used by DB & backend
Database	Backend depends on DB
Backend	Frontend depends on backend
Frontend	User-facing
NetworkPolicy	Apply security at the end