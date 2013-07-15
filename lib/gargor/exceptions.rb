

class Gargor
  class GargorError < RuntimeError; end

  class ExterminationError < GargorError; end
  class DeployError < GargorError; end
  class ParameterError < GargorError; end
  class ValidationError < GargorError; end
  class ArgumentError < GargorError; end
end
