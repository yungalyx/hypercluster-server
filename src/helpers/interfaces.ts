export interface Campaign {
  name: string;
  template: "PONZI" | "FOMO" | "LEADERBOARD"
  status: "DRAFTS" | "PENDING" | "ACTIVE" | "CLOSED"
}

export interface DecryptedRefferalCodeResponse {
  referrer: string;
  campaign_id: string;
  referring?: string;
}

export interface UserData {
  referralCode: string;
  referralCount: number;
  
}