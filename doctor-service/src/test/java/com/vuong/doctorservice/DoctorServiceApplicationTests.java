package com.vuong.doctorservice;

import com.vuong.doctorservice.dto.AppointmentSlotRequestDto;
import com.vuong.doctorservice.dto.BookAppointmentRequestDto;
import com.vuong.doctorservice.dto.DoctorDto;
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

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.modelmapper.ModelMapper;
import org.springframework.http.ResponseEntity;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DoctorServiceApplicationTest {

    @Mock
    private DoctorAvailabilityRepository doctorAvailabilityRepository;

    @Mock
    private DoctorAppointmentRepository doctorAppointmentRepository;

    @Mock
    private DoctorService doctorService;

    @Mock
    private ModelMapper modelMapper;

    @Mock
    private PatientServiceFeignClient patientServiceFeignClient;

    @Mock
    private NotificationServiceFeignClient notificationServiceFeignClient;

    @InjectMocks
    private DoctorAppointmentServiceImplementation appointmentService;

    private DoctorDto doctorDto;
    private DoctorEntity doctorEntity;

    @BeforeEach
    void setUp() {
        doctorDto = mock(DoctorDto.class);
        doctorEntity = mock(DoctorEntity.class);

        lenient().when(doctorDto.getDoctorId()).thenReturn("DOC-001");
    }

    // UT-BE-01
    @Test
    @DisplayName("UT-BE-01 - Tạo availability slot hợp lệ")
    void createAppointmentSlot_ValidData_Success() throws CustomException {

        AppointmentSlotRequestDto request =
                mock(AppointmentSlotRequestDto.class);

        LocalDate date = LocalDate.now().plusDays(1);

        when(request.getDate()).thenReturn(date);
        when(request.getStartTime()).thenReturn(LocalTime.of(9, 0));
        when(request.getEndTime()).thenReturn(LocalTime.of(10, 0));
        when(request.getPerPatientTimeInMinutes()).thenReturn(30L);

        when(doctorService.getCurrentDoctor()).thenReturn(doctorDto);

        when(doctorAvailabilityRepository
                .findByDoctorIdAndDate("DOC-001", date))
                .thenReturn(Collections.emptyList());

        when(modelMapper.map(doctorDto, DoctorEntity.class))
                .thenReturn(doctorEntity);

        appointmentService.createAppointmentSlot(request);

        verify(doctorAvailabilityRepository, times(1))
                .saveAll(anyList());
    }

    // UT-BE-02
    @Test
    @DisplayName("UT-BE-02 - Chặn availability slot bị overlap")
    void createAppointmentSlot_Overlap_ThrowsException()
            throws CustomException {

        AppointmentSlotRequestDto request =
                mock(AppointmentSlotRequestDto.class);

        LocalDate date = LocalDate.now().plusDays(1);

        when(request.getDate()).thenReturn(date);
        when(request.getStartTime()).thenReturn(LocalTime.of(9, 30));
        when(request.getEndTime()).thenReturn(LocalTime.of(10, 30));

        DoctorAvailabilityEntity existing =
                mock(DoctorAvailabilityEntity.class);

        when(existing.getStartTime())
                .thenReturn(LocalTime.of(9, 0));

        when(existing.getEndTime())
                .thenReturn(LocalTime.of(10, 0));

        when(doctorService.getCurrentDoctor()).thenReturn(doctorDto);

        when(doctorAvailabilityRepository
                .findByDoctorIdAndDate("DOC-001", date))
                .thenReturn(List.of(existing));

        assertThrows(
                CustomException.class,
                () -> appointmentService.createAppointmentSlot(request)
        );

        verify(doctorAvailabilityRepository, never())
                .saveAll(anyList());
    }

    // UT-BE-03
    @Test
    @DisplayName("UT-BE-03 - Per patient time vượt quá khung thời gian")
    void createAppointmentSlot_PerPatientTimeTooLong_ThrowsException()
            throws CustomException {

        AppointmentSlotRequestDto request =
                mock(AppointmentSlotRequestDto.class);

        LocalDate date = LocalDate.now().plusDays(1);

        when(request.getDate()).thenReturn(date);
        when(request.getStartTime()).thenReturn(LocalTime.of(9, 0));
        when(request.getEndTime()).thenReturn(LocalTime.of(9, 30));
        when(request.getPerPatientTimeInMinutes()).thenReturn(60L);

        when(doctorService.getCurrentDoctor()).thenReturn(doctorDto);

        when(doctorAvailabilityRepository
                .findByDoctorIdAndDate("DOC-001", date))
                .thenReturn(Collections.emptyList());

        when(modelMapper.map(doctorDto, DoctorEntity.class))
                .thenReturn(doctorEntity);

        assertThrows(
                CustomException.class,
                () -> appointmentService.createAppointmentSlot(request)
        );

        verify(doctorAvailabilityRepository, never())
                .saveAll(anyList());
    }

    // UT-BE-04
    @Test
    @DisplayName("UT-BE-04 - Booking appointment hợp lệ")
    void bookAppointmentSlot_ValidData_Success()
            throws CustomException {

        BookAppointmentRequestDto request =
                mock(BookAppointmentRequestDto.class);

        PatientDto patient = mock(PatientDto.class);
        DoctorAvailabilityEntity slot =
                mock(DoctorAvailabilityEntity.class);

        LocalDate date = LocalDate.now().plusDays(1);

        when(request.getPatientId()).thenReturn("PAT-001");
        when(request.getAvailabilityId()).thenReturn(1L);

        when(patient.isActive()).thenReturn(true);

        when(patientServiceFeignClient
                .getPatientById("PAT-001"))
                .thenReturn(ResponseEntity.ok(patient));

        when(slot.getIsAvailable()).thenReturn(true);
        when(slot.getDoctor()).thenReturn(doctorEntity);
        when(slot.getDate()).thenReturn(date);

        when(doctorEntity.getDoctorId())
                .thenReturn("DOC-001");

        when(doctorAvailabilityRepository.findById(1L))
                .thenReturn(Optional.of(slot));

        when(doctorAppointmentRepository
                .existsByPatientIdAndDoctorAndDate(
                        "PAT-001",
                        "DOC-001",
                        date))
                .thenReturn(false);

        appointmentService.bookAppointmentSlot(request);

        verify(slot).setIsAvailable(false);

        verify(doctorAvailabilityRepository)
                .save(slot);

        verify(doctorAppointmentRepository)
                .save(any(AppointmentEntity.class));
    }

    // UT-BE-05
    @Test
    @DisplayName("UT-BE-05 - Chặn Patient đặt cùng Doctor trong cùng ngày")
    void bookAppointmentSlot_DoubleBooking_ThrowsException()
            throws CustomException {

        BookAppointmentRequestDto request =
                mock(BookAppointmentRequestDto.class);

        PatientDto patient = mock(PatientDto.class);
        DoctorAvailabilityEntity slot =
                mock(DoctorAvailabilityEntity.class);

        LocalDate date = LocalDate.now().plusDays(1);

        when(request.getPatientId()).thenReturn("PAT-001");
        when(request.getAvailabilityId()).thenReturn(1L);

        when(patient.isActive()).thenReturn(true);

        when(patientServiceFeignClient
                .getPatientById("PAT-001"))
                .thenReturn(ResponseEntity.ok(patient));

        when(slot.getIsAvailable()).thenReturn(true);
        when(slot.getDoctor()).thenReturn(doctorEntity);
        when(slot.getDate()).thenReturn(date);

        when(doctorEntity.getDoctorId())
                .thenReturn("DOC-001");

        when(doctorAvailabilityRepository.findById(1L))
                .thenReturn(Optional.of(slot));

        when(doctorAppointmentRepository
                .existsByPatientIdAndDoctorAndDate(
                        "PAT-001",
                        "DOC-001",
                        date))
                .thenReturn(true);

        assertThrows(
                CustomException.class,
                () -> appointmentService.bookAppointmentSlot(request)
        );

        verify(doctorAppointmentRepository, never())
                .save(any(AppointmentEntity.class));
    }

    // UT-BE-06
    @Test
    @DisplayName("UT-BE-06 - Chặn booking slot không available")
    void bookAppointmentSlot_UnavailableSlot_ThrowsException()
            throws CustomException {

        BookAppointmentRequestDto request =
                mock(BookAppointmentRequestDto.class);

        PatientDto patient = mock(PatientDto.class);
        DoctorAvailabilityEntity slot =
                mock(DoctorAvailabilityEntity.class);

        when(request.getPatientId()).thenReturn("PAT-001");
        when(request.getAvailabilityId()).thenReturn(1L);

        when(patient.isActive()).thenReturn(true);

        when(patientServiceFeignClient
                .getPatientById("PAT-001"))
                .thenReturn(ResponseEntity.ok(patient));

        when(doctorAvailabilityRepository.findById(1L))
                .thenReturn(Optional.of(slot));

        when(slot.getIsAvailable()).thenReturn(false);

        assertThrows(
                CustomException.class,
                () -> appointmentService.bookAppointmentSlot(request)
        );

        verify(doctorAppointmentRepository, never())
                .save(any(AppointmentEntity.class));
    }
}