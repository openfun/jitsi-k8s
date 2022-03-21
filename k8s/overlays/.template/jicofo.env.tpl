# The videobridge selection strategy. The built-in strategies are:
# - SingleBridgeSelectionStrategy: Use the least loaded bridge, do not split a
#   conference between bridges (Octo).
# - SplitBridgeSelectionStrategy: Use a separate bridge for each participant
#   (for testing).
# - RegionBasedBridgeSelectionStrategy: Attempt to put each participant in a
#   bridge in their local region (i.e. use Octo for geo-location).
# - IntraRegionBridgeSelectionStrategy: Use additional bridges when a bridge
#   becomes overloaded (i.e. use Octo for load balancing).
#
# Additionally, you can use the fully qualified class name for custom
# BridgeSelectionStrategy implementations.
OCTO_BRIDGE_SELECTION_STRATEGY=${OCTO_STRATEGY}