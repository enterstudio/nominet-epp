0.0.4 / 2011-01-31
==================

  * Operations now cache their responses, accessible through `Client#last_response`
  * Last response messages are available through `Client#last_message`

0.0.3 / 2011-01-17 
==================

  * Tweak how #poll method works w.r.t blocks

0.0.2 / 2011-01-07
==================

  * Add Documentation
  * Support the 'abuse-limit' on Nominet check operation
  * Fix issue with info operation XML response parsing

0.0.1 / 2010-05-26
==================

  * Add support for 'none' and 'all' options on list operation
  * Fix bugs in info operation for account objects
  * Improve handling of XML namespaces and schema locations

0.0.0 / 2010-05-25
==================

  * Initial release
  * Supports the following operations
    * Create
    * Delete
    * Fork
    * Hello
    * Info
    * List
    * Lock
    * Merge
    * Poll
    * Transfer
    * Unlock
    * Unrenew
    * Update