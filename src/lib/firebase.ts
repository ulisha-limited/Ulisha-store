import { initializeApp } from 'firebase/app';
import { getAuth, RecaptchaVerifier, signInWithPhoneNumber, PhoneAuthProvider, signInWithCredential } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyAFUijffq99nLlZVl5dvbN6_LUw0ngGTSM",
  authDomain: "ulisha-store.firebaseapp.com",
  projectId: "ulisha-store",
  storageBucket: "ulisha-store.firebasestorage.app",
  messagingSenderId: "13198804501",
  appId: "1:13198804501:web:5e6a9ef1da9ab56212f01c",
  measurementId: "G-7RXH5QD1FS"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);

// OTP Service for password changes
export class OTPService {
  private recaptchaVerifier: RecaptchaVerifier | null = null;
  private verificationId: string | null = null;

  // Initialize reCAPTCHA for OTP
  initializeRecaptcha(containerId: string = 'recaptcha-container'): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        // Clear any existing verifier
        if (this.recaptchaVerifier) {
          this.recaptchaVerifier.clear();
        }

        this.recaptchaVerifier = new RecaptchaVerifier(auth, containerId, {
          size: 'invisible',
          callback: () => {
            console.log('reCAPTCHA solved');
            resolve();
          },
          'expired-callback': () => {
            console.log('reCAPTCHA expired');
            reject(new Error('reCAPTCHA expired. Please try again.'));
          }
        });

        // Render the reCAPTCHA
        this.recaptchaVerifier.render().then(() => {
          resolve();
        }).catch(reject);
      } catch (error) {
        console.error('Error initializing reCAPTCHA:', error);
        reject(error);
      }
    });
  }

  // Send OTP to phone number
  async sendOTP(phoneNumber: string): Promise<string> {
    try {
      if (!this.recaptchaVerifier) {
        throw new Error('reCAPTCHA not initialized');
      }

      // Format phone number (ensure it starts with country code)
      const formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : `+234${phoneNumber.replace(/^0/, '')}`;

      const confirmationResult = await signInWithPhoneNumber(auth, formattedPhone, this.recaptchaVerifier);
      this.verificationId = confirmationResult.verificationId;
      
      return this.verificationId;
    } catch (error: any) {
      console.error('Error sending OTP:', error);
      
      // Handle specific Firebase errors
      if (error.code === 'auth/invalid-phone-number') {
        throw new Error('Invalid phone number format. Please check and try again.');
      } else if (error.code === 'auth/too-many-requests') {
        throw new Error('Too many requests. Please try again later.');
      } else if (error.code === 'auth/captcha-check-failed') {
        throw new Error('reCAPTCHA verification failed. Please try again.');
      }
      
      throw new Error('Failed to send verification code. Please try again.');
    }
  }

  // Verify OTP code
  async verifyOTP(otpCode: string): Promise<boolean> {
    try {
      if (!this.verificationId) {
        throw new Error('No verification ID found. Please request a new code.');
      }

      const credential = PhoneAuthProvider.credential(this.verificationId, otpCode);
      await signInWithCredential(auth, credential);
      
      // Sign out immediately as we only need verification
      await auth.signOut();
      
      return true;
    } catch (error: any) {
      console.error('Error verifying OTP:', error);
      
      // Handle specific Firebase errors
      if (error.code === 'auth/invalid-verification-code') {
        throw new Error('Invalid verification code. Please check and try again.');
      } else if (error.code === 'auth/code-expired') {
        throw new Error('Verification code has expired. Please request a new one.');
      }
      
      throw new Error('Failed to verify code. Please try again.');
    }
  }

  // Clean up resources
  cleanup(): void {
    if (this.recaptchaVerifier) {
      this.recaptchaVerifier.clear();
      this.recaptchaVerifier = null;
    }
    this.verificationId = null;
  }
}

// Email OTP Service using Firebase Auth
export class EmailOTPService {
  // Send OTP to email using Firebase Auth
  async sendEmailOTP(email: string): Promise<void> {
    try {
      // Use Firebase's sendPasswordResetEmail as a verification method
      // This is a workaround since Firebase doesn't have direct email OTP
      const { sendPasswordResetEmail } = await import('firebase/auth');
      
      // We'll use a custom approach by generating a random code and storing it
      const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
      
      // Store the OTP in localStorage with timestamp (expires in 5 minutes)
      const otpData = {
        code: otpCode,
        email: email,
        timestamp: Date.now(),
        expires: Date.now() + (5 * 60 * 1000) // 5 minutes
      };
      
      localStorage.setItem('email_otp_verification', JSON.stringify(otpData));
      
      // Send email using a mock service (in production, you'd use a real email service)
      await this.sendEmailWithOTP(email, otpCode);
      
    } catch (error: any) {
      console.error('Error sending email OTP:', error);
      throw new Error('Failed to send verification code to email. Please try again.');
    }
  }

  // Verify email OTP
  async verifyEmailOTP(email: string, otpCode: string): Promise<boolean> {
    try {
      const storedData = localStorage.getItem('email_otp_verification');
      
      if (!storedData) {
        throw new Error('No verification code found. Please request a new one.');
      }
      
      const otpData = JSON.parse(storedData);
      
      // Check if OTP has expired
      if (Date.now() > otpData.expires) {
        localStorage.removeItem('email_otp_verification');
        throw new Error('Verification code has expired. Please request a new one.');
      }
      
      // Check if email matches
      if (otpData.email !== email) {
        throw new Error('Email mismatch. Please try again.');
      }
      
      // Check if OTP code matches
      if (otpData.code !== otpCode) {
        throw new Error('Invalid verification code. Please check and try again.');
      }
      
      // Clean up after successful verification
      localStorage.removeItem('email_otp_verification');
      
      return true;
    } catch (error: any) {
      console.error('Error verifying email OTP:', error);
      throw error;
    }
  }

  // Mock email sending service (replace with real email service in production)
  private async sendEmailWithOTP(email: string, otpCode: string): Promise<void> {
    // In a real application, you would use a service like SendGrid, Mailgun, etc.
    // For now, we'll simulate the email sending and show the OTP in console
    console.log(`📧 Email OTP for ${email}: ${otpCode}`);
    
    // Show a notification to the user with the OTP (for demo purposes)
    const notification = document.createElement('div');
    notification.className = 'fixed top-4 right-4 bg-blue-500 text-white px-6 py-4 rounded-lg shadow-lg z-50 max-w-sm';
    notification.innerHTML = `
      <div class="flex items-center">
        <div class="mr-3">📧</div>
        <div>
          <p class="font-medium">Demo Mode</p>
          <p class="text-sm">Your verification code: <strong>${otpCode}</strong></p>
          <p class="text-xs mt-1">In production, this would be sent to your email.</p>
        </div>
      </div>
    `;
    
    document.body.appendChild(notification);
    
    // Remove notification after 10 seconds
    setTimeout(() => {
      if (document.body.contains(notification)) {
        document.body.removeChild(notification);
      }
    }, 10000);
    
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  // Clean up resources
  cleanup(): void {
    localStorage.removeItem('email_otp_verification');
  }
}