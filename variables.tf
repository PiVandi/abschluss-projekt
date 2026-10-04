variable "location" {
  type    = string
  default = "eastus" # für Sandbox anpassen -> Vermutlich US -> Muss evtl. auf Set umgestellt werden aus möglichen Locations
}

variable "prefix" {
  description = "Kurzer, global eindeutiger Prefix (z.B. Projektname)"
  type        = string
  default     = "ap-pv"
}

#variable "github_oidc_client_id" {
#  description = "Client-ID der App Registration mit Federand Credential für die GitHub-Pipeline (Rolle AcrPush auf der ACR)"
#  type = string
#}
#
#variable "apim_publisher_email" {
#    type = string
#}
#
#variable "apim_publisher_name" {
#  type = string
#  default = "PV"
#}

#variable "acr_ip_allowlist" {
#    description = "CIDR-Liste der GitHub Actions Runner-IPs (aus https://api.github.com/meta, Feld 'actions')"
#    type = list(string)
#    default = []
#}