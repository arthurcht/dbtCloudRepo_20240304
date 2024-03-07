select *
from {{ source('dbtSchema_Arthur20240304', 'raw_transactions')}}