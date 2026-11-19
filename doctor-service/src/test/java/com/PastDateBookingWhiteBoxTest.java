package com.vuong.doctorservice;

import com.vuong.doctorservice.dto.BookAppointmentRequestDto;
import com.vuong.doctorservice.dto.PatientDto;
import com.vuong.doctorservice.entitiy.AppointmentEntity;
import com.vuong.doctorservice.entitiy.DoctorAvailabilityEntity;
import com.vuong.doctorservice.entitiy.DoctorEntity;
import com.vuong.doctorservice.exception.CustomException;
import com.vuong.doctorservice.networkmanager.NotificationServiceFeignClient;
import com.vuong.doctorservice.networkmanager.PatientServiceFeignClient;
import com.vuong.doctorservice.repository.DoctorAppointmentRepository;
import com.vuong.doctorservice.repository.DoctorAvailabilityRepository;
import com.vuong.doctorservice.service.DoctorService;
import com.vuong.doctorservice.service.implementation.DoctorAppointmentServiceImplementation;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.modelmapper.ModelMapper;
import org.springframework.http.ResponseEntity;

import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PastDateBookingWhiteBoxTest {

    @InjectMocks
    private DoctorAppointmentServiceImplementation service;

    @Mock
    private DoctorAvailabilityRepository doctorAvailabilityRepository;

    @Mock
    private DoctorAppointmentRepository doctorAppointmentRepository;

    @Mock
    private PatientServiceFeignClient patientServiceFeignClient;

    @Mock
    private NotificationServiceFeignClient notificationServiceFeignClient;

    @Mock
    private DoctorService doctorService;

    @Mock
    private ModelMapper modelMapper;

    @Test
    void WB07_bookAppointmentInPast_shouldBeRejected() throws Exception {

        // ===== ARRANGE =====

        BookAppointmentRequestDto request =
                mock(BookAppointmentRequestDto.class);

        when(request.getPatientId())
                .thenReturn("PAT-PAST");

        when(request.getAvailabilityId())
                .thenReturn(999L);


        // Patient hợp lệ
        PatientDto patient = mock(PatientDto.class);

        when(patient.isActive())
                .thenReturn(true);

        when(patientServiceFeignClient.getPatientById("PAT-PAST"))
                .thenReturn(ResponseEntity.ok(patient));


        // Doctor hợp lệ
        DoctorEntity doctor = mock(DoctorEntity.class);

        when(doctor.getDoctorId())
                .thenReturn("DOC-PAST");

        when(doctor.getFirstName())
                .thenReturn("Test");

        when(doctor.getLastName())
                .thenReturn("Doctor");


        // Slot tồn tại, còn available
        // nhưng ngày nằm trong QUÁ KHỨ
        DoctorAvailabilityEntity pastSlot =
                mock(DoctorAvailabilityEntity.class);

        when(pastSlot.getIsAvailable())
                .thenReturn(true);

        when(pastSlot.getDoctor())
                .thenReturn(doctor);

        when(pastSlot.getDate())
                .thenReturn(LocalDate.now().minusDays(1));


        when(doctorAvailabilityRepository.findById(999L))
                .thenReturn(Optional.of(pastSlot));


        // Chưa từng book doctor này trong ngày đó
        when(
                doctorAppointmentRepository
                        .existsByPatientIdAndDoctorAndDate(
                                "PAT-PAST",
                                "DOC-PAST",
                                LocalDate.now().minusDays(1)
                        )
        ).thenReturn(false);


        // ===== ACT + ASSERT =====

        // Mong đợi:
        // hệ thống phải từ chối booking trong quá khứ
        assertThrows(
                CustomException.class,
                () -> service.bookAppointmentSlot(request)
        );


        // Nếu đúng thì Appointment không được lưu
        verify(
                doctorAppointmentRepository,
                never()
        ).save(any(AppointmentEntity.class));
    }
}