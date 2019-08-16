%dw 2.0
output application/java
---
if(message.attributes.headers.client_id != null)
	message.attributes.headers.client_id
else 
	message.attributes.queryParams.client_id