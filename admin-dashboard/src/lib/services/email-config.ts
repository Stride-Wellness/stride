export interface EmailActionCodeSettings {
  url: string;
  handleCodeInApp: boolean;
  iOS?: {
    bundleId: string;
  };
  android?: {
    packageName: string;
    installApp?: boolean;
    minimumVersion?: string;
  };
  dynamicLinkDomain?: string;
}

export const getEmailActionSettings = (): EmailActionCodeSettings => ({
  url: `${process.env.ADMIN_DASHBOARD_URL || 'http://localhost:5173'}/login`,
  handleCodeInApp: false,
  // Add your app configuration if needed
  // iOS: {
  //   bundleId: 'com.stride.admin'
  // },
  // android: {
  //   packageName: 'com.stride.admin',
  //   installApp: true,
  //   minimumVersion: '1.0.0'
  // }
});

export const getWelcomeEmailTemplate = (adminName: string, privilege: number): string => {
  const roleNames = {
    1: 'Super Administrator',
    2: 'Administrator', 
    3: 'Manager',
    4: 'Support Staff'
  };

  return `
Welcome to Stride Admin Dashboard!

Hello ${adminName},

You have been granted ${roleNames[privilege as keyof typeof roleNames] || 'Administrator'} access to the Stride Admin Dashboard.

To get started:
1. Click the password reset link in this email
2. Set your secure password
3. Verify your email address
4. Log in to the admin dashboard

If you have any questions, please contact your system administrator.

Best regards,
The Stride Team
  `;
};
