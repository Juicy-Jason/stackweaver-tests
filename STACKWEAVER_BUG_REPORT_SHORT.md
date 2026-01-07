# Bug: Deprecated Ansible Import in StackWeaver

## Issue
StackWeaver's Ansible integration uses deprecated `to_text` import that will break in ansible-core 2.24.

## Warning Message
```
Importing 'to_text' from 'ansible.module_utils._text' is deprecated. 
This feature will be removed from ansible-core version 2.24. 
Use ansible.module_utils.common.text.converters instead.
```

## Impact
- **Current**: Warning only (non-blocking)
- **Future**: Will break in ansible-core 2.24+
- **Priority**: HIGH

## Fix Required
Find and replace in StackWeaver codebase:
```python
# OLD (deprecated)
from ansible.module_utils._text import to_text

# NEW (required)
from ansible.module_utils.common.text.converters import to_text
```

## Reproduction
1. Launch any Ansible playbook job in StackWeaver
2. Check job output for deprecation warning
3. Tested with: `ansible-examples/playbooks/elasticsearch.yml`

## Action Items
- [ ] Search codebase for `ansible.module_utils._text` imports
- [ ] Replace with `ansible.module_utils.common.text.converters`
- [ ] Test with ansible-core 2.23.x and prepare for 2.24

