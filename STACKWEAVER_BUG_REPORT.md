# StackWeaver Bug Report: Ansible Deprecation Warning

## Summary
StackWeaver's Ansible integration is using a deprecated import that will break in ansible-core 2.24. The deprecation warning appears when executing Ansible playbooks through StackWeaver.

## Issue Details

### Deprecation Warning
```
Importing 'to_text' from 'ansible.module_utils._text' is deprecated. 
This feature will be removed from ansible-core version 2.24. 
Use ansible.module_utils.common.text.converters instead.
```

### Impact
- **Current Status**: Warning only (playbooks still execute successfully)
- **Future Impact**: Will cause failures in ansible-core 2.24+ when the deprecated import is removed
- **Urgency**: **HIGH** - Must be fixed before ansible-core 2.24 release

### Root Cause
StackWeaver's Ansible integration code (likely in a custom module, plugin, or module_utils) is using:
```python
from ansible.module_utils._text import to_text
```

### Required Fix
Update the import to use the new location:
```python
from ansible.module_utils.common.text.converters import to_text
```

## Reproduction Steps

1. Create or use an existing Ansible playbook (tested with `ansible-examples/playbooks/elasticsearch.yml`)
2. Launch a job in StackWeaver to execute the playbook
3. Observe the deprecation warning in the job output

### Test Environment
- **Playbook**: `ansible-examples/playbooks/elasticsearch.yml`
- **Action**: Launching job through StackWeaver
- **Result**: Deprecation warning appears in job output

## Technical Details

### Deprecated Module
- **Old Import**: `ansible.module_utils._text`
- **Removed In**: ansible-core 2.24
- **Replacement**: `ansible.module_utils.common.text.converters`

### Affected Components
This warning originates from StackWeaver's internal Ansible integration code, not from user playbooks. The issue is likely in:
- Custom Ansible modules
- Custom module_utils
- Custom plugins (action, lookup, filter, etc.)
- Third-party collections used by StackWeaver

### Ansible Version Compatibility
- Works with: ansible-core < 2.24 (with warning)
- Will fail with: ansible-core >= 2.24 (import removed)

## Recommended Action Items

1. **Search StackWeaver codebase** for all occurrences of:
   - `from ansible.module_utils._text import`
   - `import ansible.module_utils._text`
   
2. **Replace all instances** with:
   - `from ansible.module_utils.common.text.converters import`

3. **Test thoroughly** with:
   - Current ansible-core version (to verify warning is gone)
   - ansible-core 2.23.x (latest stable before removal)
   - Consider testing with ansible-core devel if possible

4. **Update dependencies** if using third-party collections that have this issue

## Additional Notes

- This is a proactive fix to prevent future breakage
- The warning does not affect current functionality
- StackWeaver should consider adding deprecation warning detection to CI/CD pipeline

## Related References

- Ansible Deprecation Policy: https://docs.ansible.com/ansible/latest/dev_guide/deprecations.html
- ansible-core Changelog: Check for 2.24 release notes regarding `ansible.module_utils._text` removal

---

**Report Date**: 2026-01-07
**Reported By**: Generated from user testing
**Priority**: High (preventive maintenance before breaking change)

