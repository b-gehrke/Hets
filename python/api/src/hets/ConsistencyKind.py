from enum import Enum


class ConsistencyKind(Enum):
    """
    A type of consistency of a theory.
    """

    INCONSISTENT = 0
    """
    The theory was proven to be inconsistent
    """

    UNKNOWN = 1
    """
    The consistency of the theory is not known
    """

    PCONS = 2
    """
    The theory is proven consistent
    """

    CONS = 3
    """
    The theory is proven consistent
    """

    MONO = 4
    """
    TODO
    """

    DEFINED = 5
    """
    The theory is defined to be consistent
    """

    ERROR = 6
    """
    An error occurred while checking the consistency of a theory
    """

    TIMED_OUT = 7
    """
    The consistency checker timed out
    """

    def to_str(self) -> str:
        """
        Converts a consistency kind to human friendly string
        """

        return {
            ConsistencyKind.INCONSISTENT: "Inconsistent",
            ConsistencyKind.UNKNOWN: "Unknown",
            ConsistencyKind.PCONS: "PCons",
            ConsistencyKind.CONS: "Consistent",
            ConsistencyKind.MONO: "Mono",
            ConsistencyKind.DEFINED: "Defined",
            ConsistencyKind.ERROR: "Errored",
            ConsistencyKind.TIMED_OUT: "Timed out"
        }[self]
