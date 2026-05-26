// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MockCOPToken
/// @notice Token ERC20 simulado que representa pesos colombianos ficticios (mCOP).
///         Solo para uso en prototipo Río Cali Transparente — NO representa dinero real.
/// @dev Hereda ERC20 y Ownable de OpenZeppelin v5. La función mint está restringida al owner.
contract MockCOPToken is ERC20, Ownable {
    /// @notice Despliega el token y acuña el suministro inicial al deployer.
    /// @param initialSupply Cantidad de tokens mCOP a acuñar al deployer en el despliegue.
    constructor(uint256 initialSupply)
        ERC20("Colombian Peso Mock", "mCOP")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Acuña tokens adicionales hacia una dirección. Solo el owner puede llamar esta función.
    /// @dev Emite el evento estándar Transfer(address(0), to, amount) heredado de ERC20._mint.
    /// @param to Dirección receptora de los tokens acuñados.
    /// @param amount Cantidad de tokens a acuñar (debe ser mayor a cero).
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "MockCOPToken: mint a direccion cero");
        require(amount > 0, "MockCOPToken: monto debe ser mayor a cero");
        _mint(to, amount);
    }
}
