$ErrorActionPreference = "Stop"

$BaseUrl = "http://localhost:8090"
$AdminEmail = "admin@test.com"
$AdminPassword = "Admin@123456"

function To-JsonBody($obj) {
    return ($obj | ConvertTo-Json -Depth 10)
}

function Invoke-Hms {
    param(
        [Parameter(Mandatory=$true)][ValidateSet("GET","POST","PUT","DELETE")][string]$Method,
        [Parameter(Mandatory=$true)][string]$Path,
        $Body = $null,
        [string]$Token = "",
        [switch]$ContinueOnError
    )

    $headers = @{}
    if ($Token) {
        if ($Token.StartsWith("Bearer ")) { $headers.Authorization = $Token }
        else { $headers.Authorization = "Bearer $Token" }
    }

    try {
        $params = @{
            Uri = "$BaseUrl$Path"
            Method = $Method
            Headers = $headers
        }
        if ($null -ne $Body) {
            $params.ContentType = "application/json"
            $params.Body = To-JsonBody $Body
        }
        return Invoke-RestMethod @params
    }
    catch {
        $msg = $_.Exception.Message
        try {
            if ($_.ErrorDetails.Message) { $msg = $_.ErrorDetails.Message }
        } catch {}
        Write-Host "[SKIP/FAIL] $Method $Path -> $msg" -ForegroundColor Yellow
        if (-not $ContinueOnError) { throw }
        return $null
    }
}

function Login-Hms([string]$Email, [string]$Password) {
    $resp = Invoke-Hms -Method POST -Path "/users/login" -Body @{
        email = $Email
        password = $Password
    }
    $token = $resp.userLoginDetails.token
    if (-not $token) { throw "No token returned for $Email" }
    return $token
}

Write-Host "=== HMS demo seed started ===" -ForegroundColor Cyan

# 1) Admin login
Write-Host "[1/9] Login admin..." -ForegroundColor Cyan
$adminToken = Login-Hms $AdminEmail $AdminPassword
Write-Host "Admin login OK" -ForegroundColor Green

# 2) Rooms
Write-Host "[2/9] Creating rooms..." -ForegroundColor Cyan
$rooms = @(
    @{ roomNo = "R101"; isAvailable = $true },
    @{ roomNo = "R102"; isAvailable = $true },
    @{ roomNo = "R201"; isAvailable = $true }
)
foreach ($r in $rooms) {
    Invoke-Hms -Method POST -Path "/rooms/create" -Body $r -Token $adminToken -ContinueOnError | Out-Null
}

# 3) Patients (10-digit phone numbers to match DB column)
Write-Host "[3/9] Creating patients..." -ForegroundColor Cyan
$patients = @(
    @{
        email="patient.demo1@test.com"; password="Patient@123456"; firstName="An"; lastName="Nguyen";
        dateOfBirth="1998-04-12"; gender="Male"; bloodGroup="O_Positive"; phoneNumber="0912345601"; address="Hanoi"
    },
    @{
        email="patient.demo2@test.com"; password="Patient@123456"; firstName="Mai"; lastName="Tran";
        dateOfBirth="2000-09-23"; gender="Female"; bloodGroup="A_Positive"; phoneNumber="0912345602"; address="Hanoi"
    }
)
foreach ($p in $patients) {
    Invoke-Hms -Method POST -Path "/patients/register" -Body $p -ContinueOnError | Out-Null
}

# 4) Doctors
Write-Host "[4/9] Creating doctors..." -ForegroundColor Cyan
$doctors = @(
    @{
        email="doctor.demo1@test.com"; password="Doctor@123456"; firstName="Minh"; lastName="Le";
        careerTitle="Dr"; department="Cardiology"; specialization="Cardiology"; designation="Doctor";
        institute="HMS Hospital"; experienceYears=8; qualifications="MBBS, Cardiology"; licenseNumber="DOC-DEMO-001";
        dateOfBirth="1985-02-15"; gender="Male"; bloodGroup="B_Positive"; phoneNumber="0923456701";
        biography="Cardiology doctor for HMS demo data"; address="Hanoi"
    },
    @{
        email="doctor.demo2@test.com"; password="Doctor@123456"; firstName="Lan"; lastName="Pham";
        careerTitle="Dr"; department="Neurology"; specialization="Neurology"; designation="Doctor";
        institute="HMS Hospital"; experienceYears=6; qualifications="MBBS, Neurology"; licenseNumber="DOC-DEMO-002";
        dateOfBirth="1988-07-20"; gender="Female"; bloodGroup="A_Positive"; phoneNumber="0923456702";
        biography="Neurology doctor for HMS demo data"; address="Hanoi"
    },
    @{
        email="doctor.demo3@test.com"; password="Doctor@123456"; firstName="Huy"; lastName="Do";
        careerTitle="Dr"; department="General Medicine"; specialization="General Medicine"; designation="Doctor";
        institute="HMS Hospital"; experienceYears=5; qualifications="MBBS"; licenseNumber="DOC-DEMO-003";
        dateOfBirth="1990-11-05"; gender="Male"; bloodGroup="O_Positive"; phoneNumber="0923456703";
        biography="General medicine doctor for HMS demo data"; address="Hanoi"
    }
)
foreach ($d in $doctors) {
    Invoke-Hms -Method POST -Path "/doctors/register" -Body $d -Token $adminToken -ContinueOnError | Out-Null
}

# 5) Medicines
Write-Host "[5/9] Creating medicines..." -ForegroundColor Cyan
$medicines = @(
    @{ medicineName="Panadol 500"; genericName="Paracetamol"; manufacturer="GSK"; medicineType="Tablet"; manufactureDate="2026-01-10"; expiryDate="2028-01-10"; isOccupied=$false; isActive=$true },
    @{ medicineName="Amoxicillin 500"; genericName="Amoxicillin"; manufacturer="Demo Pharma"; medicineType="Capsule"; manufactureDate="2026-02-01"; expiryDate="2027-08-01"; isOccupied=$false; isActive=$true },
    @{ medicineName="Cough Relief"; genericName="Dextromethorphan"; manufacturer="HMS Pharma"; medicineType="Syrup"; manufactureDate="2026-03-05"; expiryDate="2027-03-05"; isOccupied=$false; isActive=$true },
    @{ medicineName="Vitamin C 500"; genericName="Ascorbic Acid"; manufacturer="HealthCo"; medicineType="Tablet"; manufactureDate="2026-04-12"; expiryDate="2028-04-12"; isOccupied=$false; isActive=$true },
    @{ medicineName="Saline 0.9"; genericName="Sodium Chloride"; manufacturer="MedSupply"; medicineType="Injection"; manufactureDate="2026-05-01"; expiryDate="2027-05-01"; isOccupied=$false; isActive=$true },
    @{ medicineName="Demo Expiry Soon"; genericName="Paracetamol"; manufacturer="Demo Pharma"; medicineType="Tablet"; manufactureDate="2025-11-01"; expiryDate=((Get-Date).AddDays(20).ToString("yyyy-MM-dd")); isOccupied=$false; isActive=$true }
)
foreach ($m in $medicines) {
    Invoke-Hms -Method POST -Path "/pharmaceutical-inventory/medicine/create" -Body $m -Token $adminToken -ContinueOnError | Out-Null
}

# 6) Medical equipment
Write-Host "[6/9] Creating medical equipment..." -ForegroundColor Cyan
$equipment = @(
    @{ medicalEquipmentName="ECG Machine"; medicalEquipmentType="Diagnostic"; manufacturer="MedTech"; manufactureDate="2025-01-10"; expiryDate="2030-01-10"; isOccupied=$false; isActive=$true },
    @{ medicalEquipmentName="Blood Pressure Monitor"; medicalEquipmentType="Monitoring"; manufacturer="Omron Demo"; manufactureDate="2025-05-15"; expiryDate="2030-05-15"; isOccupied=$false; isActive=$true },
    @{ medicalEquipmentName="Ventilator"; medicalEquipmentType="Life Support"; manufacturer="HMS Medical"; manufactureDate="2024-12-01"; expiryDate="2029-12-01"; isOccupied=$true; isActive=$true }
)
foreach ($e in $equipment) {
    Invoke-Hms -Method POST -Path "/pharmaceutical-inventory/medical-equipment/create" -Body $e -Token $adminToken -ContinueOnError | Out-Null
}

# 7) Doctor availability for the next few days
Write-Host "[7/9] Creating doctor availability..." -ForegroundColor Cyan
$tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
$day2 = (Get-Date).AddDays(2).ToString("yyyy-MM-dd")
$day3 = (Get-Date).AddDays(3).ToString("yyyy-MM-dd")
$doctorSeeds = @(
    @{ email="doctor.demo1@test.com"; password="Doctor@123456"; date=$tomorrow; start="09:00"; end="11:00" },
    @{ email="doctor.demo2@test.com"; password="Doctor@123456"; date=$day2; start="13:00"; end="15:00" },
    @{ email="doctor.demo3@test.com"; password="Doctor@123456"; date=$day3; start="08:00"; end="10:00" }
)
foreach ($ds in $doctorSeeds) {
    try {
        $doctorToken = Login-Hms $ds.email $ds.password
        Invoke-Hms -Method POST -Path "/appointments/create" -Token $doctorToken -Body @{
            date=$ds.date; startTime=$ds.start; endTime=$ds.end; perPatientTimeInMinutes=30
        } -ContinueOnError | Out-Null
    } catch {
        Write-Host "[SKIP] Could not create availability for $($ds.email): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 8) Health records for demo patients
Write-Host "[8/9] Creating health records..." -ForegroundColor Cyan
try {
    $allPatients = @(Invoke-Hms -Method GET -Path "/patients/all" -Token $adminToken)
    $demoPatients = $allPatients | Where-Object { $_.email -like "patient.demo*@test.com" } | Select-Object -First 2
    $i = 0
    foreach ($p in $demoPatients) {
        $i++
        $allergyText = if ($i -eq 1) { "None" } else { "Dust" }
        Invoke-Hms -Method POST -Path "/patients/health-records/create" -Token $adminToken -Body @{
            patientId=$p.patientId
            checkupDate=(Get-Date).ToString("yyyy-MM-dd")
            heightInCm=(170 - $i)
            weightInKg=(65 + $i)
            bloodPressure="120/80"
            bloodSugar="95"
            bodyTemperature="36.5"
            pulseRate="72"
            allergies=$allergyText
            pastSurgeries="None"
            hasDiabetes=$false
            isHypertensive=$false
            hasHeartDisease=$false
            hasKidneyDisease=$false
            hasLiverDisease=$false
            hasCancer=$false
            hasHiv=$false
            hasTb=$false
            physicalDisability="None"
            vaccineInfo="Routine vaccination completed"
            isSmoker=$false
            isAlcoholic=$false
            isActive=$true
        } -ContinueOnError | Out-Null
    }
} catch {
    Write-Host "[SKIP] Health-record seed failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 9) Book one appointment so Admin dashboard appointment count is non-zero
Write-Host "[9/9] Booking one demo appointment..." -ForegroundColor Cyan
try {
    $patientToken = Login-Hms "patient.demo1@test.com" "Patient@123456"
    $patientProfile = Invoke-Hms -Method GET -Path "/patients/profile" -Token $patientToken
    $available = @(Invoke-Hms -Method GET -Path "/appointments/get/all/availability/appointment" -Token $patientToken)
    if ($available.Count -gt 0) {
        Invoke-Hms -Method POST -Path "/appointments/book" -Token $patientToken -Body @{
            availabilityId=$available[0].availabilityId
            patientId=$patientProfile.patientId
            appointmentType="In-Person"
            appointmentStatus="Booked"
        } -ContinueOnError | Out-Null
    } else {
        Write-Host "No available appointment returned; booking skipped." -ForegroundColor Yellow
    }
} catch {
    Write-Host "[SKIP] Appointment booking failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Optional: researcher demo application (does not affect main dashboard)
Invoke-Hms -Method POST -Path "/research/register" -Body @{
    name="Demo Researcher"
    email="researcher.demo@test.com"
    designation="Research Scientist"
    institute="HMS University"
    purpose="Demo research application for testing the Analytics & Research module."
} -ContinueOnError | Out-Null

Write-Host "" 
Write-Host "=== Seed finished ===" -ForegroundColor Green
Write-Host "Refresh Admin Dashboard (Ctrl+F5)."
Write-Host "Demo doctor password: Doctor@123456"
Write-Host "Demo patient password: Patient@123456"
Write-Host "Doctor accounts: doctor.demo1@test.com, doctor.demo2@test.com, doctor.demo3@test.com"
Write-Host "Patient accounts: patient.demo1@test.com, patient.demo2@test.com"
