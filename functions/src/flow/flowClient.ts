import * as crypto from "crypto";

export interface FlowConfig {
  apiKey: string;
  secretKey: string;
  baseUrl: string;
}

export function signFlowParams(
  params: Record<string, string>,
  secretKey: string,
): string {
  const keys = Object.keys(params).filter((k) => k !== "s").sort();
  const toSign = keys.map((k) => `${k}${params[k]}`).join("");
  return crypto.createHmac("sha256", secretKey).update(toSign).digest("hex");
}

export interface FlowCustomer {
  customerId: string;
  email: string;
  name: string;
  externalId: string;
  status: string;
  last4CardDigits?: string | null;
}

export interface FlowRegisterResponse {
  url: string;
  token: string;
}

export interface FlowRegisterStatus {
  status: string;
  customerId: string;
  last4CardDigits?: string | null;
  creditCardType?: string | null;
}

export interface FlowSubscription {
  subscriptionId: string;
  planId: string;
  customerId: string;
  status: number;
  next_invoice_date?: string;
}

export interface FlowPaymentStatus {
  status: number;
  flowOrder: number;
  subject: string;
  amount: number;
  optional?: string;
  paymentData?: {
    date?: string;
    media?: string;
    amount?: number;
    fee?: number;
  };
}

export interface FlowClient {
  createCustomer(params: { name: string; email: string; externalId: string }): Promise<FlowCustomer>;
  registerCustomerCard(params: { customerId: string; url_return: string }): Promise<FlowRegisterResponse>;
  getRegisterStatus(token: string): Promise<FlowRegisterStatus>;
  createSubscription(params: { planId: string; customerId: string }): Promise<FlowSubscription>;
  getPaymentStatus(token: string): Promise<FlowPaymentStatus>;
}

export function buildFlowClient(config: FlowConfig): FlowClient {
  const postForm = async <T>(endpoint: string, params: Record<string, string>): Promise<T> => {
    const withKey = { ...params, apiKey: config.apiKey };
    const s = signFlowParams(withKey, config.secretKey);
    const body = new URLSearchParams({ ...withKey, s }).toString();
    const res = await fetch(`${config.baseUrl}${endpoint}`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body,
    });
    if (!res.ok) {
      throw new Error(`Flow API ${endpoint} error ${res.status}: ${await res.text()}`);
    }
    return res.json() as Promise<T>;
  };

  const getForm = async <T>(endpoint: string, params: Record<string, string>): Promise<T> => {
    const withKey = { ...params, apiKey: config.apiKey };
    const s = signFlowParams(withKey, config.secretKey);
    const query = new URLSearchParams({ ...withKey, s }).toString();
    const res = await fetch(`${config.baseUrl}${endpoint}?${query}`);
    if (!res.ok) {
      throw new Error(`Flow API ${endpoint} error ${res.status}: ${await res.text()}`);
    }
    return res.json() as Promise<T>;
  };

  return {
    createCustomer: (p) => postForm<FlowCustomer>("/customer/create", p),
    registerCustomerCard: (p) => postForm<FlowRegisterResponse>("/customer/register", p),
    getRegisterStatus: (token) => getForm<FlowRegisterStatus>("/customer/getRegisterStatus", { token }),
    createSubscription: (p) => postForm<FlowSubscription>("/subscription/create", p),
    getPaymentStatus: (token) => getForm<FlowPaymentStatus>("/payment/getStatus", { token }),
  };
}
