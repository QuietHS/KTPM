import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import AvailableAppointments from "../components/appointments/AvailableAppointments";

import axiosInstanceAppointmentService from "../utils/axiosInstanceAppointmentService";
import axiosInstancePatientService from "../utils/axiosInstancePatientService";
import axiosInstanceDoctorService from "../utils/axiosInstanceDoctorService";
import { toast } from "react-toastify";

jest.mock("../utils/axiosInstanceAppointmentService", () => ({
  __esModule: true,
  default: {
    get: jest.fn(),
    post: jest.fn(),
  },
}));

jest.mock("../utils/axiosInstancePatientService", () => ({
  __esModule: true,
  default: {
    get: jest.fn(),
  },
}));

jest.mock("../utils/axiosInstanceDoctorService", () => ({
  __esModule: true,
  default: {
    get: jest.fn(),
  },
}));

jest.mock("react-toastify", () => ({
  toast: {
    success: jest.fn(),
    error: jest.fn(),
  },
}));

const appointments = [
  {
    availabilityId: 101,
    doctorId: "DOC-1",
    date: "2026-10-10",
    startTime: "09:00:00",
    endTime: "09:30:00",
  },
  {
    availabilityId: 102,
    doctorId: "DOC-2",
    date: "2026-10-11",
    startTime: "10:00:00",
    endTime: "10:30:00",
  },
];

const doctorMap = {
  "DOC-1": {
    doctorId: "DOC-1",
    firstName: "Alice",
    lastName: "Nguyen",
    department: "Cardiology",
    designation: "Doctor",
  },
  "DOC-2": {
    doctorId: "DOC-2",
    firstName: "Bob",
    lastName: "Tran",
    department: "Neurology",
    designation: "Doctor",
  },
};

function mockLoadedData(patientId = "PAT-001") {
  axiosInstancePatientService.get.mockResolvedValue({
    data: { patientId },
  });

  axiosInstanceAppointmentService.get.mockResolvedValue({
    data: appointments,
  });

  axiosInstanceDoctorService.get.mockImplementation((url) => {
    const doctorId = url.split("/").pop();
    return Promise.resolve({ data: doctorMap[doctorId] });
  });
}

async function renderLoaded(patientId = "PAT-001") {
  mockLoadedData(patientId);
  render(<AvailableAppointments />);
  await screen.findByText("Dr. Alice Nguyen");
  await screen.findByText("Dr. Bob Tran");
}

describe("AvailableAppointments", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("UT-FE-09 - Hiển thị loading khi fetch", () => {
    axiosInstancePatientService.get.mockReturnValue(new Promise(() => {}));
    axiosInstanceAppointmentService.get.mockReturnValue(new Promise(() => {}));

    const { container } = render(<AvailableAppointments />);

    expect(container.querySelector(".animate-spin")).toBeInTheDocument();
  });

  test("UT-FE-10 - Load danh sách slot thành công", async () => {
    await renderLoaded();

    expect(screen.getByText("Available Appointments")).toBeInTheDocument();
    expect(screen.getByText("Filter by Date")).toBeInTheDocument();
    expect(screen.getByText("Filter by Doctor")).toBeInTheDocument();
    expect(screen.getByText("Filter by Department")).toBeInTheDocument();
    expect(document.querySelector('input[type="date"]')).toBeInTheDocument();
    expect(screen.getAllByRole("combobox")).toHaveLength(2);
    expect(screen.getByText("Dr. Alice Nguyen")).toBeInTheDocument();
    expect(screen.getByText("Dr. Bob Tran")).toBeInTheDocument();
  });

  test("UT-FE-11 - Filter theo ngày", async () => {
    await renderLoaded();

    const dateInput = document.querySelector('input[type="date"]');
    fireEvent.change(dateInput, { target: { value: "2026-10-10" } });

    await waitFor(() => {
      expect(screen.getByText("Dr. Alice Nguyen")).toBeInTheDocument();
      expect(screen.queryByText("Dr. Bob Tran")).not.toBeInTheDocument();
    });
  });

  test("UT-FE-12 - Filter theo bác sĩ", async () => {
    const user = userEvent.setup();
    await renderLoaded();

    const [doctorSelect] = screen.getAllByRole("combobox");
    await user.selectOptions(doctorSelect, "DOC-2");

    await waitFor(() => {
      expect(screen.getByText("Dr. Bob Tran")).toBeInTheDocument();
      expect(screen.queryByText("Dr. Alice Nguyen")).not.toBeInTheDocument();
    });
  });

  test("UT-FE-13 - Clear All filters", async () => {
    const user = userEvent.setup();
    await renderLoaded();

    const dateInput = document.querySelector('input[type="date"]');
    const [doctorSelect] = screen.getAllByRole("combobox");

    fireEvent.change(dateInput, { target: { value: "2026-10-10" } });
    await user.selectOptions(doctorSelect, "DOC-1");

    await user.click(screen.getByRole("button", { name: /clear all/i }));

    await waitFor(() => {
      expect(dateInput).toHaveValue("");
      expect(doctorSelect).toHaveValue("");
      expect(screen.getByText("Dr. Alice Nguyen")).toBeInTheDocument();
      expect(screen.getByText("Dr. Bob Tran")).toBeInTheDocument();
    });
  });

  test("UT-FE-14 - Book khi chưa có patientId", async () => {
    const user = userEvent.setup();
    await renderLoaded(null);

    const bookButtons = screen.getAllByRole("button", {
      name: /book in-person/i,
    });

    await user.click(bookButtons[0]);

    expect(toast.error).toHaveBeenCalledWith("Patient information not found");
    expect(axiosInstanceAppointmentService.post).not.toHaveBeenCalled();
  });

  test("UT-FE-15 - Book thành công", async () => {
    const user = userEvent.setup();
    await renderLoaded("PAT-001");
    axiosInstanceAppointmentService.post.mockResolvedValue({ data: {} });

    const bookButtons = screen.getAllByRole("button", {
      name: /book in-person/i,
    });

    await user.click(bookButtons[0]);

    await waitFor(() => {
      expect(axiosInstanceAppointmentService.post).toHaveBeenCalledWith(
        "/book",
        {
          availabilityId: 101,
          patientId: "PAT-001",
          appointmentType: "In-Person",
          appointmentStatus: "Booked",
        }
      );
      expect(toast.success).toHaveBeenCalledWith(
        "Appointment booked successfully!"
      );
    });
  });

  test("UT-FE-16 - Book thất bại", async () => {
    const user = userEvent.setup();
    await renderLoaded("PAT-001");
    axiosInstanceAppointmentService.post.mockRejectedValue({
      response: { data: { message: "Slot already booked" } },
    });

    const bookButtons = screen.getAllByRole("button", {
      name: /book in-person/i,
    });

    await user.click(bookButtons[0]);

    await waitFor(() => {
      expect(toast.error).toHaveBeenCalledWith("Slot already booked");
    });
  });
});
