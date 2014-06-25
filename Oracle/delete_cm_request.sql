update fnd_concurrent_requests
set status_code = 'X', phase_code='C'
where request_id = &request_id
/

