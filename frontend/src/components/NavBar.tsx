import Image from "next/image";
import { NavItem } from "./NavItem";
import { AptosConnect } from "./AptosConnect";
import {
  MODULE_URL
} from "../config/constants";

export function NavBar() {
  return (
    <nav className="navbar py-4 px-4">
      <div className="flex-1 text-lg font-semibold">
        <a href="#" target="_blank">
          {/* <Image src="/logo.png" width={64} height={64} alt="logo" /> */}
          <h1>Wolf Game</h1>
        </a>
        <ul className="menu menu-horizontal p-0 ml-5">
          <li className="font-sans text-lg">
            <a href="https://github.com/AlphaWoolfGame/woolf_game" target="_blank">Source Code</a>
            <a href={MODULE_URL} target="_blank">Contract on Explorer</a>
          </li>
        </ul>
      </div>
      <AptosConnect />
    </nav>
  );
}
