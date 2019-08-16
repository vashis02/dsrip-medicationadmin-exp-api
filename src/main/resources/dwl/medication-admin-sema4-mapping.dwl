%dw 2.0
output application/json  skipNullOn="everywhere"
fun statusMapping(status) =
  if (status == "Canceled Entry")
    "entered-in-error"
  else (if (status == "New Syringe/Cartridge" or status == "Given During Downtime" or status == "Completed Transfusion" or status == "Given by Other" or status == "Given")
    "completed"
  else (if (status == "MAR Hold" or status == "Paused" or status == "Imm Not Given - Patient Refused" or status == "Automatically Held" or status == "Pending" or status == "Held")
    "on-hold"
  else (if (status == "Maintenance after Bolus" or status == "Started During Downtime" or status == "Patch Applied" or status == "Restarted" or status == "Started Transfusion")
    "in-progress"
  else (if (status == "Stopped" or status == "Patch Removed")
    "stopped"
  else (if (status == "Missed" or status == "MAR Unhold" or status == "Bolus from Bag" or status == "NPO" or status == "Not given/Wasted" or status == "DUAL SIGN Handoff" or status == "Bolus from Infusion" or status == "DUAL SIGN Rate/Dose Change" or status == "Transfer to Non-Epic Unit" or status == "Rate Verify" or status == "Clinician Bolus Dose" or status == "See Alternative" or status == "Second Nurse Verify" or status == "Rate Change" or status == "Handoffe" or status == "Documented prior to Go-Live" or status == "New Bag")
    "unknown"
  else
    "unknown")))))
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
      fullUrl: "https://apiconnect-dev.mountsinai.org/api/MedicationAdmin/" ++ indexOfPayload01,
      resource: {
        resourceType: "MedicationAdministration",
        subject: {
          display: payload01."MEDICAL_RECORD_NUMBER"
        },
        context: {
          display: payload01."CSN_ID"
        },
        medicationCodeableConcept: {
          coding: [
            {
              code: payload01."MEDICATION_ID",
              display: payload01.DESCRIPTION,
              system: payload01."MEDICATION_CODING_SYSTEM"
            }
          ],
          text: payload01.DESCRIPTION
        },
        status: statusMapping(payload01."MEDICATION_ADMIN_STATUS"),
        identifier: [
          {
            use: "official",
            value: payload01."MEDICATION_ORDER_ID"
          }
        ],
        effectiveDateTime: 
          if (not payload01."MEDICATION_ADMIN_DATE_TIME" == null)
            payload01."MEDICATION_ADMIN_DATE_TIME" as Localdatetime {format: "yyyy-MM-dd'T'HH:mm:ss"}
          else
            null,
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