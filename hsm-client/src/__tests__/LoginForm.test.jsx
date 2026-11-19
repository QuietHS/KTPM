import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import LoginForm from "../components/loginform/LoginForm";

import axiosInstanceUserService from "../utils/axiosInstanceUserService";
import axiosInstancePatientService from "../utils/axiosInstancePatientService";

const mockNavigate = jest.fn();

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("../utils/axiosInstanceUserService", () => ({
  __esModule: true,
  default: {
    post: jest.fn(),
  },
}));

jest.mock("../utils/axiosInstancePatientService", () => ({
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

describe("Login Form Validation", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("LoginForm_EmptyEmail_ShowsError", async () => {
    const user = userEvent.setup();

    render(<LoginForm />);

    const emailInput = screen.getByLabelText(/email address/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const signInButton = screen.getByRole("button", {
      name: /sign in/i,
    });

    await user.type(passwordInput, "123456");

    await user.click(signInButton);

    expect(emailInput).toBeRequired();
    expect(emailInput).toBeInvalid();
    expect(emailInput.validity.valueMissing).toBe(true);

    expect(axiosInstanceUserService.post).not.toHaveBeenCalled();
  });

  test("LoginForm_InvalidEmailFormat_ShowsError", async () => {
    const user = userEvent.setup();

    render(<LoginForm />);

    const emailInput = screen.getByLabelText(/email address/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const signInButton = screen.getByRole("button", {
      name: /sign in/i,
    });

    await user.type(emailInput, "abcgmail.com");
    await user.type(passwordInput, "123456");

    await user.click(signInButton);

    expect(emailInput).toBeInvalid();
    expect(emailInput.validity.typeMismatch).toBe(true);

    expect(axiosInstanceUserService.post).not.toHaveBeenCalled();
  });

  test("LoginForm_EmptyPassword_ShowsError", async () => {
    const user = userEvent.setup();

    render(<LoginForm />);

    const emailInput = screen.getByLabelText(/email address/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const signInButton = screen.getByRole("button", {
      name: /sign in/i,
    });

    await user.type(emailInput, "patient@gmail.com");

    await user.click(signInButton);

    expect(passwordInput).toBeRequired();
    expect(passwordInput).toBeInvalid();
    expect(passwordInput.validity.valueMissing).toBe(true);

    expect(axiosInstanceUserService.post).not.toHaveBeenCalled();
  });
});