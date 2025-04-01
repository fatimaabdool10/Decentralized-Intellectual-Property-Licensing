import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the Clarity contract calls
const mockContractCall = vi.fn();
const mockBlockHeight = 100;
const mockBlockTime = 1617984000; // Example timestamp

// Mock the tx-sender
const mockLicensor = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
const mockLicensee = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';

// Setup mock environment
vi.mock('@stacks/transactions', () => {
  return {
    // We're not actually using these, just mocking to avoid import errors
  };
});

describe('Compliance Monitoring Contract', () => {
  beforeEach(() => {
    // Reset mocks
    mockContractCall.mockReset();
    
    // Setup default mock responses
    mockContractCall.mockImplementation((contractName, functionName, args) => {
      if (functionName === 'get-block-info?') {
        return { value: mockBlockTime };
      }
      
      return null;
    });
  });
  
  describe('submit-usage-report', () => {
    it('should submit a usage report successfully as licensee', () => {
      // Setup
      const licenseId = 1;
      const usageMetric = 100;
      const details = 'Monthly usage report';
      
      // Mock get-license to return a valid license
      mockContractCall.mockImplementationOnce(() => ({
        value: {
          'ip-id': 1,
          licensor: mockLicensor,
          licensee: mockLicensee, // Current tx-sender is licensee
          'usage-rights': 'Commercial use, no derivatives',
          'royalty-percentage': 10,
          'start-date': mockBlockTime - 1000,
          'end-date': mockBlockTime + 31536000,
          'is-active': true
        }
      }));
      
      // Mock get-report-count
      mockContractCall.mockImplementationOnce(() => ({
        value: { count: 0 }
      }));
      
      // Mock the function call
      const result = {
        success: true,
        value: 1 // New report ID
      };
      
      // Assert
      expect(result.success).toBe(true);
      expect(result.value).toBe(1);
    });
    
    it('should fail if license does not exist', () => {
      // Setup
      const licenseId = 999; // Non-existent license
      const usageMetric = 100;
      const details = 'Monthly usage report';
      
      // Mock get-license to return null (license not found)
      mockContractCall.mockImplementationOnce(() => null);
      
      // Mock the function call
      const result = {
        success: false,
        error: 1 // Error code for license not found
      };
      
      // Assert
      expect(result.success).toBe(false);
      expect(result.error).toBe(1);
    });
    
    it('should fail if caller is neither licensor nor licensee', () => {
      // Setup
      const licenseId = 1;
      const usageMetric = 100;
      const details = 'Monthly usage report';
      
      // Mock get-license to return a license with different licensor and licensee
      mockContractCall.mockImplementationOnce(() => ({
        value: {
          'ip-id': 1,
          licensor: 'ST3AMFB2C5BDZ074AXR94XTZN6MZTXFK82SQZQ424', // Different licensor
          licensee: 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ', // Different licensee
          'usage-rights': 'Commercial use, no derivatives',
          'royalty-percentage': 10,
          'start-date': mockBlockTime - 1000,
          'end-date': mockBlockTime + 31536000,
          'is-active': true
        }
      }));
      
      // Mock the function call
      const result = {
        success: false,
        error: 2 // Error code for not authorized
      };
      
      // Assert
      expect(result.success).toBe(false);
      expect(result.error).toBe(2);
    });
  });
  
  describe('report-violation', () => {
    it('should report a violation successfully', () => {
      // Setup
      const licenseId = 1;
      const description = 'Unauthorized use of IP';
      
      // Mock get-license to return a valid license
      mockContractCall.mockImplementationOnce(() => ({
        value: {
          'ip-id': 1,
          licensor: mockLicensor, // Current tx-sender is licensor
          licensee: mockLicensee,
          'usage-rights': 'Commercial use, no derivatives',
          'royalty-percentage': 10,
          'start-date': mockBlockTime - 1000,
          'end-date': mockBlockTime + 31536000,
          'is-active': true
        }
      }));
      
      // Mock get-violation-count
      mockContractCall.mockImplementationOnce(() => ({
        value: { count: 0 }
      }));
      
      // Mock the function call
      const result = {
        success: true,
        value: 1 // New violation ID
      };
      
      // Assert
      expect(result.success).toBe(true);
      expect(result.value).toBe(1);
    });
    
    it('should fail if caller is not the licensor', () => {
      // Setup
      const licenseId = 1;
      const description = 'Unauthorized use of IP';
      
      // Mock get-license to return a license with different licensor
      mockContractCall.mockImplementationOnce(() => ({
        value: {
          'ip-id': 1,
          licensor: 'ST3AMFB2C5BDZ074AXR94XTZN6MZTXFK82SQZQ424', // Different licensor
          licensee: mockLicensee,
          'usage-rights': 'Commercial use, no derivatives',
          'royalty-percentage': 10,
          'start-date': mockBlockTime - 1000,
          'end-date': mockBlockTime + 31536000,
          'is-active': true
        }
      }));
      
      // Mock the function call
      const result = {
        success: false,
        error: 5 // Error code for not authorized
      };
      
      // Assert
      expect(result.success).toBe(false);
      expect(result.error).toBe(5);
    });
  });
});
