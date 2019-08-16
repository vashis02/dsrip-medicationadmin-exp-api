%dw 2.0
output application/json  
fun statusMapping(status) =
  if (status == "Completed Transfusion" or status == "Given by Other" or status == "Given")
    "completed"
  else (if (status == "Paused" or status == "Pending" or status == "Held" or status == "Automatically Held")
    "on-hold"
  else (if (status == "Patch Applied" or status == "Restarted" or status == "Started Transfusion")
    "in-progress"
  else (if (status == "Stopped")
    "stopped"
  else
    ("unknown"))))
---
if (payload.status == 204)
  payload
else
  {
    resourceType: "Bundle",
    "type": "searchset",
    meta: {
      lastUpdated: now()
    },
    entry: payload map (payload01, indexOfPayload01) -> {
      fullUrl: 
        if (p("mule.env") == "prod")
          ("https://apiconnect.mountsinai.org/api/MedicationAdmin/" ++ indexOfPayload01)
        else
          "https://apiconnect-dev.mountsinai.org/api/MedicationAdmin/" ++ indexOfPayload01,
      resource: {
        resourceType: "MedicationAdministration",
        subject: {
          reference: "MEDICAL_RECORD_NUMBER/" ++ payload01."MEDICAL_RECORD_NUMBER"
        },
        context: {
          reference: 
            if (not payload01."CSN_ID" == null)
              "CSN_ID/" ++ payload01."CSN_ID"
            else
              null
        },
        medicationCodeableConcept: {
          text: payload01."MEDICATION_NAME",
          coding: [
            {
              code: payload01."MEDICATION_ID",
              version: payload01."MEDICATION_CODING_SYSTEM",
              display: payload01."MEDICATION_NAME"
            }
          ]
        },
        status: statusMapping(payload01."MEDICATION_ADMIN_STATUS"),
        identifier: [
          {
            use: "official",
            value: payload01."MEDICATION_ORDER_ID",
            assigner: {
              display: payload01."DATA_SOURCE_NAME"
            }
          }
        ],
        effectiveDateTime: payload01."MEDICATION_ADMIN_DATE_TIME",
        dosage: {
          dose: {
            value: 
              if (not payload01."ADMINISTERED_UNIT" == null)
                payload01."ADMINISTERED_UNIT"
              else
                "0"
          },
          route: {
            coding: [
              {
                display: payload01.ROUTE
              }
            ],
            text: payload01.ROUTE
          },
          site: {
            coding: [
              {
                display: payload01.SITE
              }
            ],
            text: payload01.SITE
          },
          text: payload01."INFUSION_RATE"
        },
        reasonCode: [
          {
            coding: [
              {
                display: payload01."REASON_FOR_ADMIN"
              }
            ],
            text: payload01."REASON_FOR_ADMIN"
          }
        ],
        note: [
          {
            text: payload01.COMMENTS
          }
        ]
      }
    }
  }