
class Claim  


    attr_accessor :id, :ClaimIdNumber, :ClaimDescription, :CustomerId, :PlanId, 
                  :PatientFirst, :PatientLast,
                  :Diagnosis1, :Diagnosis2,
                  :Procedure1, :Procedure2, :Procedure3, 
                  :Physician, :Clinic,
                  :DateService, :Service,
                  :Location,
                  :TotalCharge, 
                  :CoveredAmount, :BalanceOwed,
                  :PaymentAmount, :PaymentDate,
                  :PaymentAction,
                  :DateAdded,
                  :AdjustedClaimId, :AdjustingClaimId,
                  :AdjustedDate, :AppAdjusting,
                  :ClaimStatus, :Referral,
                  :PaymentAction, :ClaimType,
                  :DateConfine, :DateRelease,
                  :ToothNumber, :DrugName,
                  :Eyeware,
                  :PlanId,
                  :_csrf
 
            def  initialize() 

            end 
 
 
end